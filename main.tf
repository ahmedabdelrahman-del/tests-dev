module "cognito_module" {
  source       = "/workspaces/Terraform_Aws_Modules/task2_update/cognito_module"
  aws_region   = var.aws_region
  project_name = var.project_name
  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls
  user_pool_tier = var.user_pool_tier
}
module "security_string_module" {
  source     = "/workspaces/Terraform_Aws_Modules/task2_update/secure_string_module"
  aws_region = var.aws_region
  name_prefix = var.project_name
  cognito_token_url = module.cognito_module.cognito_token_url
  cognito_client_id = module.cognito_module.m2m_client_id
  cognito_client_secret = module.cognito_module.m2m_client_secret
  allowed_scopes = [ "${module.cognito_module.resource_server_identifier}/tokens.read", "${module.cognito_module.resource_server_identifier}/tokens.write" ]
    tags = {
    owner   = "Ahmed Abdelrahman"
    system  = "token-broker"
    purpose = "cognito-broker-secrets"
  }
}
module "lambda_module" {
  source       = "/workspaces/Terraform_Aws_Modules/task2_update/lambda_module"
  project_name = var.project_name
  broker_parameter_arns = module.security_string_module.parameter_arns
  broker_parameter_names = module.security_string_module.parameter_names
}
module "api_gateway_module" {
  source        = "/workspaces/Terraform_Aws_Modules/task2_update/api_gateway_module"
  project_name  = var.project_name
  aws_region    = var.aws_region
  api_stage_name = var.api_stage_name
  enable_api_key = var.enable_api_key
  lambda_invoke_arn = module.lambda_module.token_broker_lambda_invoke_arn
}

# Allow API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "allow_apigw_invoke" {
  statement_id  = "AllowExecutionFromAPIGatewayTokenBroker"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_module.token_broker_lambda_name
  principal     = "apigateway.amazonaws.com"

  # Restrict to this API, any stage, POST method, and /oauth2/token
  source_arn = "${module.api_gateway_module.api_execution_arn}/*/POST/oauth2/token"
}