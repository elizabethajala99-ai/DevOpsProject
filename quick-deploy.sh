#!/bin/bash
# Quick Deployment Script for 3-Tier AWS Application
# This script automates the deployment process

set -e  # Exit on error

echo "=================================="
echo "3-Tier AWS Application Deployment"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Check prerequisites
echo "Checking prerequisites..."

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI not found. Please install it first."
    exit 1
fi
print_success "AWS CLI found"

# Check Terraform
if ! command -v terraform &> /dev/null; then
    print_error "Terraform not found. Please install it first."
    exit 1
fi
print_success "Terraform found"

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured. Run 'aws configure' first."
    exit 1
fi
print_success "AWS credentials configured"

# Get AWS account info
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)
print_info "AWS Account: $AWS_ACCOUNT_ID"
print_info "AWS Region: $AWS_REGION"

echo ""
echo "=================================="
echo "Deployment Options"
echo "=================================="
echo "1. Full deployment (all at once)"
echo "2. Phased deployment (recommended for fresh account)"
echo "3. Just initialize Terraform"
echo "4. Destroy all infrastructure"
echo ""

read -p "Select option (1-4): " OPTION

case $OPTION in
    1)
        echo ""
        print_info "Starting full deployment..."
        cd 3-Tier_Architecture_with_AWS
        
        print_info "Initializing Terraform..."
        terraform init
        
        print_info "Validating configuration..."
        terraform validate
        
        print_info "Planning deployment..."
        terraform plan -out=tfplan
        
        echo ""
        read -p "Review the plan above. Continue with apply? (yes/no): " CONFIRM
        
        if [ "$CONFIRM" = "yes" ]; then
            print_info "Applying Terraform configuration..."
            terraform apply tfplan
            print_success "Deployment complete!"
            
            echo ""
            echo "=================================="
            echo "Deployment Outputs"
            echo "=================================="
            terraform output
        else
            print_warning "Deployment cancelled"
        fi
        ;;
        
    2)
        echo ""
        print_info "Starting phased deployment..."
        cd 3-Tier_Architecture_with_AWS
        
        # Phase 1: Initialize
        print_info "Phase 1: Initializing Terraform..."
        terraform init
        terraform validate
        print_success "Initialization complete"
        
        echo ""
        read -p "Continue to Phase 2 (Networking)? (yes/no): " CONFIRM
        if [ "$CONFIRM" != "yes" ]; then exit 0; fi
        
        # Phase 2: Networking
        print_info "Phase 2: Deploying VPC and Networking..."
        terraform apply -auto-approve \
            -target=aws_vpc.main_vpc \
            -target=aws_subnet.public_subnet_1 \
            -target=aws_subnet.public_subnet_2 \
            -target=aws_subnet.private_subnet_1 \
            -target=aws_subnet.private_subnet_2 \
            -target=aws_internet_gateway.main_igw \
            -target=aws_eip.nat \
            -target=aws_nat_gateway.main_nat \
            -target=aws_route_table.public_route_table \
            -target=aws_route_table.private_route_table \
            -target=aws_route_table_association.public_subnet_1_association \
            -target=aws_route_table_association.public_subnet_2_association \
            -target=aws_route_table_association.private_subnet_1_association \
            -target=aws_route_table_association.private_subnet_2_association
        print_success "Networking deployed (wait for NAT Gateway ~5 min)"
        
        echo ""
        read -p "Continue to Phase 3 (Security & Database)? (yes/no): " CONFIRM
        if [ "$CONFIRM" != "yes" ]; then exit 0; fi
        
        # Phase 3: Security Groups and RDS
        print_info "Phase 3: Deploying Security Groups and Database..."
        terraform apply -auto-approve \
            -target=aws_security_group.alb_web_sg \
            -target=aws_security_group.alb_app_sg \
            -target=aws_security_group.ecs_instance_sg \
            -target=aws_security_group.db_sg \
            -target=aws_security_group.bastion_sg \
            -target=aws_security_group_rule.alb_app_from_ecs \
            -target=aws_security_group_rule.alb_app_from_bastion \
            -target=aws_db_subnet_group.main \
            -target=aws_db_instance.database_master
        print_success "Security groups and master database deployed (~15 min for RDS)"
        
        echo ""
        read -p "Continue to Phase 4 (SSM & Secrets)? (yes/no): " CONFIRM
        if [ "$CONFIRM" != "yes" ]; then exit 0; fi
        
        # Phase 4: SSM and Secrets
        print_info "Phase 4: Deploying SSM Parameters and Secrets Manager..."
        terraform apply -auto-approve \
            -target=aws_kms_key.parameter_store_key \
            -target=aws_kms_alias.parameter_store_key_alias
        
        terraform apply -auto-approve \
            -target=aws_ssm_parameter.database_host \
            -target=aws_ssm_parameter.database_username \
            -target=aws_ssm_parameter.database_name \
            -target=aws_ssm_parameter.database_port \
            -target=aws_ssm_parameter.app_environment \
            -target=aws_secretsmanager_secret.database_password \
            -target=aws_secretsmanager_secret.database_slave_password \
            -target=aws_secretsmanager_secret.jwt_secret \
            -target=aws_secretsmanager_secret_version.database_password \
            -target=aws_secretsmanager_secret_version.database_slave_password \
            -target=aws_secretsmanager_secret_version.jwt_secret
        print_success "SSM and Secrets deployed"
        
        echo ""
        read -p "Continue to Phase 5 (Complete deployment)? (yes/no): " CONFIRM
        if [ "$CONFIRM" != "yes" ]; then exit 0; fi
        
        # Phase 5: Complete deployment
        print_info "Phase 5: Deploying remaining resources..."
        terraform apply
        print_success "Full deployment complete!"
        
        echo ""
        echo "=================================="
        echo "Deployment Outputs"
        echo "=================================="
        terraform output
        ;;
        
    3)
        echo ""
        print_info "Initializing Terraform..."
        cd 3-Tier_Architecture_with_AWS
        terraform init
        terraform validate
        print_success "Terraform initialized and validated"
        ;;
        
    4)
        echo ""
        print_warning "This will DESTROY all infrastructure!"
        read -p "Are you sure? Type 'destroy' to confirm: " CONFIRM
        
        if [ "$CONFIRM" = "destroy" ]; then
            cd 3-Tier_Architecture_with_AWS
            print_info "Destroying infrastructure..."
            terraform destroy
            print_success "Infrastructure destroyed"
        else
            print_warning "Destruction cancelled"
        fi
        ;;
        
    *)
        print_error "Invalid option selected"
        exit 1
        ;;
esac

echo ""
print_success "Script completed!"
