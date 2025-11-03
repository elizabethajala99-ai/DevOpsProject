# 🚀 Complete Deployment Guide - 3-Tier AWS Application with SSM

This guide walks you through deploying the complete infrastructure from scratch on a fresh AWS account.

## 📋 **Prerequisites Checklist**

Before starting, ensure you have:

- ✅ AWS Account with admin access
- ✅ AWS CLI installed and configured
- ✅ Terraform installed (v1.0+)
- ✅ Git installed
- ✅ GitHub account with repository access
- ✅ SSH key pair for bastion host

---

## 🎯 **STEP 1: AWS Account Setup**

### 1.1 Create IAM User for Terraform

```bash
# Log into AWS Console
# Navigate to IAM → Users → Create User

# User details:
Name: terraform-deployer
Access: Programmatic access

# Attach policies:
- AmazonEC2FullAccess
- AmazonRDSFullAccess
- AmazonECS_FullAccess
- AmazonVPCFullAccess
- IAMFullAccess
- AmazonS3FullAccess
- CloudWatchFullAccess
- SecretsManagerReadWrite
- AWSCodePipelineFullAccess
- AWSCodeBuildAdminAccess

# Save the Access Key ID and Secret Access Key
```

### 1.2 Configure AWS CLI

```bash
# Configure AWS CLI with your credentials
aws configure

# Enter your credentials:
AWS Access Key ID: <your-access-key>
AWS Secret Access Key: <your-secret-key>
Default region name: eu-west-2
Default output format: json

# Verify configuration
aws sts get-caller-identity
```

### 1.3 Create EC2 Key Pair

```bash
# Create key pair for bastion host and ECS instances
aws ec2 create-key-pair \
  --key-name cba_keypair \
  --region eu-west-2 \
  --query 'KeyMaterial' \
  --output text > ~/cba_keypair.pem

# Set correct permissions
chmod 400 ~/cba_keypair.pem

# Move to project directory
mv ~/cba_keypair.pem /home/elizabeth/Group2_Project/
```

---

## 🎯 **STEP 2: Prepare Terraform Configuration**

### 2.1 Clone Your Repository

```bash
cd /home/elizabeth/Group2_Project/Final_Integration
git clone https://github.com/elizabethajala99-ai/DevOpsProject.git
cd DevOpsProject/3-Tier_Architecture_with_AWS
```

### 2.2 Update `terraform.tfvars`

Edit the file and customize these values:

```bash
nano terraform.tfvars
```

**Update these variables:**

```hcl
# AWS Configuration
aws_region = "eu-west-2"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"

# Database Configuration
db_username        = "admin"                    # Change if desired
db_password        = "YourSecurePassword123!"   # CHANGE THIS!
db_slave_password  = "YourSecureSlavePass123!"  # CHANGE THIS!
db_name            = "taskmanagement"

# Application Configuration
jwt_secret         = "your-super-secret-jwt-key-change-this-123456789"  # CHANGE THIS!
environment        = "production"

# GitHub Configuration (for CodePipeline)
github_owner       = "elizabethajala99-ai"      # Your GitHub username
github_repo        = "DevOpsProject"            # Your repo name
codestar_connection_arn = "arn:aws:codestar-connections:eu-west-2:XXXX:connection/XXXXX"  # CodeStar Connection ARN (see below)

# ECS Configuration
ecs_instance_type  = "t3.medium"
min_size           = 1
max_size           = 3
desired_capacity   = 2

# Monitoring
enable_monitoring  = true
```

### 2.3 Create CodeStar Connection to GitHub

AWS CodeStar Connections provide a secure way to connect CodePipeline to GitHub.

#### Option 1: Create via AWS Console (Recommended)

1. **Navigate to CodePipeline Settings:**
   ```
   AWS Console → Developer Tools → Settings → Connections
   ```

2. **Create Connection:**
   - Click "Create connection"
   - Provider: Select "GitHub"
   - Connection name: `github-connection`
   - Click "Connect to GitHub"

3. **Authorize GitHub:**
   - Click "Install a new app" or "Connect to GitHub"
   - You'll be redirected to GitHub
   - Authorize AWS Connector for GitHub
   - Select repositories: Choose "All repositories" or select "DevOpsProject"
   - Click "Install"

4. **Complete Connection:**
   - Back in AWS Console, you should see "Connection status: Available"
   - **Copy the Connection ARN** (format: `arn:aws:codestar-connections:eu-west-2:ACCOUNT_ID:connection/CONNECTION_ID`)

5. **Update terraform.tfvars:**
   ```hcl
   codestar_connection_arn = "arn:aws:codestar-connections:eu-west-2:123456789012:connection/abc123..."
   ```

#### Option 2: Create via AWS CLI

```bash
# Create the connection
aws codestar-connections create-connection \
  --provider-type GitHub \
  --connection-name github-connection \
  --region eu-west-2

# This returns a connection ARN, but status will be "PENDING"
# You MUST complete the handshake in AWS Console:
# Go to Developer Tools → Connections → Click "Update pending connection"
# Then authorize on GitHub

# Verify connection is available
aws codestar-connections get-connection \
  --connection-arn <your-connection-arn> \
  --region eu-west-2
```

**Important:** The connection must be in "AVAILABLE" status before running Terraform.

---

## 🎯 **STEP 3: Initialize Terraform**

### 3.1 Navigate to Terraform Directory

```bash
cd /home/elizabeth/Group2_Project/Final_Integration/DevOpsProject/3-Tier_Architecture_with_AWS
```

### 3.2 Initialize Terraform

```bash
# Initialize Terraform (downloads providers)
terraform init

# Expected output:
# Terraform has been successfully initialized!
```

### 3.3 Validate Configuration

```bash
# Check for syntax errors
terraform validate

# Expected output:
# Success! The configuration is valid.
```

### 3.4 Plan the Deployment

```bash
# See what will be created
terraform plan

# Review the output - you should see:
# - ~60+ resources to create
# - VPC, subnets, NAT gateway, Internet gateway
# - RDS instances (master + slave)
# - ECS cluster, services, task definitions
# - Load balancers (2)
# - Security groups
# - SSM parameters (6)
# - Secrets Manager secrets (3)
# - CodePipeline, CodeBuild projects
# - ECR repositories (2)
```

---

## 🎯 **STEP 4: Deploy Infrastructure (Phase 1 - Networking)**

### 4.1 Create VPC and Networking First

To avoid timeouts, deploy in phases:

```bash
# Create just the VPC and networking resources
terraform apply -target=aws_vpc.main_vpc \
                -target=aws_subnet.public_subnet_1 \
                -target=aws_subnet.public_subnet_2 \
                -target=aws_subnet.private_subnet_1 \
                -target=aws_subnet.private_subnet_2 \
                -target=aws_internet_gateway.main_igw \
                -target=aws_eip.nat \
                -target=aws_nat_gateway.main_nat \
                -target=aws_route_table.public_route_table \
                -target=aws_route_table.private_route_table

# Type 'yes' when prompted
```

**Wait time:** ~5 minutes (NAT Gateway takes time)

---

## 🎯 **STEP 5: Deploy Infrastructure (Phase 2 - Security & Database)**

### 5.1 Create Security Groups and RDS

```bash
# Deploy security groups
terraform apply -target=aws_security_group.alb_web_sg \
                -target=aws_security_group.alb_app_sg \
                -target=aws_security_group.ecs_instance_sg \
                -target=aws_security_group.db_sg \
                -target=aws_security_group.bastion_sg

# Type 'yes' when prompted

# Deploy database subnet group and RDS
terraform apply -target=aws_db_subnet_group.main \
                -target=aws_db_instance.database_master

# Type 'yes' when prompted
```

**Wait time:** ~10-15 minutes (RDS creation takes time)

### 5.2 Create Read Replica

```bash
# Deploy RDS read replica
terraform apply -target=aws_db_instance.database_slave

# Type 'yes' when prompted
```

**Wait time:** ~10 minutes

---

## 🎯 **STEP 6: Deploy Infrastructure (Phase 3 - SSM & Secrets)**

### 6.1 Create SSM Parameters and Secrets Manager

```bash
# Deploy KMS key first
terraform apply -target=aws_kms_key.parameter_store_key \
                -target=aws_kms_alias.parameter_store_key_alias

# Deploy SSM parameters
terraform apply -target=aws_ssm_parameter.database_host \
                -target=aws_ssm_parameter.database_username \
                -target=aws_ssm_parameter.database_name \
                -target=aws_ssm_parameter.database_port \
                -target=aws_ssm_parameter.app_environment

# Deploy Secrets Manager
terraform apply -target=aws_secretsmanager_secret.database_password \
                -target=aws_secretsmanager_secret.database_slave_password \
                -target=aws_secretsmanager_secret.jwt_secret

# Type 'yes' when prompted
```

**Wait time:** ~2 minutes

---

## 🎯 **STEP 7: Deploy Infrastructure (Phase 4 - ECS & CI/CD)**

### 7.1 Create ECS Cluster and Load Balancers

```bash
# Deploy ECR repositories
terraform apply -target=aws_ecr_repository.frontend \
                -target=aws_ecr_repository.backend

# Deploy load balancers
terraform apply -target=aws_lb.internet_facing_lb \
                -target=aws_lb.internal_lb \
                -target=aws_lb_target_group.internet_facing_tg \
                -target=aws_lb_target_group.internal_tg

# Deploy ECS cluster
terraform apply -target=aws_ecs_cluster.main

# Type 'yes' when prompted
```

**Wait time:** ~5 minutes

### 7.2 Deploy Complete Infrastructure

```bash
# Now deploy everything else
terraform apply

# Review the plan carefully
# Type 'yes' when prompted
```

**Wait time:** ~10-15 minutes

---

## 🎯 **STEP 8: Initial Docker Image Build**

### 8.1 Build and Push Initial Images to ECR

Before CodePipeline can deploy, you need initial images in ECR:

```bash
# Get ECR login token
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin 125905899300.dkr.ecr.eu-west-2.amazonaws.com

# Navigate to frontend directory
cd /home/elizabeth/Group2_Project/Final_Integration/DevOpsProject/frontend

# Build frontend image
docker build -t frontend-repo .

# Tag frontend image
docker tag frontend-repo:latest 125905899300.dkr.ecr.eu-west-2.amazonaws.com/frontend-repo:latest

# Push frontend image
docker push 125905899300.dkr.ecr.eu-west-2.amazonaws.com/frontend-repo:latest

# Navigate to backend directory
cd ../backend

# Build backend image
docker build -t backend-repo .

# Tag backend image
docker tag backend-repo:latest 125905899300.dkr.ecr.eu-west-2.amazonaws.com/backend-repo:latest

# Push backend image
docker push 125905899300.dkr.ecr.eu-west-2.amazonaws.com/backend-repo:latest
```

**Wait time:** ~5-10 minutes (depending on internet speed)

---

## 🎯 **STEP 9: Update SSM Parameter (After Load Balancers Created)**

### 9.1 Get Internal Load Balancer DNS

```bash
# Get internal ALB DNS name
terraform output internal_lb_dns
```

### 9.2 Update Frontend API URL Parameter

```bash
# Update the SSM parameter with correct ALB DNS
aws ssm put-parameter \
  --name "/myapp/frontend/api-url" \
  --value "http://<your-internal-alb-dns>:5000" \
  --overwrite \
  --region eu-west-2

# Or run targeted terraform apply
terraform apply -target=aws_ssm_parameter.frontend_api_url
```

---

## 🎯 **STEP 10: Trigger CodePipeline**

### 10.1 Push Code to GitHub (Triggers Pipeline)

```bash
cd /home/elizabeth/Group2_Project/Final_Integration/DevOpsProject

# Ensure all files are committed
git add .
git commit -m "Initial deployment - trigger pipeline"
git push origin main
```

### 10.2 Monitor Pipeline Execution

```bash
# Watch pipeline status
aws codepipeline get-pipeline-state --name three-tier-pipeline --region eu-west-2

# Or check in AWS Console:
# CodePipeline → three-tier-pipeline
```

**Wait time:** ~10-15 minutes for complete pipeline

---

## 🎯 **STEP 11: Verify Deployment**

### 11.1 Get Application URLs

```bash
# Get all outputs
terraform output

# Important outputs:
# - internet_facing_lb_dns: <public-url>
# - bastion_host_public_ip: <bastion-ip>
```

### 11.2 Test Frontend

```bash
# Test frontend (in browser or curl)
curl http://<internet-facing-lb-dns>/

# Expected: HTML page loads
```

### 11.3 Test API Health

```bash
# Test backend health endpoint
curl http://<internet-facing-lb-dns>/api/health

# Expected: {"status":"ok","timestamp":"..."}
```

### 11.4 SSH to Bastion and Test Database

```bash
# SSH to bastion
ssh -i /home/elizabeth/Group2_Project/cba_keypair.pem ubuntu@<bastion-ip>

# Test database connection
./connect-to-db.sh

# Expected: MySQL prompt
# mysql> SHOW DATABASES;
```

---

## 🎯 **STEP 12: Verify Application Functionality**

### 12.1 Open Application in Browser

```
http://<internet-facing-lb-dns>/
```

### 12.2 Test User Registration

1. Click "Sign Up"
2. Enter email and password
3. Register new user
4. Expected: Redirect to login

### 12.3 Test Login and Task Creation

1. Login with registered credentials
2. Create a new task
3. Verify task appears in list
4. Test mark complete/delete

---

## 📊 **Deployment Summary**

| Phase | Resources Created | Time | Status |
|-------|------------------|------|--------|
| 1. Networking | VPC, Subnets, NAT, IGW | ~5 min | |
| 2. Security & DB | Security Groups, RDS | ~20 min | |
| 3. SSM & Secrets | Parameters, Secrets, KMS | ~2 min | |
| 4. ECS & CI/CD | ECS, ECR, CodePipeline | ~15 min | |
| 5. Initial Build | Docker images to ECR | ~10 min | |
| 6. Pipeline Run | Build & deploy containers | ~15 min | |
| **Total** | **~60 resources** | **~70 min** | |

---

## 🔧 **Troubleshooting**

### Issue: Terraform timeout on RDS creation

```bash
# Increase timeout or create RDS separately
terraform apply -target=aws_db_instance.database_master
```

### Issue: CodePipeline fails on first run

```bash
# Check if ECR images exist
aws ecr list-images --repository-name frontend-repo --region eu-west-2
aws ecr list-images --repository-name backend-repo --region eu-west-2

# If empty, manually push images (see Step 8)
```

### Issue: 504 Gateway Timeout

```bash
# Check ECS task logs
aws logs tail /ecs/frontend --follow --region eu-west-2
aws logs tail /ecs/backend --follow --region eu-west-2

# Check if tasks are running
aws ecs list-tasks --cluster three-tier-ecs-cluster --region eu-west-2
```

### Issue: Database connection failed

```bash
# Verify security groups allow backend → RDS
aws ec2 describe-security-groups --filters "Name=group-name,Values=db-security-group" --region eu-west-2

# Check RDS status
aws rds describe-db-instances --region eu-west-2
```

---

## 🧹 **Cleanup (Destroy Infrastructure)**

```bash
# WARNING: This destroys ALL resources

# Navigate to Terraform directory
cd /home/elizabeth/Group2_Project/Final_Integration/DevOpsProject/3-Tier_Architecture_with_AWS

# Destroy in reverse order
terraform destroy

# Type 'yes' when prompted
```

**Cost to run for 1 hour:** ~$2
**Cost to run for 1 month (continuous):** ~$120-150

---

## 📚 **Additional Resources**

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [SSM Parameter Store Guide](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
- [AWS CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/)

---

## ✅ **Next Steps After Deployment**

1. Set up custom domain name with Route 53
2. Add SSL/TLS certificate with ACM
3. Configure CloudWatch alarms for monitoring
4. Set up automated backups for RDS
5. Implement WAF rules for security
6. Configure auto-scaling policies

---

**Deployment completed!** 🎉

Your 3-tier application with SSM Parameter Store and Secrets Manager is now live on AWS!
