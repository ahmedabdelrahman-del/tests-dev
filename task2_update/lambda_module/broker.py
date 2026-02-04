import base64
import json
import os
import urllib.parse
import urllib.request
from datetime import datetime, timezone

import boto3

ssm = boto3.client("ssm")


def _get_ssm_param(name: str, decrypt: bool = False) -> str:
    """Fetch a parameter from SSM Parameter Store."""
    resp = ssm.get_parameter(Name=name, WithDecryption=decrypt)
    return resp["Parameter"]["Value"]


def _json_response(status_code: int, body: dict):
    """Return an API Gateway compatible response."""
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Cache-Control": "no-store",
            "Pragma": "no-cache",
        },
        "body": json.dumps(body),
    }


def handler(event, context):
    """
    Token broker Lambda.

    Expected request:
      - POST
      - body can be JSON or form-encoded
      - supports client_credentials only

    Input (either format):
      - grant_type=client_credentials (required)
      - scope="space separated scopes" (optional)
    """

    # Parameter names are provided as environment variables
    token_url_param = os.environ["SSM_COGNITO_TOKEN_URL_PARAM"]
    client_id_param = os.environ["SSM_COGNITO_CLIENT_ID_PARAM"]
    client_secret_param = os.environ["SSM_COGNITO_CLIENT_SECRET_PARAM"]
    allowed_scopes_param = os.environ.get("SSM_ALLOWED_SCOPES_PARAM")

    # Fetch config from SSM
    token_url = _get_ssm_param(token_url_param, decrypt=False)
    client_id = _get_ssm_param(client_id_param, decrypt=False)
    client_secret = _get_ssm_param(client_secret_param, decrypt=True)

    allowed_scopes = []
    if allowed_scopes_param:
        try:
            allowed_scopes = json.loads(_get_ssm_param(allowed_scopes_param, decrypt=False))
        except Exception:
            allowed_scopes = []

    # Parse request body
    raw_body = event.get("body") or ""
    if event.get("isBase64Encoded"):
        raw_body = base64.b64decode(raw_body).decode("utf-8")

    content_type = (event.get("headers") or {}).get("content-type") or (event.get("headers") or {}).get("Content-Type") or ""

    grant_type = None
    requested_scopes = ""

    # Accept JSON body or x-www-form-urlencoded
    if "application/json" in content_type:
        try:
            body_json = json.loads(raw_body) if raw_body else {}
        except json.JSONDecodeError:
            return _json_response(400, {"error": "invalid_request", "message": "Invalid JSON body"})
        grant_type = body_json.get("grant_type")
        requested_scopes = body_json.get("scope", "") or ""
    else:
        form = urllib.parse.parse_qs(raw_body)
        grant_type = (form.get("grant_type") or [None])[0]
        requested_scopes = (form.get("scope") or [""])[0]

    # Validate grant type (broker only supports client_credentials)
    if grant_type != "client_credentials":
        return _json_response(
            400,
            {
                "error": "unsupported_grant_type",
                "message": "Only client_credentials is supported by this broker",
            },
        )

    # Validate scopes against allowlist (if provided)
    scope_list = [s for s in requested_scopes.split() if s.strip()]
    if allowed_scopes and scope_list:
        for s in scope_list:
            if s not in allowed_scopes:
                return _json_response(
                    403,
                    {
                        "error": "invalid_scope",
                        "message": f"Scope not allowed: {s}",
                    },
                )

    # Build token request to Cognito
    basic = base64.b64encode(f"{client_id}:{client_secret}".encode("utf-8")).decode("utf-8")

    form_data = {"grant_type": "client_credentials"}
    if requested_scopes:
        form_data["scope"] = requested_scopes

    data_bytes = urllib.parse.urlencode(form_data).encode("utf-8")
    req = urllib.request.Request(
        token_url,
        data=data_bytes,
        method="POST",
        headers={
            "Authorization": f"Basic {basic}",
            "Content-Type": "application/x-www-form-urlencoded",
        },
    )

    # Call Cognito
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            resp_body = resp.read().decode("utf-8")
            # Cognito returns JSON
            return {
                "statusCode": resp.status,
                "headers": {
                    "Content-Type": "application/json",
                    "Cache-Control": "no-store",
                    "Pragma": "no-cache",
                },
                "body": resp_body,
            }
    except urllib.error.HTTPError as e:
        # Pass through Cognito error safely
        err_body = e.read().decode("utf-8") if e.fp else ""
        return _json_response(
            e.code,
            {
                "error": "token_request_failed",
                "upstream_status": e.code,
                "upstream_body": err_body,
                "timestamp": datetime.now(timezone.utc).isoformat(),
            },
        )
    except Exception as e:
        return _json_response(
            500,
            {
                "error": "internal_error",
                "message": str(e),
                "timestamp": datetime.now(timezone.utc).isoformat(),
            },
        )
