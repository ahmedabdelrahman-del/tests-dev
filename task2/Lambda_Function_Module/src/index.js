const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");

const sm = new SecretsManagerClient({});

exports.handler = async (event) => {
  try {
    const tokenUrl = process.env.COGNITO_TOKEN_URL;
    const clientId = process.env.COGNITO_CLIENT_ID;
    const secretArn = process.env.COGNITO_CLIENT_SECRET_ARN;
    const defaultScope = process.env.DEFAULT_SCOPE || "";

    // Optional: validate request (you can enforce allowlisted scopes here)
    // For Flow A, often you just use DEFAULT_SCOPE and ignore client-provided scope.

    const secretRes = await sm.send(new GetSecretValueCommand({ SecretId: secretArn }));
    const clientSecret = secretRes.SecretString;

    const form = new URLSearchParams();
    form.set("grant_type", "client_credentials");
    if (defaultScope) form.set("scope", defaultScope);

    // Use HTTP Basic Auth: base64(client_id:client_secret)
    const basic = Buffer.from(`${clientId}:${clientSecret}`).toString("base64");

    const resp = await fetch(tokenUrl, {
      method: "POST",
      headers: {
        "Authorization": `Basic ${basic}`,
        "Content-Type": "application/x-www-form-urlencoded"
      },
      body: form.toString()
    });

    const text = await resp.text();
    return {
      statusCode: resp.status,
      headers: { "Content-Type": "application/json" },
      body: text
    };
  } catch (err) {
    console.error("Token broker error:", err);
    return {
      statusCode: 500,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ message: "Internal server error" })
    };
  }
};
