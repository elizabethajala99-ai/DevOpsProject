# AWS 3-Tier Architecture Diagram

## Standard AWS Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                             │
│                                      AWS Cloud                                              │
│                                   Region: eu-west-2                                         │
│                                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                                                                                       │ │
│  │                          VPC (10.0.0.0/16)                                           │ │
│  │                                                                                       │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────┐│ │
│  │  │                        Availability Zone: eu-west-2a                            ││ │
│  │  │                                                                                 ││ │
│  │  │  ┌──────────────────────┐         ┌──────────────────────┐                     ││ │
│  │  │  │  Public Subnet       │         │  Private Subnet      │                     ││ │
│  │  │  │  10.0.1.0/24         │         │  10.0.3.0/24         │                     ││ │
│  │  │  │                      │         │                      │                     ││ │
│  │  │  │  ┌────────────────┐  │         │  ┌────────────────┐ │                     ││ │
│  │  │  │  │   Bastion      │  │         │  │  ECS Container │ │                     ││ │
│  │  │  │  │     Host       │  │         │  │   Instance 1   │ │                     ││ │
│  │  │  │  │  EC2 Instance  │  │         │  │                │ │                     ││ │
│  │  │  │  │  (Amazon Linux)│  │         │  │  ┌──────────┐  │ │                     ││ │
│  │  │  │  └────────────────┘  │         │  │  │Frontend  │  │ │                     ││ │
│  │  │  │         │             │         │  │  │Container │  │ │                     ││ │
│  │  │  │         │             │         │  │  │  (nginx) │  │ │                     ││ │
│  │  │  │  ┌──────▼─────────┐  │         │  │  └──────────┘  │ │                     ││ │
│  │  │  │  │  Internet      │  │         │  │  ┌──────────┐  │ │                     ││ │
│  │  │  │  │  Facing ALB    │  │         │  │  │Backend   │  │ │                     ││ │
│  │  │  │  │  (Port 80)     │  │         │  │  │Container │  │ │                     ││ │
│  │  │  │  └────────────────┘  │         │  │  │(Node.js) │  │ │                     ││ │
│  │  │  │                      │         │  │  └──────────┘  │ │                     ││ │
│  │  │  │                      │         │  └────────────────┘ │                     ││ │
│  │  │  │                      │         │          │           │                     ││ │
│  │  │  │                      │         │  ┌───────▼────────┐ │                     ││ │
│  │  │  │  ┌────────────────┐  │         │  │  Internal ALB  │ │                     ││ │
│  │  │  │  │  NAT Gateway   │  │         │  │  (Port 5000)   │ │                     ││ │
│  │  │  │  │                │  │         │  └────────────────┘ │                     ││ │
│  │  │  │  └────────────────┘  │         │          │           │                     ││ │
│  │  │  │                      │         │          │           │                     ││ │
│  │  │  │                      │         │  ┌───────▼────────┐ │                     ││ │
│  │  │  │                      │         │  │  RDS MySQL     │ │                     ││ │
│  │  │  │                      │         │  │  Master        │ │                     ││ │
│  │  │  │                      │         │  │  (db.t3.micro) │ │                     ││ │
│  │  │  │                      │         │  └────────────────┘ │                     ││ │
│  │  │  └──────────────────────┘         └──────────────────────┘                     ││ │
│  │  └─────────────────────────────────────────────────────────────────────────────────┘│ │
│  │                                                                                       │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────┐│ │
│  │  │                        Availability Zone: eu-west-2b                            ││ │
│  │  │                                                                                 ││ │
│  │  │  ┌──────────────────────┐         ┌──────────────────────┐                     ││ │
│  │  │  │  Public Subnet       │         │  Private Subnet      │                     ││ │
│  │  │  │  10.0.2.0/24         │         │  10.0.4.0/24         │                     ││ │
│  │  │  │                      │         │                      │                     ││ │
│  │  │  │  ┌────────────────┐  │         │  ┌────────────────┐ │                     ││ │
│  │  │  │  │  Internet      │  │         │  │  ECS Container │ │                     ││ │
│  │  │  │  │  Facing ALB    │  │         │  │   Instance 2   │ │                     ││ │
│  │  │  │  │  (Port 80)     │  │         │  │                │ │                     ││ │
│  │  │  │  └────────────────┘  │         │  │  ┌──────────┐  │ │                     ││ │
│  │  │  │                      │         │  │  │Frontend  │  │ │                     ││ │
│  │  │  │                      │         │  │  │Container │  │ │                     ││ │
│  │  │  │                      │         │  │  │  (nginx) │  │ │                     ││ │
│  │  │  │                      │         │  │  └──────────┘  │ │                     ││ │
│  │  │  │                      │         │  │  ┌──────────┐  │ │                     ││ │
│  │  │  │                      │         │  │  │Backend   │  │ │                     ││ │
│  │  │  │                      │         │  │  │Container │  │ │                     ││ │
│  │  │  │                      │         │  │  │(Node.js) │  │ │                     ││ │
│  │  │  │                      │         │  │  └──────────┘  │ │                     ││ │
│  │  │  │                      │         │  └────────────────┘ │                     ││ │
│  │  │  │                      │         │          │           │                     ││ │
│  │  │  │                      │         │  ┌───────▼────────┐ │                     ││ │
│  │  │  │                      │         │  │  Internal ALB  │ │                     ││ │
│  │  │  │                      │         │  │  (Port 5000)   │ │                     ││ │
│  │  │  │                      │         │  └────────────────┘ │                     ││ │
│  │  │  │                      │         │          │           │                     ││ │
│  │  │  │                      │         │  ┌───────▼────────┐ │                     ││ │
│  │  │  │                      │         │  │  RDS MySQL     │ │                     ││ │
│  │  │  │                      │         │  │  Slave (Read   │ │                     ││ │
│  │  │  │                      │         │  │  Replica)      │ │                     ││ │
│  │  │  │                      │         │  │  (db.t3.micro) │ │                     ││ │
│  │  │  │                      │         │  └────────────────┘ │                     ││ │
│  │  │  └──────────────────────┘         └──────────────────────┘                     ││ │
│  │  └─────────────────────────────────────────────────────────────────────────────────┘│ │
│  │                                                                                       │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────┐│ │
│  │  │                           Network Components                                    ││ │
│  │  │                                                                                 ││ │
│  │  │  Internet Gateway ←→ Public Subnets                                            ││ │
│  │  │  NAT Gateway → Private Subnets → Internet (Outbound Only)                      ││ │
│  │  │  VPC Flow Logs → CloudWatch Logs                                               ││ │
│  │  └─────────────────────────────────────────────────────────────────────────────────┘│ │
│  │                                                                                       │ │
│  └───────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              Developer Tools & CI/CD                                  │ │
│  │                                                                                       │ │
│  │  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐   │ │
│  │  │   GitHub     │────▶│  CodeStar    │────▶│ CodePipeline │────▶│  CodeBuild   │   │ │
│  │  │ (Source Code)│     │  Connection  │     │              │     │              │   │ │
│  │  └──────────────┘     └──────────────┘     └──────┬───────┘     └──────┬───────┘   │ │
│  │                                                     │                    │           │ │
│  │                                              ┌──────▼────────┐           │           │ │
│  │                                              │      S3       │           │           │ │
│  │                                              │  (Artifacts)  │           │           │ │
│  │                                              └───────────────┘           │           │ │
│  │                                                                   ┌──────▼───────┐   │ │
│  │                                                                   │     ECR      │   │ │
│  │                                                                   │  (Container  │   │ │
│  │                                                                   │   Registry)  │   │ │
│  │                                                                   └──────┬───────┘   │ │
│  │                                                                          │           │ │
│  │                                                                   ┌──────▼───────┐   │ │
│  │                                                                   │ ECS Cluster  │   │ │
│  │                                                                   │ (Container   │   │ │
│  │                                                                   │Orchestration)│   │ │
│  │                                                                   └──────────────┘   │ │
│  │                                                                                       │ │
│  │  ┌──────────────────────────────────────────────────────────────────────────────┐   │ │
│  │  │                          S3 Buckets                                          │   │ │
│  │  │                                                                              │   │ │
│  │  │  • Terraform State (terraform-state-bucket)                                 │   │ │
│  │  │  • CodePipeline Artifacts (codepipeline-artifacts-bucket)                   │   │ │
│  │  │  • Build Logs & Cache (codebuild-cache-bucket)                              │   │ │
│  │  └──────────────────────────────────────────────────────────────────────────────┘   │ │
│  └───────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                           Monitoring & Logging                                        │ │
│  │                                                                                       │ │
│  │  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐                         │ │
│  │  │  CloudWatch  │     │  CloudWatch  │     │  CloudWatch  │                         │ │
│  │  │    Metrics   │     │     Logs     │     │    Alarms    │                         │ │
│  │  │              │     │              │     │              │                         │ │
│  │  │  • ECS CPU   │     │ • /ecs/backend│    │ • CPU > 80% │                         │ │
│  │  │  • Memory    │     │ • /ecs/frontend│   │ • Memory    │                         │ │
│  │  │  • ALB       │     │ • Build Logs │     │ • Health    │                         │ │
│  │  └──────────────┘     └──────────────┘     └──────────────┘                         │ │
│  └───────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         │
                                    ┌────▼────┐
                                    │  Users  │
                                    │ (HTTPS) │
                                    └─────────┘
```

---

## Detailed Component Breakdown

### AWS Services Used

| Service | Purpose | Configuration |
|---------|---------|---------------|
| **VPC** | Network isolation | CIDR: 10.0.0.0/16 |
| **Internet Gateway** | Internet access for public subnets | Attached to VPC |
| **NAT Gateway** | Outbound internet for private subnets | In public subnet eu-west-2a |
| **Application Load Balancer (Internet-facing)** | Web tier load balancing | Port 80, Cross-AZ |
| **Application Load Balancer (Internal)** | App tier load balancing | Port 5000, Private |
| **ECS Cluster** | Container orchestration | EC2 launch type |
| **ECS Services** | Frontend & Backend services | 2 tasks each |
| **EC2 Auto Scaling Group** | ECS container instances | 2 instances, t3.micro |
| **RDS MySQL** | Relational database | Master-Slave, db.t3.micro |
| **ECR** | Docker image registry | Private repositories |
| **CodePipeline** | CI/CD orchestration | 5 stages |
| **CodeBuild** | Build automation | Frontend & Backend builds |
| **CodeStar Connections** | GitHub integration | OAuth connection |
| **CloudWatch Logs** | Centralized logging | Log groups per service |
| **CloudWatch Metrics** | Performance monitoring | CPU, Memory, Network |
| **S3** | Object storage | Terraform state, artifacts, logs |
| **SSM Parameter Store** | Configuration management | Non-sensitive app configuration |
| **Secrets Manager** | Secrets management | Database passwords, JWT secrets |
| **Bastion Host** | Secure SSH access | EC2 in public subnet |

---

## Traffic Flow Diagrams

### Incoming User Request Flow

```
┌──────────┐
│   User   │
└────┬─────┘
     │ HTTP Request
     ▼
┌──────────────────────┐
│  Internet Gateway    │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Internet-facing ALB  │ ◄─── Route 53 (optional)
│   (Port 80)          │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Frontend Container   │
│  (nginx on ECS)      │
│  - Serves HTML/CSS   │
│  - Proxies /api/*    │
└──────────┬───────────┘
           │ API Request
           ▼
┌──────────────────────┐
│   Internal ALB       │
│   (Port 5000)        │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Backend Container    │
│ (Node.js on ECS)     │
│  - REST API          │
│  - Business Logic    │
└──────────┬───────────┘
           │ SQL Query
           ▼
┌──────────────────────┐
│   RDS MySQL          │
│   Master (Write)     │
│   Slave (Read)       │
└──────────────────────┘
```

### CI/CD Pipeline Flow

```
┌──────────┐
│ Developer│
│  (Push)  │
└────┬─────┘
     │ git push
     ▼
┌──────────────────────┐
│      GitHub          │
│   (Source Code)      │
└──────────┬───────────┘
           │ Webhook
           ▼
┌──────────────────────┐
│  CodeStar Connection │
│   (OAuth Auth)       │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│   CodePipeline       │
│   (Orchestration)    │
└──────────┬───────────┘
           │ Store Artifacts
           ▼
┌──────────────────────┐
│      S3 Bucket       │
│   (Artifacts Store)  │
└──────────┬───────────┘
           │
     ┌─────┴─────┐
     ▼           ▼
┌─────────┐  ┌─────────┐
│Frontend │  │ Backend │
│ Build   │  │  Build  │
│         │  │         │
│CodeBuild│  │CodeBuild│
└────┬────┘  └────┬────┘
     │            │
     │ Push Image │
     ▼            ▼
┌──────────────────────┐
│        ECR           │
│  (Image Registry)    │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│    ECS Cluster       │
│  (Pull & Deploy)     │
│                      │
│ ┌──────┐  ┌──────┐  │
│ │Front │  │ Back │  │
│ │ end  │  │  end │  │
│ └──────┘  └──────┘  │
└──────────────────────┘
```

### Database Replication Flow

```
┌──────────────────────────────────┐
│     Availability Zone: 2a        │
│                                  │
│  ┌────────────────────────────┐  │
│  │   RDS MySQL Master         │  │
│  │   (Read/Write Operations)  │  │
│  │                            │  │
│  │   • User Writes            │  │
│  │   • INSERT/UPDATE/DELETE   │──┼──┐
│  └────────────────────────────┘  │  │
└──────────────────────────────────┘  │
                                      │ Asynchronous
                                      │ Replication
                                      │
┌──────────────────────────────────┐  │
│     Availability Zone: 2b        │  │
│                                  │  │
│  ┌────────────────────────────┐  │  │
│  │   RDS MySQL Slave          │◄─┼──┘
│  │   (Read-Only Replica)      │  │
│  │                            │  │
│  │   • Read Operations        │  │
│  │   • SELECT Queries         │  │
│  └────────────────────────────┘  │
└──────────────────────────────────┘
```

---

## Security Groups & Network ACLs

### Security Group Rules Matrix

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Security Group Rules                           │
├─────────────────────┬───────────────────┬────────────────────────────┤
│   Component         │   Inbound         │   Outbound                 │
├─────────────────────┼───────────────────┼────────────────────────────┤
│ Internet ALB        │ 80: 0.0.0.0/0     │ All: 0.0.0.0/0            │
├─────────────────────┼───────────────────┼────────────────────────────┤
│ Internal ALB        │ 5000: ECS SG      │ All: 0.0.0.0/0            │
│                     │ 5000: Web ALB SG  │                            │
│                     │ 8080: Bastion SG  │                            │
├─────────────────────┼───────────────────┼────────────────────────────┤
│ ECS Instances       │ 80: Web ALB SG    │ All: 0.0.0.0/0            │
│                     │ 5000: Int ALB SG  │                            │
├─────────────────────┼───────────────────┼────────────────────────────┤
│ RDS                 │ 3306: ECS SG      │ None                       │
├─────────────────────┼───────────────────┼────────────────────────────┤
│ Bastion Host        │ 22: Admin IP      │ All: 0.0.0.0/0            │
└─────────────────────┴───────────────────┴────────────────────────────┘
```

---

## High Availability Design

### Multi-AZ Deployment Strategy

```
                     ┌─────────────────┐
                     │  Route 53 DNS   │ (Optional)
                     └────────┬────────┘
                              │
              ┌───────────────┴───────────────┐
              │                               │
    ┌─────────▼─────────┐         ┌──────────▼────────┐
    │   AZ: eu-west-2a  │         │  AZ: eu-west-2b   │
    │                   │         │                   │
    │  ┌─────────────┐  │         │  ┌─────────────┐  │
    │  │  Frontend   │  │         │  │  Frontend   │  │
    │  │  Container  │  │         │  │  Container  │  │
    │  └─────────────┘  │         │  └─────────────┘  │
    │  ┌─────────────┐  │         │  ┌─────────────┐  │
    │  │  Backend    │  │         │  │  Backend    │  │
    │  │  Container  │  │         │  │  Container  │  │
    │  └─────────────┘  │         │  └─────────────┘  │
    │  ┌─────────────┐  │         │  ┌─────────────┐  │
    │  │  RDS Master │  │         │  │  RDS Slave  │  │
    │  │  (Primary)  │──┼─────────┼─▶│  (Standby)  │  │
    │  └─────────────┘  │         │  └─────────────┘  │
    └───────────────────┘         └───────────────────┘

    Benefits:
    ✓ Fault Tolerance across AZs
    ✓ Load Distribution
    ✓ Database Replication
    ✓ Zero Downtime Deployments
```

---

## Scaling Architecture

### ECS Auto Scaling Configuration

```
┌────────────────────────────────────────────────────────────┐
│                    CloudWatch Metrics                      │
│                                                            │
│  CPU Utilization > 75%  ──▶  Scale Out (+1 Task)         │
│  CPU Utilization < 25%  ──▶  Scale In (-1 Task)          │
│  Memory > 80%           ──▶  Scale Out (+1 Task)         │
└────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────┐
│              ECS Service Auto Scaling                      │
│                                                            │
│  Min Tasks: 2                                             │
│  Max Tasks: 10                                            │
│  Desired: 2                                               │
└────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────┐
│           EC2 Auto Scaling Group                           │
│                                                            │
│  Min Instances: 2                                         │
│  Max Instances: 6                                         │
│  Desired: 2                                               │
└────────────────────────────────────────────────────────────┘
```

---

## Infrastructure as Code Structure

### Terraform Module Organization

```
3-Tier_Architecture_with_AWS/
│
├── providers.tf         ─── AWS Provider Configuration
├── variables.tf         ─── Input Variables
├── terraform.tfvars     ─── Variable Values (gitignored)
│
├── networking.tf        ─── VPC, Subnets, IGW, NAT, Routes
│                            • VPC (10.0.0.0/16)
│                            • 2 Public Subnets
│                            • 2 Private Subnets
│                            • Internet Gateway
│                            • NAT Gateway
│                            • Route Tables
│
├── security_groups.tf   ─── Security Group Rules
│                            • ALB Security Groups
│                            • ECS Security Groups
│                            • RDS Security Groups
│                            • Bastion Security Groups
│
├── webtier.tf          ─── Internet-facing ALB
│                            • Application Load Balancer
│                            • Target Groups
│                            • Listeners (Port 80)
│
├── apptier.tf          ─── Internal ALB
│                            • Internal Load Balancer
│                            • Target Groups
│                            • Listeners (Port 5000)
│
├── ecs.tf              ─── ECS Configuration
│                            • ECS Cluster
│                            • Task Definitions
│                            • ECS Services
│                            • Auto Scaling Group
│                            • Launch Configuration
│
├── datatier.tf         ─── RDS Configuration
│                            • DB Subnet Group
│                            • RDS Master Instance
│                            • RDS Slave Instance
│                            • Parameter Groups
│
├── bastion.tf          ─── Bastion Host
│                            • EC2 Instance
│                            • Key Pair
│                            • Elastic IP
│
├── cicd.tf             ─── CI/CD Pipeline
│                            • CodePipeline
│                            • CodeBuild Projects
│                            • ECR Repositories
│                            • S3 Buckets (Artifacts)
│                            • IAM Roles
│
├── s3.tf               ─── S3 Storage
│                            • Terraform State Bucket
│                            • CodePipeline Artifacts
│                            • Build Cache
│
└── outputs.tf          ─── Output Values
                             • ALB DNS Names
                             • Bastion IP
                             • RDS Endpoints
```

---

## Cost Optimization Strategies

```
┌─────────────────────────────────────────────────────────────┐
│              Monthly Cost Breakdown (~$120)                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ECS (2x t3.micro)           $20-30                        │
│  ├─ Reserved Instances       Save 30-40%                   │
│  └─ Spot Instances           Save 70-90% (non-prod)        │
│                                                             │
│  RDS (2x db.t3.micro)        $30-40                        │
│  ├─ Reserved Instances       Save 30-60%                   │
│  └─ Aurora Serverless        Pay per use                   │
│                                                             │
│  NAT Gateway                 $32                            │
│  └─ NAT Instance             Save 50% (lower performance)  │
│                                                             │
│  ALB (2x)                    $16                            │
│  └─ Shared ALB               Consolidate if possible       │
│                                                             │
│  Data Transfer               $5-10                          │
│  └─ CloudFront CDN           Reduce transfer costs         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Disaster Recovery & Backup

```
┌─────────────────────────────────────────────────────────────┐
│                  Backup Strategy                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  RDS Automated Backups                                     │
│  ├─ Daily Snapshots                                        │
│  ├─ 7-day Retention                                        │
│  └─ Point-in-Time Recovery                                 │
│                                                             │
│  ECS Task Definitions                                      │
│  ├─ Versioned                                              │
│  └─ Rollback Capability                                    │
│                                                             │
│  ECR Images                                                 │
│  ├─ Tagged by Build Number                                 │
│  └─ Image Lifecycle Policies                               │
│                                                             │
│  Infrastructure as Code                                     │
│  ├─ Git Version Control                                    │
│  └─ Terraform State (S3 Backend)                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Recovery Time Objective (RTO): < 1 hour
Recovery Point Objective (RPO): < 5 minutes
```

---

## Monitoring Dashboard

```
┌─────────────────────────────────────────────────────────────┐
│              CloudWatch Dashboard Layout                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   ALB        │  │  ECS CPU     │  │  RDS CPU     │    │
│  │  Requests    │  │  Usage       │  │  Usage       │    │
│  │  ▲▂▃▅▇█      │  │  ▃▄▅▆▇█      │  │  ▁▂▃▄▅▆      │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   Target     │  │  ECS Memory  │  │  RDS         │    │
│  │   Health     │  │  Usage       │  │  Connections │    │
│  │  ●●○○        │  │  ▃▄▅▆▇█      │  │  ▂▃▄▅▆       │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Recent Alarms                           │  │
│  │  ✓ All Systems Operational                           │  │
│  │  ✓ No Active Alarms                                  │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## References

- **AWS Well-Architected Framework**: https://aws.amazon.com/architecture/well-architected/
- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **ECS Best Practices**: https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/
- **RDS Best Practices**: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html

---

**Document Version**: 1.0  
**Last Updated**: October 31, 2025  
**Maintained By**: DevOps Team
