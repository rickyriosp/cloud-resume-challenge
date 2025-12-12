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
    - Give permissions to the services that we'll be using (S3, CloudFront, ACM, R53)
- In our GitHub repository settings, include the role as a secret to be used in the Actions pipeline

![](/aws/docs/github-oidc.webp)

![](/aws/docs/github-role.webp)

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "S3TerraformStateBackend",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::cloud-resume-challenge-terraform-state-75jasd7",
                "arn:aws:s3:::cloud-resume-challenge-terraform-state-75jasd7/*"
            ]
        },
        {
            "Sid": "S3FrontendHostingBucket",
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "arn:aws:s3:::cloud-resume-challenge-frontend-*",
                "arn:aws:s3:::cloud-resume-challenge-frontend-*/*"
            ]
        },
        {
            "Sid": "CloudFrontPermissions",
            "Effect": "Allow",
            "Action": [
                "cloudfront:GetDistribution",
                "cloudfront:GetDistributionConfig",
                "cloudfront:ListDistributions",
                "cloudfront:CreateDistribution",
                "cloudfront:UpdateDistribution",
                "cloudfront:DeleteDistribution",
                "cloudfront:TagResource",
                "cloudfront:UntagResource",
                "cloudfront:ListTagsForResource",
                "cloudfront:GetOriginAccessControl",
                "cloudfront:CreateOriginAccessControl",
                "cloudfront:UpdateOriginAccessControl",
                "cloudfront:DeleteOriginAccessControl",
                "cloudfront:ListOriginAccessControls",
                "cloudfront:CreateInvalidation",
                "cloudfront:GetInvalidation",
                "cloudfront:ListInvalidations"
            ],
            "Resource": "*"
        },
        {
            "Sid": "ACMCertificatePermissions",
            "Effect": "Allow",
            "Action": [
                "acm:DescribeCertificate",
                "acm:ListCertificates",
                "acm:RequestCertificate",
                "acm:DeleteCertificate",
                "acm:AddTagsToCertificate",
                "acm:ListTagsForCertificate",
                "acm:RemoveTagsFromCertificate",
                "acm:GetCertificate"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Route53Permissions",
            "Effect": "Allow",
            "Action": [
                "route53:GetHostedZone",
                "route53:ListHostedZones",
                "route53:ListHostedZonesByName",
                "route53:ListResourceRecordSets",
                "route53:ChangeResourceRecordSets",
                "route53:GetChange",
                "route53:ListTagsForResource",
                "route53:ChangeTagsForResource"
            ],
            "Resource": "*"
        }
    ]
}
```

![](/aws/docs/github-secrets.webp)