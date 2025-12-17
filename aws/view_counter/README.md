# Lambda Counter API

This project implements a simple counter API using FastAPI and AWS Lambda. It provides endpoints to retrieve and increment a counter value stored in DynamoDB.

## Architecture

This Lambda function is part of the Cloud Resume Challenge and serves as the backend API for tracking website view counts. It uses:

- **AWS Lambda**: Serverless compute to run the FastAPI application
- **Amazon DynamoDB**: NoSQL database to persist the counter value
- **API Gateway**: HTTP API to expose Lambda function endpoints
- **Mangum**: ASGI adapter to run FastAPI on AWS Lambda

**Infrastructure**: All AWS resources are provisioned and managed through Terraform (see the Terraform configuration in the repository root).

## Project Structure

```
view_counter
├── src
│   ├── main.py          # Main logic for the Lambda function and FastAPI application
│   └── requirements.txt # Dependencies required for the project
├── tests
│   └── test_main.py     # Unit tests for the API endpoints
└── README.md            # Project documentation
```

## Lambda Function Details

### Handler

The Lambda handler is defined in `main.py` using Mangum:

```python
handler = Mangum(app)
```

### Environment Variables

The Lambda function requires the following environment variables (automatically configured by Terraform):

- `TABLE_NAME`: Name of the DynamoDB table storing the counter
- `AWS_REGION`: AWS region where DynamoDB table is located

### DynamoDB Table Structure

The function expects a DynamoDB table with:

- **Primary Key**: `id` (String)
- **Attribute**: `views` (Number)
- **Item**: Single record with `id = "view-counter"`

## API Endpoints

- **GET /api/counter**
  - Retrieves the current counter value.
  - Response: `{"count": <number>}`
- **POST /api/counter**
  - Increments the counter value by 1 and returns the updated value.
  - Response: `{"count": <number>}`

## Deployment

### Infrastructure as Code

All AWS infrastructure for this Lambda function is managed through **Terraform**. The Terraform configuration handles:

- Lambda function creation and configuration
- DynamoDB table provisioning
- API Gateway HTTP API setup
- IAM roles and policies
- CloudWatch log groups
- CORS configuration

### Deployment Process

The deployment is automated through the Terraform pipeline:

1. **Code Changes**: Make changes to `main.py` or `requirements.txt`
2. **Commit & Push**: Push changes to the repository
3. **Terraform Pipeline**: The CI/CD pipeline automatically:
   - Packages the Lambda function with dependencies
   - Creates a deployment ZIP file
   - Runs `terraform plan` to preview changes
   - Runs `terraform apply` to deploy updates
   - Updates Lambda function code and configuration

### Manual Deployment

If you need to deploy manually:

```bash
# Navigate to the Terraform directory
cd terraform/

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply changes
terraform apply
```

### Terraform Resources

The following resources are managed by Terraform for this Lambda function:

- `aws_lambda_function.view_counter` - Lambda function
- `aws_dynamodb_table.view_counter` - DynamoDB table
- `aws_iam_role.lambda_exec` - Lambda execution role
- `aws_iam_policy.lambda_dynamodb` - DynamoDB access policy
- `aws_apigatewayv2_api.counter_api` - API Gateway
- `aws_apigatewayv2_integration.lambda` - API Gateway integration
- `aws_lambda_permission.api_gateway` - API Gateway invoke permission

## Monitoring

- **CloudWatch Logs**: Lambda execution logs are automatically sent to CloudWatch (log group created by Terraform)
- **CloudWatch Metrics**: Monitor invocations, duration, errors, and throttles through the AWS Console

## CORS Configuration

The API CORS settings are configured in Terraform to allow requests from your resume website domain.

## Troubleshooting

### Common Issues

1. **403 Forbidden**:
   - Check IAM permissions in Terraform IAM policy
   - Verify Lambda execution role is properly attached
2. **500 Internal Server Error**:
   - Check CloudWatch Logs: `/aws/lambda/view-counter`
   - Verify environment variables are set correctly in Terraform
3. **CORS Errors**:
   - Update allowed origins in Terraform configuration
   - Redeploy with `terraform apply`
4. **Deployment Failures**:
   - Check Terraform state: `terraform state list`
   - Review Terraform plan output before applying
   - Verify AWS credentials and permissions

### Viewing Logs

```bash
# Using AWS CLI
aws logs tail /aws/lambda/view-counter --follow
```

## Performance Considerations

Configuration managed by Terraform:

- **Memory**: Configurable in Terraform (default varies)
- **Timeout**: Configurable in Terraform (default varies)
- **Concurrency**: Adjust reserved concurrency in Terraform if needed

## Cost Estimation

Based on 10,000 requests per month:

- Lambda: $0.20 (128MB memory, 100ms avg duration, 10K invocations)
- DynamoDB: $0.28 (10K reads + 10K writes on-demand pricing)
- API Gateway: $0.01 (10K requests at $1.00 per million)
- CloudWatch Logs: $0.50 (500MB ingested at $0.50/GB)
- **Total**: ~$0.99/month

*Note: Costs may vary based on actual usage patterns and AWS region. AWS Free Tier may cover most of these costs for low-traffic sites.*
