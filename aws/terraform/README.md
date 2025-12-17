# Cloud Resume Challenge - Terraform Infrastructure

This directory contains the Infrastructure as Code (IaC) for deploying the Cloud Resume Challenge on AWS using Terraform.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Infrastructure Components](#infrastructure-components)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Outputs](#outputs)
- [GitHub Actions Integration](#github-actions-integration)

## Overview

This Terraform configuration deploys a serverless architecture for hosting a resume website with a visitor counter. The infrastructure includes:

- Static website hosting via S3 and CloudFront
- RESTful API using API Gateway and Lambda
- DynamoDB for visitor count persistence
- SSL/TLS certificates via ACM
- CloudWatch for logging and monitoring

## Architecture

```
User → CloudFront → S3 (Static Website)
  ↓
API Gateway → Lambda → DynamoDB (ViewCounter)
  ↓
CloudWatch Logs
```

**Domains:**

- Frontend: `resume.riosr.com` (CloudFront distribution)
- API: `api-counter.riosr.com` (API Gateway custom domain)

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 (using AWS provider ~> 6.0)
3. **S3 Backend Bucket** for state management: `cloud-resume-challenge-terraform-state-75jasd7`
4. **Domain** registered and managed (e.g., Route 53 or external DNS provider)
5. **Lambda Deployment Packages:**
   - `lambda_package.zip` - Lambda function code
   - `dependencies.zip` - Lambda layer dependencies

## Infrastructure Components

### 1. Provider Configuration (`main.tf`)

- **Region:** us-east-1 (required for CloudFront ACM certificates)
- **Default Tags:** Application and Environment tags applied to all resources
- **Local Variables:**
  - Domain: `riosr.com`
  - Subdomain: `resume`
  - API Subdomain: `api-counter`
  - Python Version: `python3.12`

### 2. S3 Bucket (`s3.tf`)

- **Resource:** `aws_s3_bucket.frontend`
- **Bucket Name:** `cloud-resume-challenge-frontend-as61z23`
- **Features:**
  - Block all public access (secured via CloudFront OAC)
  - Bucket policy allows CloudFront Service Principal access
  - Force destroy enabled for easy cleanup

### 3. CloudFront Distribution (`cloudfront.tf`)

- **Resource:** `aws_cloudfront_distribution.s3_frontend`
- **Features:**
  - Origin Access Control (OAC) for S3 bucket security
  - IPv6 enabled
  - Custom SSL certificate from ACM
  - Default root object: `index.html`
  - Price class: 100 (North America & Europe)
- **Caching:**
  - Min TTL: 0 seconds
  - Default TTL: 3600 seconds (1 hour)
  - Max TTL: 86400 seconds (24 hours)

### 4. ACM Certificates (`acm.tf`)

Two SSL/TLS certificates (both DNS validated):

- **Frontend:** `resume.riosr.com`
- **API:** `api-counter.riosr.com`

### 5. DynamoDB Table (`dynamodb.tf`)

- **Table Name:** `ViewCounter`
- **Billing Mode:** Provisioned (5 RCU, 5 WCU)
- **Primary Key:** `id` (String)
- **Purpose:** Store and retrieve visitor count

### 6. Lambda Function (`lambda.tf`)

- **Function Name:** `view-counter`
- **Runtime:** Python 3.12
- **Handler:** `src.main.lambda_handler`
- **Timeout:** 10 seconds
- **Environment Variables:**
  - `VIEW_COUNTER_TABLE`: DynamoDB table name
- **Lambda Layer:** Custom dependencies layer for required Python packages
- **Permissions:** Invoked by API Gateway via resource policy

### 7. API Gateway (`api_gateway.tf`)

- **Type:** HTTP API (API Gateway v2)
- **API Name:** `cloud-resume-view-counter`
- **Integration:** AWS_PROXY with Lambda function
- **Route:** `ANY /api/{proxy+}`
- **Custom Domain:** `api-counter.riosr.com`
- **Stage:** `$default` (auto-deployed)
- **Features:**
  - Regional endpoint
  - TLS 1.2 security policy
  - Automatic redeployment on configuration changes

### 8. IAM Roles & Policies (`iam.tf`)

#### Lambda Execution Role

- **Role:** `view_counter_lambda_execution_role`
- **Policies:**
  - CloudWatch Logs access (create log groups/streams, write logs)
  - DynamoDB access (read/write operations on ViewCounter table)

#### API Gateway CloudWatch Role

- **Role:** `api_gateway_cloudwatch_role`
- **Policy:** CloudWatch Logs access

### 9. CloudWatch (`cloudwatch.tf`)

- Log group resources are commented out but available for future use
- IAM policies enable Lambda and API Gateway logging

### 10. Backend Configuration (`backend.tf`)

- **Backend Type:** S3
- **Bucket:** `cloud-resume-challenge-terraform-state-75jasd7`
- **Region:** us-east-1
- **Encryption:** Enabled
- **State Locking:** Uses local lockfile (DynamoDB locking commented out)

## Configuration

### Local Variables (main.tf)

Update these values for your deployment:

```hcl
locals {
  region         = "us-east-1"
  domain         = "riosr.com"           # Your domain
  subdomain      = "resume"              # Frontend subdomain
  api_subdomain  = "api-counter"         # API subdomain
  s3_origin_id   = "cloudResumeS3Origin"
  python_version = "python3.12"
}
```

### Required Files

Before running Terraform, ensure these files exist in the terraform directory:

- `lambda_package.zip` - Contains the Lambda function code from `aws/view_counter/src/`
- `dependencies.zip` - Contains Python dependencies for the Lambda layer

## Deployment

### Initial Setup

1. **Create Backend Bucket** (one-time):

   ```bash
   aws s3api create-bucket \
     --bucket cloud-resume-challenge-terraform-state-75jasd7 \
     --region us-east-1

   aws s3api put-bucket-versioning \
     --bucket cloud-resume-challenge-terraform-state-75jasd7 \
     --versioning-configuration Status=Enabled
   ```

2. **Prepare Lambda Packages**:
   ```bash
   cd ../view_counter
   ./package_code.sh
   mv lambda_package.zip ../terraform/
   mv dependencies.zip ../terraform/
   cd ../terraform
   ```

### Terraform Commands

```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Apply infrastructure changes
terraform apply

# Destroy infrastructure (when needed)
terraform destroy
```

### Post-Deployment DNS Configuration

After deployment, create DNS records:

1. **Frontend:** CNAME record for `resume.riosr.com` → CloudFront distribution domain
2. **API:** CNAME record for `api-counter.riosr.com` → API Gateway domain
3. **Certificate Validation:** Add DNS validation records for both ACM certificates

## Outputs

The following outputs are available after deployment:

| Output                        | Description                                       |
| ----------------------------- | ------------------------------------------------- |
| `aws_s3_frontend_bucket_name` | Name of the S3 bucket hosting the frontend        |
| `cloudfront_distribution_id`  | CloudFront distribution ID for cache invalidation |

Access outputs with:

```bash
terraform output
terraform output cloudfront_distribution_id
```

## GitHub Actions Integration

### OIDC Authentication Setup

To enable GitHub Actions to deploy to AWS, configure OIDC authentication:

1. **Create OIDC Identity Provider** in AWS:

   - Provider URL: `token.actions.githubusercontent.com`
   - Audience: `sts.amazonaws.com`

2. **Create IAM Role** for GitHub Actions:

   - Trust relationship with the OIDC provider
   - Permissions for required services:
     - S3 (PutObject, DeleteObject)
     - CloudFront (CreateInvalidation)
     - ACM (read certificates)
     - Lambda (UpdateFunctionCode)
     - API Gateway (UpdateApi, CreateDeployment)
     - DynamoDB (read/write)
     - CloudWatch (write logs)
     - IAM (limited for role management)

3. **Add GitHub Secrets** in repository settings:
   - `AWS_ROLE_ARN` - ARN of the IAM role created above
   - Any other environment-specific variables

### Architecture Diagrams

![GitHub OIDC Setup](/aws/docs/github-oidc.webp)  
![GitHub IAM Role](/aws/docs/github-role.webp)  
![GitHub Repository Secrets](/aws/docs/github-secrets.webp)

## Why Terraform?

We chose Terraform over other IaC options (CloudFormation, AWS CDK, OpenTofu) because:

- Most prevalent in job postings
- Cloud-agnostic (can extend to multi-cloud)
- Large community and extensive documentation
- Declarative syntax with good readability

## Maintenance Notes

- **State Management:** State is stored in S3 with encryption enabled
- **Lambda Updates:** Run `package_code.sh` and re-apply to update Lambda function
- **Dependencies:** Update `dependencies.zip` when Python requirements change
- **CloudFront Cache:** Invalidate cache after frontend updates using the distribution ID output
- **Cost Optimization:** Current configuration uses minimal resources (5 RCU/WCU DynamoDB, CloudFront PriceClass_100)
