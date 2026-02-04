### What the API module does
Step 1 — Creates a public HTTPS endpoint
Using Amazon API Gateway, you expose something like:
POST /oauth2/token
This becomes the only public path your clients use (not Cognito directly).
It does:
creates a stable “front door”
gives you request logs/metrics
provides throttling + authentication hooks
####
Step 2 — Routes requests to Lambda (integration)
API Gateway sends requests to your Lambda broker.
It does:
passes the HTTP request body/headers to Lambda
returns Lambda response back to caller
####
Step 3 — Enforces throttling at the edge (before Lambda runs)
This is where “throttling” shines: it blocks abusive traffic before Lambda gets invoked (saving money and reducing load).
####
Step 4 — Optionally enforces “client identity”
Depending on your design, API Gateway can require:
API key
IAM auth
JWT authorizer
…and then throttle per-client identity (API key usage plan) or per-stage.
####
What the API module should NOT do
❌ It should not expose Cognito endpoints
Don’t proxy /oauth2/token directly to Cognito publicly if your security goal is “broker is the only caller.”
❌ It should not “trust” client-provided client_id
Caller-supplied client_id is not a reliable identity. Use API key / IAM / JWT as the caller identity.
❌ It should not implement business logic
API Gateway should:
route
throttle
authenticate
validate shape (optional)
Business rules stay in Lambda.
####
REST API module: what it does (end-to-end)
Your REST API module should implement:
Client → REST API /oauth2/token → Lambda broker → Cognito
Where AWS Lambda stays the policy brain, and API Gateway is the protective front door.
