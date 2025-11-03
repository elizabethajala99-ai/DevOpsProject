#!/bin/bash
# Post-Deployment Verification Script
# Run this after deployment to verify everything is working

set -e

echo "=================================="
echo "Post-Deployment Verification"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${YELLOW}→ $1${NC}"; }

# Get outputs
cd 3-Tier_Architecture_with_AWS

print_info "Getting deployment outputs..."
FRONTEND_URL=$(terraform output -raw internet_facing_lb_dns 2>/dev/null || echo "")
BASTION_IP=$(terraform output -raw bastion_host_public_ip 2>/dev/null || echo "")
INTERNAL_ALB=$(terraform output -raw internal_lb_dns 2>/dev/null || echo "")

if [ -z "$FRONTEND_URL" ]; then
    print_error "Could not get Terraform outputs. Run 'terraform apply' first."
    exit 1
fi

print_success "Got deployment outputs"
echo ""

echo "=================================="
echo "Infrastructure Check"
echo "=================================="

# Check 1: Frontend reachable
print_info "Testing frontend (http://$FRONTEND_URL)..."
if curl -s -o /dev/null -w "%{http_code}" "http://$FRONTEND_URL/" | grep -q "200"; then
    print_success "Frontend is reachable"
else
    print_error "Frontend is NOT reachable"
fi

# Check 2: API health endpoint
print_info "Testing API health endpoint..."
API_RESPONSE=$(curl -s "http://$FRONTEND_URL/api/health" 2>/dev/null || echo "")
if echo "$API_RESPONSE" | grep -q "ok"; then
    print_success "Backend API is healthy"
else
    print_error "Backend API is NOT responding correctly"
    echo "Response: $API_RESPONSE"
fi

# Check 3: ECS tasks running
print_info "Checking ECS tasks..."
FRONTEND_TASKS=$(aws ecs list-tasks --cluster three-tier-ecs-cluster --service-name frontend-service --region eu-west-2 --query 'taskArns' --output text 2>/dev/null | wc -w)
BACKEND_TASKS=$(aws ecs list-tasks --cluster three-tier-ecs-cluster --service-name backend-service --region eu-west-2 --query 'taskArns' --output text 2>/dev/null | wc -w)

if [ "$FRONTEND_TASKS" -ge 1 ] && [ "$BACKEND_TASKS" -ge 1 ]; then
    print_success "ECS tasks running (Frontend: $FRONTEND_TASKS, Backend: $BACKEND_TASKS)"
else
    print_error "Not enough ECS tasks running (Frontend: $FRONTEND_TASKS, Backend: $BACKEND_TASKS)"
fi

# Check 4: RDS status
print_info "Checking RDS instances..."
RDS_STATUS=$(aws rds describe-db-instances --region eu-west-2 --query 'DBInstances[?DBInstanceIdentifier==`db-master`].DBInstanceStatus' --output text 2>/dev/null || echo "")
if [ "$RDS_STATUS" = "available" ]; then
    print_success "RDS master database is available"
else
    print_error "RDS master database status: $RDS_STATUS"
fi

# Check 5: SSM parameters
print_info "Checking SSM parameters..."
SSM_COUNT=$(aws ssm describe-parameters --parameter-filters "Key=Name,Values=/myapp/" --region eu-west-2 --query 'length(Parameters)' --output text 2>/dev/null || echo "0")
if [ "$SSM_COUNT" -ge 6 ]; then
    print_success "SSM parameters configured ($SSM_COUNT found)"
else
    print_error "SSM parameters missing (expected 6, found $SSM_COUNT)"
fi

# Check 6: Secrets Manager
print_info "Checking Secrets Manager..."
SECRETS_COUNT=$(aws secretsmanager list-secrets --region eu-west-2 --query 'length(SecretList[?starts_with(Name, `/myapp/`)])' --output text 2>/dev/null || echo "0")
if [ "$SECRETS_COUNT" -ge 3 ]; then
    print_success "Secrets Manager configured ($SECRETS_COUNT secrets)"
else
    print_error "Secrets missing (expected 3, found $SECRETS_COUNT)"
fi

# Check 7: CodePipeline status
print_info "Checking CodePipeline..."
PIPELINE_STATUS=$(aws codepipeline get-pipeline-state --name three-tier-pipeline --region eu-west-2 --query 'stageStates[0].latestExecution.status' --output text 2>/dev/null || echo "")
if [ "$PIPELINE_STATUS" = "Succeeded" ]; then
    print_success "CodePipeline last run: Succeeded"
elif [ "$PIPELINE_STATUS" = "InProgress" ]; then
    print_info "CodePipeline currently running"
else
    print_error "CodePipeline status: $PIPELINE_STATUS"
fi

echo ""
echo "=================================="
echo "Summary"
echo "=================================="
echo ""
echo "Frontend URL: http://$FRONTEND_URL"
echo "Bastion IP: $BASTION_IP"
echo "Internal ALB: $INTERNAL_ALB"
echo ""
echo "SSH to bastion:"
echo "  ssh -i ~/cba_keypair.pem ubuntu@$BASTION_IP"
echo ""
echo "Test application:"
echo "  Open browser: http://$FRONTEND_URL"
echo ""
echo "Check logs:"
echo "  aws logs tail /ecs/frontend --follow --region eu-west-2"
echo "  aws logs tail /ecs/backend --follow --region eu-west-2"
echo ""

print_success "Verification complete!"
