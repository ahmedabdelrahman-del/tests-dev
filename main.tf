module "Cognito_Module" {
  source = "/workspaces/Terraform_Aws_Modules/task2/Cognito_Module"

  name                    = var.project_name
  region                  = var.region
  domain_prefix           = var.cognito_domain_prefix
  resource_server_identifier = var.resource_server_identifier
  scopes                  = var.scopes
  tags                    = var.tags
}

module "Lambda_Function_Module" {
  source = "/workspaces/Terraform_Aws_Modules/task2/Lambda_Function_Module"

  name                     = "${var.project_name}-token-broker"
  cognito_token_url         = module.Cognito_Module.token_url
  cognito_client_id         = module.Cognito_Module.client_id
  cognito_client_secret_arn = module.Cognito_Module.client_secret_arn

  # optional: request a default scope
  default_scope            = module.Cognito_Module.allowed_scopes[1] # e.g. orders.write (just demo)
  tags                     = var.tags
}

module "API_GateWay_Module" {
  source = "/workspaces/Terraform_Aws_Modules/task2/API_GateWay_Module"

  name                 = var.project_name
  region               = var.region
  stage_name           = var.stage_name
  lambda_invoke_arn     = module.Lambda_Function_Module.invoke_arn
  lambda_function_name  = module.Lambda_Function_Module.function_name

  throttle_rate_limit   = var.apigw_rate_limit
  throttle_burst_limit  = var.apigw_burst_limit

  tags                 = var.tags
}

module "WAF_Module" {
  source = "/workspaces/Terraform_Aws_Modules/task2/WAF_Module"
  name                = var.project_name
  scope               = "REGIONAL"

  # Associate WAF to the API Gateway stage
  target_resource_arn = module.API_GateWay_Module.stage_arn

  global_rate_limit      = 10000
  token_path_rate_limit  = var.waf_rate_limit
  allow_ip_cidrs      = var.allow_ip_cidrs
  block_ip_cidrs      = var.block_ip_cidrs

  tags                = var.tags
}
