# CI/CD Pipelines Documentation

This directory contains GitHub Actions workflows for automating the deployment of the Cloud Resume Challenge infrastructure and frontend application to AWS.

## 📋 Overview

The project uses two main CI/CD pipelines:

1. **Infrastructure Pipeline** (`infra-aws.yml`) - Deploys AWS infrastructure using Terraform
2. **Frontend Pipeline** (`frontend-aws.yml`) - Builds and deploys the frontend application to S3/CloudFront

## 🔐 Authentication

Both pipelines use **OpenID Connect (OIDC)** for secure, keyless authentication with AWS. This eliminates the need to store long-lived AWS credentials as GitHub secrets.

### Required Secrets

Configure these secrets in your GitHub repository settings:

| Secret Name              | Description                     | Example Value                                      |
| ------------------------ | ------------------------------- | -------------------------------------------------- |
| `AWS_REGION`             | AWS region for deployment       | `us-east-1`                                        |
| `AWS_TERRAFORM_ROLE_ARN` | ARN of IAM role with OIDC trust | `arn:aws:iam::123456789012:role/GitHubActionsRole` |

### Required Permissions

```yaml
permissions:
  id-token: write # Required for requesting OIDC JWT token
  contents: read # Required for checking out repository
```

---

## 🏗️ Infrastructure Pipeline

**File:** [`infra-aws.yml`](infra-aws.yml)

### Purpose

Provisions and manages AWS infrastructure using Terraform, including:

- S3 buckets for frontend hosting and Lambda code
- CloudFront distribution
- Lambda function for view counter
- API Gateway
- DynamoDB table
- IAM roles and policies
- ACM certificates
- CloudWatch logs

### Triggers

```yaml
# Automatic triggers
- Push to any branch when files change in:
    - aws/**
    - .github/workflows/infra-aws.yml

# Manual trigger
- workflow_dispatch (via GitHub UI)
```

### Workflow Steps

#### Job: `terraform`

1. **Checkout Repository** - Clones the repository code
2. **Configure AWS Credentials** - Authenticates using OIDC and assumes the Terraform role
3. **Setup Python 3.12** - Installs Python for Lambda packaging
4. **Run Lambda Package Script** - Packages Lambda function code and dependencies:
   - Makes `package_code.sh` executable
   - Creates `lambda_package.zip` (application code)
   - Creates `dependencies.zip` (Python dependencies)
   - Moves zip files to terraform directory
5. **Setup Terraform 1.14.0** - Installs specified Terraform version
6. **Terraform Init** - Initializes Terraform working directory and downloads providers
7. **Terraform Plan** - Creates execution plan showing infrastructure changes
8. **Terraform Apply** - Applies changes to AWS infrastructure (auto-approved)

### Key Files Modified

- `aws/view_counter/lambda_package.zip` (generated)
- `aws/view_counter/dependencies.zip` (generated)
- `aws/terraform/.terraform/` (state and providers)

### Execution Time

Typical runtime: **3-5 minutes**

---

## 🎨 Frontend Pipeline

**File:** [`frontend-aws.yml`](frontend-aws.yml)

### Purpose

Builds the Vite.js frontend application and deploys it to S3 with CloudFront invalidation for instant updates.

### Triggers

```yaml
# Automatic triggers
- Push to any branch when files change in:
    - frontend/**
    - .github/workflows/frontend-aws.yml

# Triggered by infrastructure pipeline completion
- After 'Terraform IaC Deployment to AWS' workflow completes

# Manual trigger
- workflow_dispatch (via GitHub UI)
```

### Workflow Architecture

The pipeline uses a **3-job architecture** with dependencies:

```
terraform (Get Outputs)
    ↓
build (Parallel) ──→ deploy (Requires both)
    ↓
```

### Workflow Jobs

#### Job 1: `terraform` - Get Terraform Outputs

**Purpose:** Retrieves infrastructure details needed for deployment

**Steps:**

1. **Checkout Repository** - Clones the repository
2. **Configure AWS Credentials** - Authenticates via OIDC
3. **Setup Terraform 1.14.0** - Installs Terraform
4. **Terraform Init** - Initializes Terraform state
5. **Terraform Outputs** - Extracts and exposes:
   - `aws_s3_bucket_name` - Target S3 bucket for frontend files
   - `cloudfront_distribution_id` - CloudFront distribution to invalidate

**Outputs:**

```yaml
aws_s3_bucket_name: 'resume-frontend-bucket-abc123'
cloudfront_distribution_id: 'E1234ABCD5678'
```

#### Job 2: `build` - Build Vite.js Frontend

**Purpose:** Compiles and optimizes the frontend application

**Steps:**

1. **Checkout Repository** - Clones the repository
2. **Set up Node.js** - Installs latest LTS version of Node.js
3. **Install Dependencies and Build** - Runs:
   ```bash
   npm ci                # Clean install (uses package-lock.json)
   npm run build-aws     # Production build for AWS
   ```
4. **Archive Production Artifacts** - Uploads `frontend/dist` folder:
   - Artifact name: `frontend-dist`
   - Retention: 1 day
   - Contains optimized HTML, CSS, JS, and assets

**Build Output:** Optimized production bundle in `frontend/dist/`

#### Job 3: `deploy` - Deploy Frontend to S3

**Purpose:** Deploys built files to S3 and invalidates CloudFront cache

**Dependencies:** Requires both `terraform` and `build` jobs to complete

**Steps:**

1. **Download Production Artifacts** - Retrieves `frontend-dist` artifact
2. **Configure AWS Credentials** - Authenticates via OIDC
3. **Sync Files to S3** - Uploads files to S3:
   ```bash
   aws s3 sync . s3://<bucket-name> --delete
   ```
   - Uploads only changed files
   - `--delete` removes files not in source
4. **Invalidate CloudFront Cache** - Forces immediate update:
   ```bash
   aws cloudfront create-invalidation --distribution-id <id> --paths "/*"
   ```
   - Clears all cached content
   - Makes new version immediately visible

### Execution Time

- **terraform job:** ~1 minute
- **build job:** ~2-3 minutes
- **deploy job:** ~1-2 minutes
- **Total:** ~4-6 minutes

---

## 🔄 Pipeline Dependencies

The frontend pipeline can be triggered by the infrastructure pipeline completion, creating a deployment chain:

```
Code Push → Infra Pipeline → Frontend Pipeline
                ↓                    ↓
            AWS Resources        Updated Website
```

This ensures that when infrastructure changes (like new S3 bucket names), the frontend is automatically redeployed with the correct configuration.

---

## 🚀 Manual Deployment

Both pipelines support manual triggering via `workflow_dispatch`:

1. Go to **Actions** tab in GitHub
2. Select the workflow (Infrastructure or Frontend)
3. Click **Run workflow**
4. Select branch and click **Run workflow**

---

## 🐛 Troubleshooting

### Common Issues

| Issue                          | Pipeline       | Solution                                                   |
| ------------------------------ | -------------- | ---------------------------------------------------------- |
| OIDC authentication failed     | Both           | Verify IAM role trust policy includes GitHub OIDC provider |
| Terraform state locked         | Infrastructure | Wait for previous run to complete or manually unlock       |
| S3 sync permission denied      | Frontend       | Ensure IAM role has `s3:PutObject` and `s3:DeleteObject`   |
| CloudFront invalidation failed | Frontend       | Verify role has `cloudfront:CreateInvalidation`            |
| Lambda packaging failed        | Infrastructure | Check Python version and dependencies in requirements.txt  |
| Node build failed              | Frontend       | Check package.json scripts and dependencies                |

### Viewing Logs

1. Navigate to **Actions** tab
2. Click on the workflow run
3. Click on individual job to see detailed logs
4. Expand step to see command output

### Testing Changes

For testing workflow changes:

1. Create a feature branch
2. Modify workflow files
3. Push to trigger the pipeline
4. Verify changes work before merging to main

---

## 📊 Workflow Status

View current pipeline status in the repository README or Actions tab:

[![Infrastructure](../../actions/workflows/infra-aws.yml/badge.svg)](../../actions/workflows/infra-aws.yml)
[![Frontend](../../actions/workflows/frontend-aws.yml/badge.svg)](../../actions/workflows/frontend-aws.yml)

---

## 🔒 Security Best Practices

1. **Use OIDC instead of long-lived credentials** ✅
2. **Principle of least privilege** - IAM role has only required permissions
3. **No secrets in code** - All sensitive values in GitHub Secrets
4. **Branch protection** - Require PR reviews for workflow changes
5. **Regular updates** - Keep GitHub Actions versions current

---

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS OIDC with GitHub Actions](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Terraform GitHub Actions](https://developer.hashicorp.com/terraform/tutorials/automation/github-actions)
- [AWS CLI S3 Sync](https://docs.aws.amazon.com/cli/latest/reference/s3/sync.html)
- [CloudFront Invalidation](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Invalidation.html)

---

## 📝 Maintenance Notes

- **Terraform Version:** Currently using v1.14.0 (update in both workflows)
- **Node Version:** Using LTS (automatically updated)
- **Python Version:** 3.12 for Lambda packaging
- **Artifact Retention:** 1 day for build artifacts (adjust if needed)