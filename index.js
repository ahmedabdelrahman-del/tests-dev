"use strict";

const { DynamoDBClient, UpdateItemCommand } = require("@aws-sdk/client-dynamodb");
const {
  CognitoIdentityProviderClient,
  InitiateAuthCommand,
  RespondToAuthChallengeCommand,
} = require("@aws-sdk/client-cognito-identity-provider");

// ---------- ENV ----------
const {
  RATELIMIT_TABLE,
  USER_POOL_ID,
  CLIENT_ID,

  WINDOW_SECONDS = "60",

  LOGIN_USER_MAX_PER_WINDOW = "5",
  LOGIN_IP_MAX_PER_WINDOW = "30",

  REFRESH_USER_MAX_PER_WINDOW = "20",
  REFRESH_IP_MAX_PER_WINDOW = "120",

  MFA_USER_MAX_PER_WINDOW = "10", // per 5 minutes recommended
  MFA_WINDOW_SECONDS = "300",

  LOG_LEVEL = "INFO",
} = process.env;

const ddb = new DynamoDBClient({});
const cognito = new CognitoIdentityProviderClient({});

// ---------- Helpers ----------
function jsonResponse(statusCode, bodyObj, extraHeaders = {}) {
  return {
    statusCode,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
      "Pragma": "no-cache",
      ...extraHeaders,
    },
    body: JSON.stringify(bodyObj),
  };
}

function safeLog(level, msg, meta = {}) {
  const levels = ["ERROR", "WARN", "INFO", "DEBUG"];
  const cur = levels.indexOf(LOG_LEVEL.toUpperCase());
  const lvl = levels.indexOf(level);
  if (lvl <= cur) {
    // لا تطبع secrets: tokens/password/refresh_token
    const redacted = { ...meta };
    if (redacted.password) redacted.password = "***";
    if (redacted.refresh_token) redacted.refresh_token = "***";
    if (redacted.access_token) redacted.access_token = "***";
    if (redacted.id_token) redacted.id_token = "***";
    console.log(JSON.stringify({ level, msg, ...redacted }));
  }
}

function getSourceIp(event) {
  // REST API proxy: غالبًا من requestContext.identity.sourceIp
  return event?.requestContext?.identity?.sourceIp || "unknown";
}

function getRoute(event) {
  // REST API proxy: resource/method/path
  const method = event.httpMethod || "UNKNOWN";
  const path = event.path || event.resource || "unknown";
  return `${method} ${path}`;
}

function parseJsonBody(event) {
  if (!event.body) return {};
  const raw = event.isBase64Encoded ? Buffer.from(event.body, "base64").toString("utf8") : event.body;
  try {
    return JSON.parse(raw);
  } catch {
    throw new Error("INVALID_JSON");
  }
}

function maskUser(u) {
  if (!u || typeof u !== "string") return "";
  if (u.length <= 2) return "*";
  return u[0] + "***" + u[u.length - 1];
}

// DynamoDB atomic counter with TTL
async function bumpCounter({ key, windowSeconds, max }) {
  const now = Math.floor(Date.now() / 1000);
  const ttl = now + windowSeconds;

  const cmd = new UpdateItemCommand({
    TableName: RATELIMIT_TABLE,
    Key: { k: { S: key } },
    // Atomic increment + set ttl only (overwrites ttl each window hit; OK for fixed-window)
    UpdateExpression: "SET ttl = :ttl ADD counter :incr",
    ExpressionAttributeValues: {
      ":ttl": { N: String(ttl) },
      ":incr": { N: "1" },
    },
    ReturnValues: "UPDATED_NEW",
  });

  const res = await ddb.send(cmd);
  const counter = Number(res?.Attributes?.counter?.N || "0");

  if (counter > max) {
    // time left in window for Retry-After (best-effort)
    const retryAfter = Math.max(1, ttl - now);
    return { allowed: false, counter, retryAfter };
  }

  return { allowed: true, counter, retryAfter: 0 };
}

async function enforceLimits({ ip, username, routeKey, type }) {
  // type: "login" | "refresh" | "mfa"
  const windowSeconds = type === "mfa" ? Number(MFA_WINDOW_SECONDS) : Number(WINDOW_SECONDS);

  const limits = {
    login: {
      userMax: Number(LOGIN_USER_MAX_PER_WINDOW),
      ipMax: Number(LOGIN_IP_MAX_PER_WINDOW),
    },
    refresh: {
      userMax: Number(REFRESH_USER_MAX_PER_WINDOW),
      ipMax: Number(REFRESH_IP_MAX_PER_WINDOW),
    },
    mfa: {
      userMax: Number(MFA_USER_MAX_PER_WINDOW),
      ipMax: 60, // Optional: you can move this to env if you want
    },
  }[type];

  // 1) IP limit
  const ipKey = `ip#${ip}#route#${routeKey}`;
  const ipCheck = await bumpCounter({ key: ipKey, windowSeconds, max: limits.ipMax });
  if (!ipCheck.allowed) {
    return { ok: false, reason: "IP_LIMIT", retryAfter: ipCheck.retryAfter };
  }

  // 2) User limit (لو فيه username)
  if (username) {
    const userKey = `user#${username}#route#${routeKey}`;
    const userCheck = await bumpCounter({ key: userKey, windowSeconds, max: limits.userMax });
    if (!userCheck.allowed) {
      return { ok: false, reason: "USER_LIMIT", retryAfter: userCheck.retryAfter };
    }
  }

  return { ok: true };
}

// ---------- Cognito calls ----------
async function cognitoLogin({ username, password }) {
  // USER_PASSWORD_AUTH
  const cmd = new InitiateAuthCommand({
    AuthFlow: "USER_PASSWORD_AUTH",
    ClientId: CLIENT_ID,
    AuthParameters: {
      USERNAME: username,
      PASSWORD: password,
    },
  });

  return cognito.send(cmd);
}

async function cognitoRefresh({ refreshToken }) {
  const cmd = new InitiateAuthCommand({
    AuthFlow: "REFRESH_TOKEN_AUTH",
    ClientId: CLIENT_ID,
    AuthParameters: {
      REFRESH_TOKEN: refreshToken,
    },
  });

  return cognito.send(cmd);
}

async function cognitoRespondToMfa({ challengeName, session, username, mfaCode }) {
  const cmd = new RespondToAuthChallengeCommand({
    ClientId: CLIENT_ID,
    ChallengeName: challengeName, // SOFTWARE_TOKEN_MFA أو SMS_MFA
    Session: session,
    ChallengeResponses: {
      USERNAME: username,
      SOFTWARE_TOKEN_MFA_CODE: mfaCode, // لو challengeName = SOFTWARE_TOKEN_MFA
      // لو SMS_MFA: استخدم SMS_MFA_CODE بدل SOFTWARE_TOKEN_MFA_CODE
    },
  });

  return cognito.send(cmd);
}

// ---------- Handler ----------
exports.handler = async (event) => {
  const ip = getSourceIp(event);
  const route = getRoute(event);

  // نحدد endpoint بناءً على path
  const path = event.path || "";
  const method = event.httpMethod || "";

  safeLog("INFO", "Incoming request", { route, ip });

  if (method !== "POST") {
    return jsonResponse(405, { message: "Method Not Allowed" });
  }

  let body;
  try {
    body = parseJsonBody(event);
  } catch (e) {
    return jsonResponse(400, { message: "Invalid JSON body" });
  }

  // Normalize routes (REST API)
  // expected: /token/login, /token/refresh, /token/mfa
  try {
    if (path.endsWith("/token/login")) {
      const username = (body.username || "").trim();
      const password = body.password;

      if (!username || !password) {
        return jsonResponse(400, { message: "Missing username/password" });
      }

      // Rate limit قبل Cognito
      const lim = await enforceLimits({
        ip,
        username,
        routeKey: "token_login",
        type: "login",
      });

      if (!lim.ok) {
        return jsonResponse(
          429,
          { message: "Too many requests. Try again later." },
          { "Retry-After": String(lim.retryAfter) }
        );
      }

      const res = await cognitoLogin({ username, password });

      // MFA/Challenge handling
      if (res.ChallengeName) {
        return jsonResponse(200, {
          status: "CHALLENGE_REQUIRED",
          challenge_name: res.ChallengeName,
          session: res.Session,
          username, // أو ابعتها masked لو تفضل
        });
      }

      const r = res.AuthenticationResult || {};
      return jsonResponse(200, {
        access_token: r.AccessToken,
        id_token: r.IdToken,
        refresh_token: r.RefreshToken,
        expires_in: r.ExpiresIn,
        token_type: r.TokenType || "Bearer",
      });
    }

    if (path.endsWith("/token/refresh")) {
      const refreshToken = body.refresh_token;

      if (!refreshToken) {
        return jsonResponse(400, { message: "Missing refresh_token" });
      }

      // username قد لا يكون متوفر هنا، نعمل rate limit على IP فقط أو user لو متوفر
      const username = body.username ? String(body.username).trim() : "";

      const lim = await enforceLimits({
        ip,
        username: username || null,
        routeKey: "token_refresh",
        type: "refresh",
      });

      if (!lim.ok) {
        return jsonResponse(
          429,
          { message: "Too many requests. Try again later." },
          { "Retry-After": String(lim.retryAfter) }
        );
      }

      const res = await cognitoRefresh({ refreshToken });
      const r = res.AuthenticationResult || {};

      return jsonResponse(200, {
        access_token: r.AccessToken,
        id_token: r.IdToken,
        expires_in: r.ExpiresIn,
        token_type: r.TokenType || "Bearer",
      });
    }

    if (path.endsWith("/token/mfa")) {
      const username = (body.username || "").trim();
      const mfaCode = body.mfa_code;
      const session = body.session;
      const challengeName = body.challenge_name; // SOFTWARE_TOKEN_MFA أو SMS_MFA

      if (!username || !mfaCode || !session || !challengeName) {
        return jsonResponse(400, { message: "Missing username/mfa_code/session/challenge_name" });
      }

      const lim = await enforceLimits({
        ip,
        username,
        routeKey: "token_mfa",
        type: "mfa",
      });

      if (!lim.ok) {
        return jsonResponse(
          429,
          { message: "Too many requests. Try again later." },
          { "Retry-After": String(lim.retryAfter) }
        );
      }

      const res = await cognitoRespondToMfa({ challengeName, session, username, mfaCode });

      const r = res.AuthenticationResult || {};
      return jsonResponse(200, {
        access_token: r.AccessToken,
        id_token: r.IdToken,
        refresh_token: r.RefreshToken,
        expires_in: r.ExpiresIn,
        token_type: r.TokenType || "Bearer",
      });
    }

    return jsonResponse(404, { message: "Not Found" });
  } catch (err) {
    // لا تكشف تفاصيل Cognito errors للعميل
    safeLog("ERROR", "Unhandled error", {
      route,
      ip,
      errorName: err?.name,
      errorMessage: err?.message,
    });

    // أخطاء شائعة من Cognito:
    // NotAuthorizedException, UserNotFoundException, PasswordResetRequiredException, TooManyRequestsException, etc.
    if (err?.name === "NotAuthorizedException" || err?.name === "UserNotFoundException") {
      return jsonResponse(401, { message: "Invalid credentials" });
    }

    if (err?.name === "TooManyRequestsException") {
      // Cognito نفسه عمل throttle
      return jsonResponse(429, { message: "Upstream throttling. Try again later." }, { "Retry-After": "30" });
    }

    return jsonResponse(500, { message: "Internal Server Error" });
  }
};
