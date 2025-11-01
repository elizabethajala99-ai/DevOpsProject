#!/bin/bash
# Infrastructure Testing Script
# Run this to test all tiers of your 3-tier architecture

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
KEY_PATH="$HOME/terraform_assignment/cba_keypair.pem"
BASTION_IP="18.133.220.243"
ECS_INSTANCE_1="10.0.3.16"
ECS_INSTANCE_2="10.0.4.158"
INTERNET_LB="internet-facing-lb-1108187320.eu-west-2.elb.amazonaws.com"
INTERNAL_LB="internal-app-internal-lb-1137168179.eu-west-2.elb.amazonaws.com"
DB_MASTER="db-master.cbu4cwq0inx2.eu-west-2.rds.amazonaws.com"
DB_SLAVE="db-slave.cbu4cwq0inx2.eu-west-2.rds.amazonaws.com"
DB_USER="mydbuser"
DB_PASS="MyNewSecurePassword!2024"
DB_NAME="mydatabase"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  3-Tier Infrastructure Testing${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Test 1: Bastion Host Connectivity
echo -e "${YELLOW}Test 1: Bastion Host Connectivity${NC}"
echo "Testing SSH to bastion host..."
if ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@$BASTION_IP "echo 'Bastion host connected successfully!'" 2>/dev/null; then
    echo -e "${GREEN}✓ Bastion host is accessible${NC}\n"
else
    echo -e "${RED}✗ Cannot connect to bastion host${NC}\n"
fi

# Test 2: Web Tier (Internet-facing Load Balancer)
echo -e "${YELLOW}Test 2: Web Tier (Internet-facing Load Balancer)${NC}"
echo "Testing frontend via internet-facing ALB..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://$INTERNET_LB)
if [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ Frontend is accessible (HTTP $RESPONSE)${NC}"
    echo "  URL: http://$INTERNET_LB"
else
    echo -e "${RED}✗ Frontend returned HTTP $RESPONSE${NC}"
fi

echo "Testing API health endpoint..."
curl -s http://$INTERNET_LB/api/health | jq . 2>/dev/null || echo "API response received"
echo ""

# Test 3: Application Tier (Internal Load Balancer)
echo -e "${YELLOW}Test 3: Application Tier (Internal Load Balancer)${NC}"
echo "Testing backend through internal ALB from bastion..."
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ubuntu@$BASTION_IP << 'EOFTEST'
echo "Checking if internal ALB is reachable from bastion..."
INTERNAL_LB="internal-app-internal-lb-1137168179.eu-west-2.elb.amazonaws.com"
if curl -s --max-time 5 http://$INTERNAL_LB:5000/api/health > /dev/null 2>&1; then
    echo "✓ Internal ALB is reachable on port 5000"
else
    echo "✗ Cannot reach internal ALB"
fi
EOFTEST
echo ""

# Test 4: ECS Container Instances
echo -e "${YELLOW}Test 4: ECS Container Instances${NC}"
echo "Checking ECS instances via bastion..."
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ubuntu@$BASTION_IP << EOFECS
echo "Testing connectivity to ECS instances..."
echo "ECS Instance 1: $ECS_INSTANCE_1"
if timeout 2 bash -c "cat < /dev/null > /dev/tcp/$ECS_INSTANCE_1/22" 2>/dev/null; then
    echo "✓ ECS Instance 1 is reachable"
else
    echo "✗ ECS Instance 1 not responding"
fi

echo "ECS Instance 2: $ECS_INSTANCE_2"
if timeout 2 bash -c "cat < /dev/null > /dev/tcp/$ECS_INSTANCE_2/22" 2>/dev/null; then
    echo "✓ ECS Instance 2 is reachable"
else
    echo "✗ ECS Instance 2 not responding"
fi
EOFECS
echo ""

# Test 5: Database Tier
echo -e "${YELLOW}Test 5: Database Tier (RDS MySQL)${NC}"
echo "Testing database connectivity from bastion..."
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ubuntu@$BASTION_IP << EOFDB
# Install mysql client if not present
if ! command -v mysql &> /dev/null; then
    echo "Installing MySQL client..."
    sudo apt-get update -qq && sudo apt-get install -y mysql-client > /dev/null 2>&1
fi

echo "Testing Master Database (read/write)..."
if mysql -h $DB_MASTER -u $DB_USER -p'$DB_PASS' -D $DB_NAME -e "SELECT 'Master connection successful' as status;" 2>/dev/null; then
    echo "✓ Master database is accessible"
    echo ""
    echo "Querying users table:"
    mysql -h $DB_MASTER -u $DB_USER -p'$DB_PASS' -D $DB_NAME -e "SELECT id, username, email, created_at FROM users ORDER BY id;" 2>/dev/null
else
    echo "✗ Cannot connect to master database"
fi

echo ""
echo "Testing Slave Database (read-only)..."
if mysql -h $DB_SLAVE -u $DB_USER -p'$DB_PASS' -D $DB_NAME -e "SELECT 'Slave connection successful' as status;" 2>/dev/null; then
    echo "✓ Slave database is accessible"
else
    echo "✗ Cannot connect to slave database"
fi
EOFDB
echo ""

# Test 6: End-to-End Sign-up Test
echo -e "${YELLOW}Test 6: End-to-End Sign-up Test${NC}"
echo "Testing user registration..."
TIMESTAMP=$(date +%s)
SIGNUP_RESPONSE=$(curl -s -X POST http://$INTERNET_LB/api/auth/signup \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"testuser$TIMESTAMP\",\"email\":\"test$TIMESTAMP@example.com\",\"password\":\"Test123!\"}")

if echo "$SIGNUP_RESPONSE" | grep -q "Account created"; then
    echo -e "${GREEN}✓ User registration successful${NC}"
    echo "$SIGNUP_RESPONSE" | jq . 2>/dev/null || echo "$SIGNUP_RESPONSE"
else
    echo -e "${RED}✗ User registration failed${NC}"
    echo "$SIGNUP_RESPONSE"
fi
echo ""

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Testing Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Key Endpoints:"
echo "  Frontend: http://$INTERNET_LB"
echo "  Bastion:  ssh -i $KEY_PATH ubuntu@$BASTION_IP"
echo "  Database: $DB_MASTER:3306"
echo ""
echo "To manually test database:"
echo "  1. SSH to bastion: ssh -i $KEY_PATH ubuntu@$BASTION_IP"
echo "  2. Connect to DB: mysql -h $DB_MASTER -u $DB_USER -p'$DB_PASS' -D $DB_NAME"
echo "  3. Query users: SELECT * FROM users;"
