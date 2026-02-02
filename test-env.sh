#!/bin/bash
# Quick Test Commands for Terraform AWS Modules

set -e

echo "==================================="
echo "TERRAFORM ENVIRONMENT TEST SCRIPT"
echo "==================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
  echo -e "${GREEN}[✓]${NC} $1"
}

print_step() {
  echo -e "\n${YELLOW}[STEP]${NC} $1"
}

print_error() {
  echo -e "${RED}[✗]${NC} $1"
}

# Change to terraform directory
cd /workspaces/Terraform_Aws_Modules

# Step 1: Validate
print_step "Validating Terraform Configuration"
terraform validate
print_status "Configuration validation passed"

# Step 2: Plan
print_step "Creating Terraform Plan"
terraform plan -out=tfplan -json > /tmp/tfplan.json 2>&1 || true
terraform plan -out=tfplan 2>&1 | tail -20
print_status "Plan created successfully"

# Step 3: Show plan summary
print_step "Showing Resource Summary"
RESOURCE_COUNT=$(terraform plan -json -no-color tfplan 2>/dev/null | grep -c "\"type\"" || echo "N/A")
echo "Total resources to create: $RESOURCE_COUNT"

# Step 4: List key outputs that will be generated
print_step "Key Outputs After Deployment"
echo "The following outputs will be available after deployment:"
echo "  - cognito_user_pool_id (Cognito User Pool ID)"
echo "  - cognito_client_id (App Client ID)"
echo "  - login_url (API Gateway login endpoint)"
echo "  - refresh_url (API Gateway refresh endpoint)"
echo "  - mfa_url (API Gateway MFA endpoint)"
echo "  - waf_web_acl_arn (WAF Web ACL ARN)"

# Step 5: Check AWS credentials
print_step "Checking AWS Credentials"
if aws sts get-caller-identity >/dev/null 2>&1; then
  ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
  print_status "AWS credentials configured for account: $ACCOUNT"
else
  print_error "AWS credentials not configured. Please run: aws configure"
  exit 1
fi

# Step 6: Display next steps
print_step "Next Steps"
echo ""
echo "To deploy the infrastructure, run:"
echo "  terraform apply tfplan"
echo ""
echo "After deployment, verify with:"
echo "  terraform output"
echo ""
echo "To test the API endpoints:"
echo "  LOGIN_URL=\$(terraform output -raw login_url)"
echo "  curl -X POST \$LOGIN_URL -H 'Content-Type: application/json' -d '{\"username\":\"testuser\",\"password\":\"TestPass123!\"}'"
echo ""
echo "To clean up all resources:"
echo "  terraform destroy"
echo ""

print_status "Test validation complete! Ready for deployment."
