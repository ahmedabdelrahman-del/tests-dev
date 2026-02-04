# why i need it in this project: 
A Lambda token broker is a controlled “middleman” between your callers and Amazon Cognito’s /oauth2/token endpoint. It exists to enforce your company’s rules and hide Cognito credentials/endpoints from clients.
# What the Lambda token broker exactly does:
1) Accepts a token request from an internal/external caller:
Typically via Amazon API Gateway:
POST /oauth2/token (your endpoint)
It receives:
grant_type (usually client_credentials)
requested scope (optional)
caller identity (API key / IAM / JWT — depends on your gateway setup)
2) Authenticates and identifies the caller (your policy)
It decides who is calling, based on:
API Gateway API key usage plan identity
IAM principal (SigV4)
JWT claims
mTLS client certificate metadata
(you choose one; the broker just consumes the identity signal)

3) Authorizes what that caller is allowed to request
This is the key “broker” value:
Is this caller allowed to request tokens at all?
Which Cognito client should be used?
Which scopes are permitted for this caller?
What token TTL policy applies? (if you enforce short-lived tokens)
Optionally: restrict audience/claims (depends on flow)
4) Enforces rate limits / quotas (per client identity)
For example:
3 token grants per day for client A
higher limits for privileged clients
burst limits
Usually done with Amazon DynamoDB counters or another rate-limiting store.
5) Retrieves the Cognito app credentials securely
It reads from:
AWS Systems Manager Parameter Store SecureString (your choice)
or Secrets Manager
It fetches:
Cognito client_id
Cognito client_secret
Cognito /oauth2/token URL
allowed scopes (optional)
6) Calls Cognito /oauth2/token on behalf of the caller
It makes the upstream request:
grant_type=client_credentials
scope=...
Basic Auth with client_id:client_secret
Then receives:
access token
expires_in
token_type
7) Returns a safe response to the caller
It returns:
token response (or a controlled error)
consistent HTTP status codes
safe error messages that don’t leak internals
8) Logs and emits metrics (without leaking secrets)
It logs:
request id / correlation id
caller identity (hashed or internal id)
scopes requested
allow/deny decisions
quota outcomes
But never logs secrets or tokens.
# what it should not do:
❌ 1) It should not expose Cognito secrets to clients
❌ 2) It should not blindly pass through arbitrary requests to Cognito
❌ 3) It should not become an identity provider for end users
❌ 4) It should not store issued access tokens long-term
❌ 5) It should not log sensitive data
❌ 6) It should not implement complex business logic unrelated to token issuance
❌ 7) It should not become a single point of failure without protections

