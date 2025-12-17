## Using Terraform

We have multiple options for IaC:
- CloudFormation
- AWS CDK
- Terraform
- OpenTofu

We are going to use **Terraform** because it's the most prevalent in the jobs postings I've found on LinkedIn.

## Connecting Github Actions and AWS

In order to enable GitHub Actions to deploy to AWS accounts we need to do the following steps:
- Create an OIDC Identity Provider in our AWS Account for GitHub
    - Provider: token.actions.githubusercontent.com
    - Audience: sts.amazonaws.com
- Create a new Role for GitHub Actions to use for the deployment
    - Add the previously created Identity as a Trusted Relationship
    - Give permissions to the services that we'll be using (S3, CloudFront, ACM, R53, IAM, CloudWatch, Lambda, API Gateway, etc)
- In our GitHub repository settings, include the role as a secret to be used in the Actions pipeline

![](/aws/docs/github-oidc.webp)  

![](/aws/docs/github-role.webp)  

![](/aws/docs/github-secrets.webp)  
