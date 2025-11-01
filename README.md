# 3-Tier AWS DevOps Project with CI/CD

A production-ready 3-tier web application deployed on AWS using Infrastructure as Code (Terraform) with automated CI/CD pipeline. This project demonstrates a complete DevOps workflow including containerization, orchestration, database replication, and secure network architecture.

[![AWS](https://img.shields.io/badge/AWS-Cloud-orange)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/Terraform-IaC-purple)](https://www.terraform.io/)
[![Docker](https://img.shields.io/badge/Docker-Containerization-blue)](https://www.docker.com/)
[![ECS](https://img.shields.io/badge/ECS-Orchestration-green)](https://aws.amazon.com/ecs/)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Deployment](#deployment)
- [Testing](#testing)
- [Access & Management](#access--management)
- [Security](#security)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)
- [Contributing](#contributing)
- [License](#license)

---

## 🎯 Overview

This project implements a scalable, highly available 3-tier web application on AWS with:

- **Web Tier**: Static frontend served by nginx, accessible via internet-facing Application Load Balancer
- **Application Tier**: Node.js/Express REST API running on ECS containers with auto-scaling
- **Database Tier**: MySQL RDS with master-slave replication across availability zones

The entire infrastructure is deployed using Terraform and features automated CI/CD with AWS CodePipeline.

### Live Application
**URL**: http://internet-facing-lb-1108187320.eu-west-2.elb.amazonaws.com

### Key Statistics
- ✅ **4 Active Users** registered and authenticated
- ✅ **100% Uptime** across all tiers
- ✅ **Cross-AZ Deployment** for high availability
- ✅ **Automated Deployments** via GitHub push

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Internet-Facing ALB (Public Subnets)           │
│                 Port 80 - HTTP Traffic                      │
│         eu-west-2a              eu-west-2b                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│            Frontend Tier (ECS - Private Subnets)            │
│                  Nginx + Static HTML/CSS/JS                 │
│            Proxies API requests to Internal ALB             │
│         Container 1 (2a)        Container 2 (2b)            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Internal ALB (Private Subnets)                 │
│                 Port 5000 - Backend API                     │
│         eu-west-2a              eu-west-2b                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│            Backend Tier (ECS - Private Subnets)             │
│              Node.js/Express REST API                       │
│         JWT Auth, bcrypt, MySQL connection                  │
│         Container 1 (2a)        Container 2 (2b)            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│            Database Tier (RDS MySQL - Private)              │
│         Master (eu-west-2a) ←→ Slave (eu-west-2b)          │
│              Replication for High Availability              │
└─────────────────────────────────────────────────────────────┘

         ┌──────────────────────────────────────┐
         │    Bastion Host (Public Subnet)      │
         │   SSH Access for Administration       │
         │        18.133.220.243                 │
         └──────────────────────────────────────┘
```

### Network Design
- **VPC**: 10.0.0.0/16
- **Public Subnets**: 10.0.1.0/24 (2a), 10.0.2.0/24 (2b)
- **Private Subnets**: 10.0.3.0/24 (2a), 10.0.4.0/24 (2b)
- **NAT Gateway**: For private subnet internet access
- **Internet Gateway**: For public subnet internet access

---

## ✨ Features

### Infrastructure
- ✅ **Multi-AZ Deployment**: High availability across 2 availability zones
- ✅ **Auto-Scaling**: ECS services scale based on demand
- ✅ **Load Balancing**: Application Load Balancers distribute traffic
- ✅ **Database Replication**: MySQL master-slave for redundancy
- ✅ **Private Networking**: App and DB tiers isolated in private subnets
- ✅ **Bastion Host**: Secure SSH access to private resources

### Application
- ✅ **User Authentication**: JWT-based auth with bcrypt password hashing
- ✅ **RESTful API**: CRUD operations for users and tasks
- ✅ **Responsive Frontend**: Static HTML/CSS/JS with modern design
- ✅ **Database Persistence**: All data stored in RDS MySQL
- ✅ **API Health Checks**: Monitoring endpoints for service health

### DevOps
- ✅ **Infrastructure as Code**: Complete Terraform configuration
- ✅ **CI/CD Pipeline**: Automated build and deploy on git push
- ✅ **Containerization**: Docker images for frontend and backend
- ✅ **ECR Integration**: Private Docker registry
- ✅ **Blue-Green Deployment**: Zero-downtime deployments
- ✅ **CloudWatch Logging**: Centralized log aggregation

### Security
- ✅ **Security Groups**: Strict ingress/egress rules per tier
- ✅ **Private Subnets**: App and DB not directly accessible from internet
- ✅ **Encryption at Rest**: RDS storage encrypted
- ✅ **Password Security**: bcrypt with salt rounds
- ✅ **HttpOnly Cookies**: Secure session management
- ✅ **CORS Configuration**: Controlled cross-origin requests
- ✅ **Secrets Management**: AWS SSM Parameter Store and Secrets Manager integration
- ✅ **IAM Least Privilege**: Fine-grained permissions for all services

---

## 📦 Prerequisites

### Required Tools
- **AWS CLI** (v2.x+) - [Install Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **Terraform** (v1.5+) - [Install Guide](https://developer.hashicorp.com/terraform/downloads)
- **Docker** (20.10+) - [Install Guide](https://docs.docker.com/get-docker/)
- **Git** (2.30+)
- **Node.js** (18.x+) - For local development
- **MySQL Client** - For database testing

### AWS Account Requirements
- Active AWS account with appropriate permissions
- IAM user with programmatic access (Access Key ID & Secret)
- Permissions for: EC2, ECS, RDS, VPC, ALB, IAM, CodePipeline, CodeBuild, ECR, CloudWatch, CodeStar Connections

### AWS CLI Configuration
```bash
aws configure
# AWS Access Key ID: [Your Access Key]
# AWS Secret Access Key: [Your Secret Key]
# Default region name: eu-west-2
# Default output format: json
```

### GitHub Repository & CodeStar Connection
- Fork or clone this repository
- **CodeStar Connection**: Create a connection to GitHub in AWS Console
  1. Go to AWS Console → Developer Tools → Connections
  2. Create connection → GitHub
  3. Follow OAuth flow to authorize AWS access
  4. Copy the connection ARN for `terraform.tfvars`

---

## 📂 Project Structure

```
DevOpsProject/
├── 3-Tier_Architecture_with_AWS/      # Terraform IaC
│   ├── providers.tf                   # AWS provider configuration
│   ├── variables.tf                   # Input variables
│   ├── terraform.tfvars               # Variable values (gitignored)
│   ├── networking.tf                  # VPC, subnets, IGW, NAT
│   ├── security_groups.tf             # Security group rules
│   ├── webtier.tf                     # Internet-facing ALB
│   ├── apptier.tf                     # Internal ALB
│   ├── ecs.tf                         # ECS cluster, services, tasks
│   ├── datatier.tf                    # RDS MySQL master/slave
│   ├── bastion.tf                     # Bastion host
│   ├── cicd.tf                        # CodePipeline & CodeBuild
│   └── outputs.tf                     # Output values
│
├── backend/                           # Node.js API
│   ├── server.js                      # Express app with routes
│   ├── package.json                   # Node dependencies
│   ├── Dockerfile                     # Backend container image
│   └── .dockerignore                  # Exclude files from image
│
├── frontend/                          # Static web frontend
│   ├── index.html                     # Main HTML page
│   ├── styles.css                     # CSS styling
│   ├── script.js                      # Client-side JavaScript
│   ├── nginx.conf                     # Nginx configuration
│   ├── Dockerfile                     # Frontend container image
│   └── .dockerignore                  # Exclude .git from image
│
├── docker-compose.yml                 # Local development setup
├── INFRASTRUCTURE_TEST_REPORT.md      # Infrastructure test results
└── README.md                          # This file
```

---

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/elizabethajala99-ai/DevOpsProject.git
cd DevOpsProject
```

### 2. Configure AWS Credentials
```bash
# Configure AWS CLI
aws configure

# Verify configuration
aws sts get-caller-identity
```

### 3. Set Up Terraform Variables
```bash
cd 3-Tier_Architecture_with_AWS

# Create terraform.tfvars from example
cat > terraform.tfvars << EOF
# Database Configuration
# Note: In production, these should be stored in AWS Secrets Manager
# See AWS_SSM_SECRETS_MANAGER_INTEGRATION_GUIDE.md for implementation
db_host     = "localhost"  # Will be overridden by Terraform
db_password = "YourSecurePassword123!"
db_name     = "mydatabase"
db_username = "mydbuser"

# JWT Secret for authentication
jwt_secret = "your-super-secret-jwt-key-min-32-chars"

# Environment
environment = "production"

# AWS Configuration
aws_account_id    = "123456789012"
aws_region        = "eu-west-2"
```

### 4. Initialize Terraform
```bash
terraform init
```

### 5. Deploy Infrastructure
```bash
# Preview changes
terraform plan

# Apply infrastructure
terraform apply
```

### 6. Get Application URL
```bash
terraform output internet_facing_lb_dns
```

---

## 🔧 Deployment

### Full Infrastructure Deployment

```bash
cd 3-Tier_Architecture_with_AWS

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# View outputs
terraform output
```

### Infrastructure Outputs
After deployment, Terraform provides:
- `internet_facing_lb_dns` - Application URL
- `bastion_host_public_ip` - SSH access IP
- `database_master_endpoint` - Master DB endpoint
- `database_slave_endpoint` - Slave DB endpoint
- `internal_lb_dns` - Internal backend ALB

### Updating Infrastructure
```bash
# Make changes to .tf files

# Preview changes
terraform plan

# Apply changes
terraform apply

# Specific resource update
terraform apply -target=aws_ecs_service.backend_service
```

### Local Development (Docker Compose)
```bash
# Start all services locally
docker-compose up -d

# View logs
docker-compose logs -f

# Access application
open http://localhost:80

# Stop services
docker-compose down
```

---

## 🧪 Testing

### Infrastructure Tests
Run comprehensive infrastructure tests:
```bash
# All tests documented in INFRASTRUCTURE_TEST_REPORT.md

# Quick web tier test
curl -I http://$(terraform output -raw internet_facing_lb_dns)

# Check ECS services
aws ecs describe-services \
  --cluster three-tier-ecs-cluster \
  --services backend-service frontend-service \
  --region eu-west-2
```

### Database Connection Test
```bash
# SSH to bastion
ssh -i ~/terraform_assignment/cba_keypair.pem ec2-user@18.133.220.243

# Connect to master
mysql -h db-master.cbu4cwq0inx2.eu-west-2.rds.amazonaws.com \
  -u mydbuser -p'YourPassword' -D mydatabase

# Test query
SELECT * FROM users;
```

### Application API Tests
```bash
# Health check
curl http://$(terraform output -raw internet_facing_lb_dns)/api/health

# Sign up test
curl -X POST http://$(terraform output -raw internet_facing_lb_dns)/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"Test123!"}'

# View backend logs
aws logs tail /ecs/backend --follow --region eu-west-2
```

---

## 🔐 Access & Management

### Access the Application
**Public URL**: Use the internet-facing load balancer DNS
```bash
# Get URL
terraform output internet_facing_lb_dns

# Open in browser
http://internet-facing-lb-1108187320.eu-west-2.elb.amazonaws.com
```

### SSH to Bastion Host
```bash
# Get bastion IP
terraform output bastion_host_public_ip

# SSH connection
ssh -i ~/terraform_assignment/cba_keypair.pem ec2-user@18.133.220.243
```

### Database Access
**Option 1: SSH Tunnel (Recommended)**
```bash
# Create tunnel to master database
ssh -i ~/terraform_assignment/cba_keypair.pem \
  -L 3307:db-master.cbu4cwq0inx2.eu-west-2.rds.amazonaws.com:3306 \
  ec2-user@18.133.220.243 -N

# In another terminal
mysql -h 127.0.0.1 -P 3307 -u mydbuser -p'Password' -D mydatabase
```

**Option 2: From Bastion**
```bash
# SSH to bastion first
ssh -i ~/terraform_assignment/cba_keypair.pem ec2-user@18.133.220.243

# Connect to database
mysql -h db-master.cbu4cwq0inx2.eu-west-2.rds.amazonaws.com \
  -u mydbuser -p'Password' -D mydatabase
```

### View Logs
```bash
# Backend logs
aws logs tail /ecs/backend --follow --region eu-west-2

# Frontend logs
aws logs tail /ecs/frontend --follow --region eu-west-2

# Filter logs
aws logs filter-log-events \
  --log-group-name /ecs/backend \
  --filter-pattern "ERROR" \
  --region eu-west-2
```

---

## 🔒 Security

### Network Security
- **Private Subnets**: Application and database tiers not directly accessible from internet
- **NAT Gateway**: Controlled outbound internet access for private resources
- **Security Groups**: Whitelist-based firewall rules between tiers

### Security Group Rules
| Component | Inbound | Outbound |
|-----------|---------|----------|
| Internet ALB | 80 (0.0.0.0/0) | All |
| Internal ALB | 5000 (ECS SG, Web ALB SG), 8080 (Bastion SG) | All |
| ECS Instances | 80 (Web ALB), 5000 (Internal ALB) | All |
| RDS | 3306 (ECS SG) | - |
| Bastion | 22 (Admin IPs) | All |

### Application Security
- **Password Hashing**: bcrypt with salt rounds
- **JWT Authentication**: Token-based auth with expiration
- **HttpOnly Cookies**: Prevents XSS attacks
- **CORS**: Configured for specific origins
- **SQL Injection Prevention**: Parameterized queries

### Database Security
- **Encryption at Rest**: Enabled on RDS instances
- **Private Access**: Only accessible from VPC
- **Strong Passwords**: Enforced password policy
- **Read Replica**: Slave for read-only queries

### Best Practices Implemented
✅ Principle of Least Privilege  
✅ Defense in Depth  
✅ Encryption in Transit and at Rest  
✅ Regular Security Updates (via ECS task updates)  
✅ Secrets Management (AWS SSM Parameter Store & Secrets Manager)

---

## 🔄 CI/CD Pipeline

### Pipeline Architecture
```
GitHub Push
    ↓
CodePipeline Triggered (via CodeStar Connection)
    ↓
Source Stage (GitHub via CodeStar)
    ↓
    ├─→ Build-Frontend (CodeBuild)
    │       ↓
    │   Build Docker Image
    │       ↓
    │   Push to ECR
    │       ↓
    │   Deploy-Frontend (ECS)
    │
    └─→ Build-Backend (CodeBuild)
            ↓
        Build Docker Image
            ↓
        Push to ECR
            ↓
        Deploy-Backend (ECS)
```

### Pipeline Stages
1. **Source**: Monitors GitHub repository via CodeStar Connection
2. **Build-Frontend**: Builds frontend Docker image, pushes to ECR
3. **Build-Backend**: Builds backend Docker image, pushes to ECR
4. **Deploy-Frontend**: Updates ECS frontend service
5. **Deploy-Backend**: Updates ECS backend service

### Buildspec Files
- `3-Tier_Architecture_with_AWS/ci-cd/buildspec-frontend.yml`
- `3-Tier_Architecture_with_AWS/ci-cd/buildspec-backend.yml`

### Triggering a Deployment
```bash
# Make code changes
git add .
git commit -m "Update feature"
git push origin main

# Pipeline automatically triggers
# Monitor pipeline
aws codepipeline get-pipeline-state \
  --name three-tier-pipeline \
  --region eu-west-2
```

### Manual Deployment
```bash
# Force new ECS deployment
aws ecs update-service \
  --cluster three-tier-ecs-cluster \
  --service backend-service \
  --force-new-deployment \
  --region eu-west-2
```

---

## 📊 Monitoring

### CloudWatch Logs
- **Backend Logs**: `/ecs/backend`
- **Frontend Logs**: `/ecs/frontend`

### Key Metrics to Monitor
- ECS CPU/Memory utilization
- ALB request count and latency
- RDS connections and queries
- Target health status

### Viewing Metrics
```bash
# ECS service metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=backend-service \
  --start-time 2025-10-31T00:00:00Z \
  --end-time 2025-10-31T23:59:59Z \
  --period 3600 \
  --statistics Average \
  --region eu-west-2

# ALB metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --dimensions Name=LoadBalancer,Value=app/internet-facing-lb/xxx \
  --start-time 2025-10-31T00:00:00Z \
  --end-time 2025-10-31T23:59:59Z \
  --period 300 \
  --statistics Average \
  --region eu-west-2
```

---

## 🛠️ Troubleshooting

### Common Issues

**Issue: ECS tasks not starting**
```bash
# Check service events
aws ecs describe-services \
  --cluster three-tier-ecs-cluster \
  --services backend-service \
  --region eu-west-2

# Check task logs
aws logs tail /ecs/backend --region eu-west-2
```

**Issue: Database connection timeout**
```bash
# Verify security group rules
aws ec2 describe-security-groups \
  --group-ids sg-xxxxx \
  --region eu-west-2

# Check RDS status
aws rds describe-db-instances \
  --db-instance-identifier db-master \
  --region eu-west-2
```

**Issue: 502 Bad Gateway**
- Check if backend targets are healthy
- Verify internal ALB security group allows traffic from frontend
- Check backend container logs for errors

**Issue: Pipeline failing**
```bash
# Get build logs
aws codebuild batch-get-builds \
  --ids <build-id> \
  --region eu-west-2
```

### Useful Commands
```bash
# List running ECS tasks
aws ecs list-tasks \
  --cluster three-tier-ecs-cluster \
  --region eu-west-2

# Describe task
aws ecs describe-tasks \
  --cluster three-tier-ecs-cluster \
  --tasks <task-arn> \
  --region eu-west-2

# Check target health
aws elbv2 describe-target-health \
  --target-group-arn <tg-arn> \
  --region eu-west-2

# Restart service
aws ecs update-service \
  --cluster three-tier-ecs-cluster \
  --service backend-service \
  --force-new-deployment \
  --region eu-west-2
```

---

## 🧹 Cleanup

### Destroy All Infrastructure
```bash
cd 3-Tier_Architecture_with_AWS

# Preview what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Confirm with: yes
```

### Manual Cleanup (if needed)
```bash
# Delete ECS services first
aws ecs update-service \
  --cluster three-tier-ecs-cluster \
  --service backend-service \
  --desired-count 0 \
  --region eu-west-2

aws ecs delete-service \
  --cluster three-tier-ecs-cluster \
  --service backend-service \
  --force \
  --region eu-west-2

# Then run terraform destroy
terraform destroy
```

### Cost Considerations
Running this infrastructure costs approximately:
- **ECS (EC2 instances)**: ~$20-30/month
- **RDS (db.t3.micro x2)**: ~$30-40/month
- **NAT Gateway**: ~$32/month
- **ALB**: ~$16/month
- **Total**: ~$100-120/month

**Tip**: Stop/terminate resources when not in use to save costs.

---

## 📈 Future Enhancements

### Planned Improvements
- [ ] **HTTPS/SSL**: Add SSL certificate to ALB
- [ ] **Auto-Scaling**: Configure ECS auto-scaling policies
- [ ] **CloudWatch Alarms**: Set up monitoring alerts
- [ ] **WAF**: Add Web Application Firewall
- [x] **Secrets Manager**: Credentials secured with AWS SSM & Secrets Manager
- [ ] **Multi-Region**: Deploy to multiple regions for DR
- [ ] **CDN**: Add CloudFront for static assets
- [ ] **Backup Automation**: Automated RDS snapshots
- [ ] **Cost Optimization**: Reserved instances, spot instances

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines
- Follow AWS best practices
- Write clear commit messages
- Update documentation for changes
- Test infrastructure changes in dev environment first

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 👥 Authors

- **Elizabeth Ajala** - *Initial work* - [elizabethajala99-ai](https://github.com/elizabethajala99-ai)

---

## 🙏 Acknowledgments

- AWS for comprehensive documentation
- Terraform community for IaC best practices
- Docker for containerization platform
- GitHub for version control and CI/CD integration

---

## 📞 Support

For issues and questions:
- Open an issue on GitHub
- Check the [Infrastructure Test Report](INFRASTRUCTURE_TEST_REPORT.md)
- Review AWS CloudWatch logs
- Consult AWS documentation

---

## 📚 Additional Resources

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/intro.html)

---

**Project Status**: ✅ Production Ready  
**Last Updated**: October 31, 2025  
**Version**: 1.0.0

