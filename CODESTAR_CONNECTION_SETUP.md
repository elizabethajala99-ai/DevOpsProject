# 🔗 CodeStar Connection Setup Guide

## What is CodeStar Connection?

AWS CodeStar Connections provides a secure way to connect AWS CodePipeline to GitHub without using personal access tokens. It uses GitHub Apps for authentication, which is more secure and doesn't require token management.

---

## 📋 **Step-by-Step Setup**

### **Method 1: AWS Console (Recommended)**

#### 1. Navigate to Connections

```
AWS Console → Developer Tools → Settings → Connections
OR
AWS Console → CodePipeline → Settings → Connections
```

#### 2. Create New Connection

1. Click **"Create connection"**
2. Select provider: **GitHub**
3. Connection name: `github-connection` (or any name you prefer)
4. Click **"Connect to GitHub"**

#### 3. Install GitHub App

You'll be redirected to GitHub:

1. Click **"Install a new app"** or **"Connect to GitHub"**
2. Select account: **elizabethajala99-ai** (your GitHub account)
3. Choose repository access:
   - **Recommended:** "Only select repositories" → Select **DevOpsProject**
   - **Alternative:** "All repositories" (if you plan to add more projects)
4. Click **"Install"**

#### 4. Complete Authorization

1. Back in AWS Console, you'll see the connection
2. Status should change from **"Pending"** to **"Available"**
3. **Copy the Connection ARN**
   - Format: `arn:aws:codestar-connections:eu-west-2:125905899300:connection/abc12345-...`

#### 5. Update Terraform Configuration

```hcl
# In terraform.tfvars
codestar_connection_arn = "arn:aws:codestar-connections:eu-west-2:125905899300:connection/abc12345-6789-def0-1234-56789abcdef0"
github_owner            = "elizabethajala99-ai"
github_repo             = "DevOpsProject"
```

---

### **Method 2: AWS CLI (Advanced)**

#### 1. Create Connection

```bash
aws codestar-connections create-connection \
  --provider-type GitHub \
  --connection-name github-connection \
  --region eu-west-2
```

**Output:**
```json
{
    "ConnectionArn": "arn:aws:codestar-connections:eu-west-2:123456789012:connection/abc...",
    "Tags": []
}
```

**⚠️ Important:** The connection is created but status is **"PENDING"**

#### 2. Complete Handshake (REQUIRED)

You **MUST** complete the GitHub authorization via AWS Console:

1. Go to: AWS Console → Developer Tools → Connections
2. Find your connection (status: Pending)
3. Click **"Update pending connection"**
4. Click **"Install a new app"** on GitHub
5. Authorize and install the GitHub App
6. Connection status changes to **"Available"**

#### 3. Verify Connection

```bash
# Get connection details
aws codestar-connections get-connection \
  --connection-arn "arn:aws:codestar-connections:eu-west-2:123456789012:connection/abc..." \
  --region eu-west-2

# Check if status is "AVAILABLE"
```

---

## 🔍 **Verify Your Connection**

### Check Connection Status

```bash
# List all connections
aws codestar-connections list-connections --region eu-west-2

# Get specific connection details
aws codestar-connections get-connection \
  --connection-arn <your-connection-arn> \
  --region eu-west-2
```

**Expected Output:**
```json
{
    "Connection": {
        "ConnectionName": "github-connection",
        "ConnectionArn": "arn:aws:codestar-connections:eu-west-2:...",
        "ProviderType": "GitHub",
        "OwnerAccountId": "125905899300",
        "ConnectionStatus": "AVAILABLE"  ← Must be AVAILABLE
    }
}
```

---

## 📝 **Update terraform.tfvars**

After creating the CodeStar connection, update your `terraform.tfvars`:

```hcl
# AWS Configuration
aws_region    = "eu-west-2"
aws_account_id = "125905899300"  # Replace with your account ID

# GitHub Configuration (CodeStar Connection)
codestar_connection_arn = "arn:aws:codestar-connections:eu-west-2:125905899300:connection/YOUR-CONNECTION-ID"
github_owner            = "elizabethajala99-ai"
github_repo             = "DevOpsProject"

# Database passwords (CHANGE THESE!)
db_password       = "YourSecurePassword123!"
db_slave_password = "YourSecureSlavePass123!"
db_username       = "admin"
db_name           = "taskmanagement"

# JWT Secret (CHANGE THIS!)
jwt_secret = "your-super-secret-jwt-key-change-this-123456789"

# Other settings
environment       = "production"
enable_monitoring = true
```

---

## ⚠️ **Troubleshooting**

### Issue: Connection Status is "PENDING"

**Cause:** GitHub App not installed or authorized

**Solution:**
1. Go to AWS Console → Connections
2. Click on the pending connection
3. Click "Update pending connection"
4. Complete GitHub authorization

---

### Issue: "Connection not found" during Terraform apply

**Cause:** Connection ARN is incorrect or connection doesn't exist

**Solution:**
```bash
# List all connections to find the correct ARN
aws codestar-connections list-connections --region eu-west-2

# Copy the correct ConnectionArn
```

---

### Issue: CodePipeline fails with "Connection error"

**Cause:** Connection status is not "AVAILABLE"

**Solution:**
```bash
# Check connection status
aws codestar-connections get-connection \
  --connection-arn <your-arn> \
  --region eu-west-2

# If status is PENDING, complete the handshake in AWS Console
```

---

### Issue: GitHub webhook not triggering pipeline

**Cause:** GitHub App not properly installed or repository not selected

**Solution:**
1. Go to GitHub → Settings → Integrations → Applications
2. Find "AWS Connector for GitHub"
3. Click "Configure"
4. Ensure "DevOpsProject" repository is selected
5. Save changes

---

## 🔐 **Security Best Practices**

### ✅ **Advantages of CodeStar Connection over PAT:**

1. **No token management** - No need to rotate tokens every 90 days
2. **Fine-grained permissions** - GitHub App has limited, specific permissions
3. **Audit trail** - All actions logged in GitHub and AWS CloudTrail
4. **Repository-specific** - Can limit access to specific repos
5. **Revocable** - Can revoke access from either GitHub or AWS side

### ✅ **Minimum Permissions:**

The GitHub App only needs:
- Read access to repository contents
- Read/Write access to webhooks
- Read access to metadata

---

## 📚 **Additional Resources**

- [AWS CodeStar Connections Documentation](https://docs.aws.amazon.com/dtconsole/latest/userguide/welcome-connections.html)
- [GitHub Apps Documentation](https://docs.github.com/en/apps)
- [CodePipeline GitHub Integration](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-github.html)

---

## ✅ **Quick Checklist**

Before running Terraform:

- [ ] CodeStar connection created in AWS Console
- [ ] GitHub App installed and authorized
- [ ] Connection status: **AVAILABLE**
- [ ] Connection ARN copied to terraform.tfvars
- [ ] Repository name matches exactly: `DevOpsProject`
- [ ] GitHub owner matches: `elizabethajala99-ai`

---

**Ready to proceed with Terraform deployment!** 🚀
