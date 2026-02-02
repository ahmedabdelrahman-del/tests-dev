# API Gateway + Lambda + Cognito + DynamoDB

Token broker infrastructure with API Gateway, Lambda, Cognito authentication, and DynamoDB rate limiting.

## 🚀 Quick Start

### 1. Prerequisites
```bash
# Install Terraform
terraform version

# Configure AWS
aws configure
```

### 2. Deploy Infrastructure
```bash
terraform init
terraform plan
terraform apply --auto-approve
```

### 3. Test API
```bash
python3 tests/test-comprehensive.py
```

## 📊 Infrastructure

- **API Gateway**: 50 req/sec throttle, 100 burst limit
- **Lambda**: Node.js 20.x token broker
- **Cognito**: User authentication pool
- **DynamoDB**: Rate limiting table
- **CloudWatch**: Full logging enabled

## 🧪 Testing

Run comprehensive tests including rate limit verification:

```bash
python3 tests/test-comprehensive.py
```

**Tests Include:**
- ✓ Endpoint connectivity (3 endpoints)
- ✓ CORS configuration
- ✓ Response format validation
- ✓ Performance metrics
- ✓ Concurrent request handling (20 concurrent)
- ✓ **Rate limiting verification** (150+ requests exceeding limit)
- ✓ CloudWatch logging

**Expected Results:**
- Endpoints responding: ✓
- CORS headers: ✓
- Throttling active: ✓ (429 responses when limit exceeded)

## 🔧 Commands

```bash
# Plan changes
terraform plan

# Deploy
terraform apply

# Destroy
terraform destroy

# Get outputs
terraform output -json

# View logs
aws logs tail /aws/apigateway/token-broker-dev-* --follow
```

## 📁 Structure

```
├── README.md                          # This file
├── main.tf                            # Root module
├── variables.tf                       # Variables
├── outputs.tf                         # Outputs
├── provider.tf                        # AWS provider
├── terraform.tfvars                   # Configuration
├── Api_gateway_Lambda/                # API + Lambda modules
│   ├── API_gate_way_Module/
│   ├── Lambda_Token_Broker_Module/
│   ├── cognito_user_pool_Module/
│   ├── Data_Base_Module/
│   ├── monitoring_Module/
│   └── waf_apigw_rest_Module/
├── Modules/                           # Additional modules
└── tests/
    └── test-comprehensive.py          # Comprehensive test suite
```

