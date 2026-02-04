### REST API module: what it does (end-to-end)
### REST API module should implement:
Client → REST API /oauth2/token → Lambda broker → Cognito
Where AWS Lambda stays the policy brain, and API Gateway is the protective front door.
### 1) REST API container
Resource purpose: creates the API “shell” that holds resources, methods, stages.
What it does
Defines an API named like token-broker-api
Enables you to add routes/resources (/oauth2/token)
Provides a global place for stage deployment and logging
What it should NOT do
It should not contain secrets
It should not hardcode credentials
It should not expose Cognito directly (the integration should be Lambda broker, not Cognito)
### 2) Resource path /oauth2 and /oauth2/token
REST API uses a resource tree:
root /
child /oauth2
child /oauth2/token
What it does
Creates the route structure so you can attach a method: POST /oauth2/token
What it should NOT do
It should not create extra endpoints you don’t need (keep the API minimal: token endpoint only)
### 3) Method: POST on /oauth2/token
This is the actual HTTP method entry point.
What it does
Defines request handling for POST
You can require an API key here (optional but recommended if you want per-client usage plans)
You can attach authorizers later (IAM/JWT/custom auth)
What it should NOT do
It should not accept multiple grant types unless you explicitly allow them (keep surface area small)
It should not treat request body client_id as identity (identity must come from API key/IAM/JWT)
### 4) Integration: API Gateway → Lambda (proxy)
This wires the method to your broker Lambda.
What it does
Forwards request to Lambda
Returns Lambda response back to client
With proxy integration, Lambda receives the full request context
What it should NOT do
It should not transform or log sensitive payloads (don’t enable full request/response logging that includes tokens)
### 5) Lambda permission to allow API Gateway invocation
API Gateway must be allowed to call Lambda.
What it does
Grants invoke permission scoped to this API/stage/method
Without it, you’ll get “Forbidden” on invocation
What it should NOT do
It should not be wildcarded too broadly (avoid allowing any API to invoke the function)
### 6) Deployment + Stage
REST API requires a deployment and stage (e.g., dev).
What it does
Produces an invoke URL like:
https://{restapi-id}.execute-api.{region}.amazonaws.com/dev/oauth2/token
This is also where you define:
stage logging/metrics
default throttling
method-level settings
What it should NOT do
It should not log request/response bodies for token endpoints (risk of token leakage)
It should not enable overly verbose logs unless you sanitize
### How throttling is applied (exactly)
API Gateway throttling is enforced using a token bucket style mechanism with:
Rate (steady requests/second)
Burst (short spike capacity)
When exceeded, API Gateway returns:
HTTP 429 Too Many Requests
and the request never reaches Lambda (good—saves cost and protects Cognito).
Where you configure throttling
A) Stage-level throttling (baseline protection)
You can set a default rate/burst for the stage.
Effect: protects the entire API.
Good for:
global flood control
safety net
Limitation:
it’s shared unless you add per-client usage plans.
B) Method-level throttling (protect the token endpoint specifically)
You can set specific limits for:
POST /oauth2/token
Good for:
keeping other endpoints flexible (if you add them later)
making token endpoint stricter
C) Usage plans + API keys (per-client throttling + quotas)
This is the most important part if you want per-client control at the gateway.
How it works
You create an API key for each consumer (service/client)
You create a usage plan with:
throttle (rate/burst)
optional quota (requests/day, week, month)
You attach the key to the plan
You require the API key on the method
Result
Client A and Client B are throttled independently
You can enforce daily quotas at the gateway level
Note: Even with usage plans, for strict security you still keep Lambda-side policy (because API keys can be leaked/shared).
