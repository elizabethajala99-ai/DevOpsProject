# 📋 Pre-Deployment Checklist

Complete this checklist before running `terraform apply` to ensure a smooth deployment.

## ✅ **AWS Account Prerequisites**

- [ ] AWS account created and verified
- [ ] IAM user created with necessary permissions (or using root account for testing)
- [ ] AWS CLI installed locally
- [ ] AWS CLI configured (`aws configure`)
- [ ] AWS credentials working (`aws sts get-caller-identity` succeeds)
- [ ] Selected region: `eu-west-2` (or update in terraform.tfvars)

## ✅ **Required Software**

- [ ] Terraform installed (version 1.0+)
  ```bash
  terraform --version
  ```
- [ ] Docker installed (for building images)
  ```bash
  docker --version
  ```
- [ ] Git installed
  ```bash
  git --version
  ```

## ✅ **SSH Key Pair**

- [ ] EC2 key pair created (`cba_keypair`)
  ```bash
  aws ec2 create-key-pair --key-name cba_keypair --region eu-west-2 --query 'KeyMaterial' --output text > ~/cba_keypair.pem
  chmod 400 ~/cba_keypair.pem
  ```
- [ ] Key pair file saved securely
- [ ] Key pair permissions set to 400

## ✅ **GitHub Configuration**

- [ ] GitHub repository exists (`elizabethajala99-ai/DevOpsProject`)
- [ ] Repository is public or you have CodeStar connection configured
- [ ] **CodeStar Connection created and AVAILABLE**
  - Created via AWS Console (Developer Tools → Connections)
  - GitHub app installed and authorized
  - Connection status: Available
  - Connection ARN copied
- [ ] CodeStar Connection ARN saved in `terraform.tfvars`

## ✅ **Terraform Configuration**

- [ ] `terraform.tfvars` file exists in `3-Tier_Architecture_with_AWS/`
- [ ] Database passwords changed from defaults
  - `db_password` - CHANGED
  - `db_slave_password` - CHANGED
- [ ] JWT secret changed from default
  - `jwt_secret` - CHANGED
- [ ] CodeStar Connection ARN added
  - `codestar_connection_arn` - ADDED (format: arn:aws:codestar-connections:...)
- [ ] GitHub repository details correct
  - `github_owner` - CORRECT
  - `github_repo` - CORRECT

## ✅ **Cost Awareness**

- [ ] Understood monthly cost (~$120-150)
- [ ] Understood hourly cost (~$2/hour)
- [ ] Plan to destroy resources after testing
- [ ] Set up billing alerts in AWS Console (optional)

## ✅ **File Structure Verification**

Ensure your project has this structure:

```
DevOpsProject/
├── 3-Tier_Architecture_with_AWS/
│   ├── alb.tf
│   ├── bastion.tf
│   ├── cicd.tf
│   ├── database.tf
│   ├── ecs.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── security_groups.tf
│   ├── ssm_secrets.tf
│   ├── terraform.tfvars   ← Must exist and be configured
│   ├── variables.tf
│   └── vpc.tf
├── frontend/
│   ├── Dockerfile
│   ├── app.js
│   ├── home.html
│   ├── index.html
│   ├── nginx.conf.template
│   └── entrypoint.sh
├── backend/
│   ├── Dockerfile
│   ├── server.js
│   └── package.json
├── buildspec_frontend.yml
├── buildspec_backend.yml
├── DEPLOYMENT_GUIDE.md
└── quick-deploy.sh
```

- [ ] All files present
- [ ] No missing Terraform files

## ✅ **Network & Connectivity**

- [ ] Internet connection stable (for downloading Terraform providers)
- [ ] No VPN blocking AWS services
- [ ] Firewall allows outbound HTTPS (443)

## ✅ **Final Checks**

- [ ] Read through `DEPLOYMENT_GUIDE.md`
- [ ] Understand deployment will take ~60-70 minutes
- [ ] Know how to check AWS Console for resources
- [ ] Have terminal ready for long-running commands
- [ ] Prepared to wait for RDS creation (~20 minutes)

---

## 🚀 **Ready to Deploy!**

If all items are checked, proceed with deployment:

### **Option 1: Automated Script**
```bash
cd /home/elizabeth/Group2_Project/Final_Integration/DevOpsProject
./quick-deploy.sh
```

### **Option 2: Manual Terraform**
```bash
cd /home/elizabeth/Group2_Project/Final_Integration/DevOpsProject/3-Tier_Architecture_with_AWS
terraform init
terraform plan
terraform apply
```

---

## ⚠️ **Common Issues to Watch For**

| Issue | Solution |
|-------|----------|
| "Error: InvalidKeyPair.NotFound" | Create key pair: `aws ec2 create-key-pair --key-name cba_keypair` |
| "Error: UnauthorizedOperation" | Check IAM permissions |
| "Error: ResourceNotFoundException" | Ensure region is correct in terraform.tfvars |
| Terraform hangs on RDS | Normal - RDS takes 15-20 minutes to create |
| "Error: CodeStar connection not available" | Go to AWS Console → Connections → Complete GitHub authorization |

---

## 📞 **Need Help?**

1. Check `DEPLOYMENT_GUIDE.md` troubleshooting section
2. Review Terraform error messages carefully
3. Check AWS CloudWatch Logs for application issues
4. Verify security groups allow necessary traffic

---

**Good luck with your deployment!** 🎉
