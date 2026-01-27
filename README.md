# Terraform AWS Modules

Infrastructure as Code using Terraform and AWS.

## Prerequisites

### 1. Install Terraform
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install terraform
terraform version
```

### 2. Install AWS CLI v2
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

### 3. Configure AWS Credentials
```bash
aws configure
```

Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., us-east-1)
- Output format (json)

## Usage

Initialize Terraform:
```bash
terraform init
```

Validate configuration:
```bash
terraform validate
```

Plan infrastructure changes:
```bash
terraform plan
```

Apply changes:
```bash
terraform apply
```

Destroy infrastructure:
```bash
terraform destroy
```

