# Token Broker Architecture (Cognito + SSM + Lambda + API Gateway)

This document explains each module in this solution and how they integrate together.  
Goal: expose a stable `/oauth2/token` endpoint that **does not expose Cognito directly**, enforces throttling, and keeps secrets out of code.

---

## Module 1 — Cognito OAuth Foundation (Terraform)

**What it does**
- Creates a Cognito User Pool (OAuth issuer).
- Adds a Cognito-managed domain to expose OAuth endpoints.
- Defines a Resource Server and custom scopes:
  - `tokens.read`
  - `tokens.write`
- Creates App Clients:
  - **M2M client** (`client_credentials`) with a client secret (used by the broker)
  - (Optional) interactive client (`authorization_code`) for Hosted UI testing

**What it should NOT do**
- It should not be called directly by external clients for token issuance if you require a broker.
- It should not store secrets outside Cognito itself.

**Key outputs**
- Token endpoint URL: `https://<domain>.auth.<region>.amazoncognito.com/oauth2/token`
- Resource server identifier: `https://api.<prefix>.local`
- M2M client id + secret

---

## Module 2 — SSM SecureString Secrets (Terraform)

**What it does**
Stores infrastructure credentials/config in AWS Systems Manager Parameter Store:
- `cognito_token_url` (String)
- `cognito_client_id` (String)
- `cognito_client_secret` (**SecureString**)
- `allowed_scopes` (String JSON array)

All stored under a consistent path:
`/<project>/<env>/broker/*`

**What it should NOT do**
- It should not store user data or customer secrets.
- It should not expose values to humans by default (IAM controls should restrict reads).

**Why it exists**
- Keeps Cognito credentials out of Lambda environment variables, source code, and Terraform outputs.
- Enables least-privilege access for runtime components.

---

## Module 3 — Lambda Token Broker (Terraform + Code)

**What it does**
- Reads broker configuration and Cognito credentials from SSM SecureString.
- Accepts requests (initially only `client_credentials`).
- Validates scope against `allowed_scopes`.
- Calls Cognito `/oauth2/token` using M2M client credentials.
- Returns token response to the caller with safe headers (`no-store`, etc.).

**What it should NOT do**
- Must not log secrets, Authorization headers, or tokens.
- Must not accept caller-supplied Cognito `client_id` / `client_secret`.
- Must not proxy arbitrary grant types (`password`, `refresh_token`) unless explicitly approved.
- Must not store tokens long-term.

**Security boundary**
- Only Lambda is allowed to read the Cognito secret from SSM (IAM enforced).

---

## Module 4 — API Gateway REST API (Terraform)

**What it does**
- Exposes a public endpoint: `POST /oauth2/token`
- Integrates with Lambda token broker (AWS_PROXY).
- Applies throttling:
  - method-level throttling (rate/burst)
  - usage plan throttling + quota (per API key)
- Requires API key (optional but recommended for per-client throttling).

**What it should NOT do**
- Must not log request/response bodies for the token method (avoid token leaks).
- Must not trust `client_id` in body as caller identity.
- Must not call Cognito directly (integration should be Lambda broker).

**How throttling works**
- **Rate**: steady requests per second
- **Burst**: short spikes allowed
- Exceeding limits returns **HTTP 429** before Lambda runs (protects cost and upstream Cognito).

---

# Final Integration (End-to-End Flow)

1. Client sends:
   `POST https://{api-id}.execute-api.{region}.amazonaws.com/{stage}/oauth2/token`
   - includes `x-api-key` (if enabled)
   - body: `grant_type=client_credentials&scope=<resource_server>/tokens.read`

2. API Gateway:
   - validates API key and usage plan association
   - enforces per-key throttling/quota
   - enforces method/stage throttling
   - forwards request to Lambda broker

3. Lambda broker:
   - loads `client_id`, `client_secret`, token URL from SSM
   - validates requested scopes
   - calls Cognito `/oauth2/token`

4. Cognito returns token JSON:
   - access_token, expires_in, token_type

5. Lambda returns the response to API Gateway → client.

**Result**
- Clients never call Cognito directly.
- Cognito secret stays internal to infrastructure.
- Throttling is enforced at the edge (API Gateway) and policy is enforced in the broker (Lambda).

---
