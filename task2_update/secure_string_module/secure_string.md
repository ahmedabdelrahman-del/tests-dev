# SSM SecureString Secrets Module (Terraform)

This module stores **infrastructure-level secrets and configuration** required by the platform to interact with Amazon Cognito.

It is designed specifically for the **Lambda token broker architecture**, where internal services — not customers — authenticate to Cognito in order to mint OAuth tokens.

---

## Purpose of This Module

The module creates encrypted parameters in AWS Systems Manager Parameter Store:

- Cognito OAuth token endpoint URL
- Cognito machine-to-machine App Client ID
- Cognito machine-to-machine App Client Secret (SecureString)
- Allowed OAuth scopes for the broker

These values are:

- 🔐 encrypted at rest
- 🔒 readable only by designated IAM roles (Lambda later)
- 🚫 never embedded in source code
- 🚫 never exposed to customers
- 🚫 not tied to end users or tenants

---

## Architecture Context

At this stage of the build, the system looks like:

