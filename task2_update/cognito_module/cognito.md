# Cognito OAuth Foundation (Terraform)

This module provisions the **Amazon Cognito OAuth foundation** used by the system:

- A User Pool acting as the authorization server
- A Cognito-managed domain exposing OAuth endpoints
- Custom OAuth scopes (Resource Server)
- Two App Clients:
  - Machine-to-machine client for token issuance
  - Interactive client for browser login flows

This is the first building block for a future **Lambda token broker** that will sit in front of Cognito and enforce:

- per-client quotas (e.g., 3 tokens/day)
- authorization rules
- secret isolation
- auditing and logging

---

## Architecture Context

For now, clients can call Cognito directly:


