import os
import boto3
import logging
from mangum import Mangum
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s', force=True)
logger = logging.getLogger()
logger.setLevel(logging.INFO)

app = FastAPI(title="View Counter", description="Lambda View Counter API", version="1.0.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://resume.riosr.com"],  # In production, replace with specific origins
    allow_methods=["*"],
    allow_headers=["*"],
    allow_credentials=True,
)

# DynamoDB setup
TABLE_NAME = os.getenv("VIEW_COUNTER_TABLE", "ViewCounter") # adjust if your table name differs
ITEM_KEY = {"id": "global"}  # adjust if your partition key name differs

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)

def _get_counter():
    try:
        resp = table.get_item(Key=ITEM_KEY, ConsistentRead=True)
        value = resp.get("Item", {}).get("value", 0)
        return int(value)
    except ClientError as e:
        logger.error("DynamoDB get_item error: %s", e)
        raise

def _increment_counter():
    try:
        # Atomically increment value attribute; create item if missing
        resp = table.update_item(
            Key=ITEM_KEY,
            UpdateExpression="SET #v = if_not_exists(#v, :zero) + :inc",
            ExpressionAttributeNames={"#v": "value"},
            ExpressionAttributeValues={":zero": 0, ":inc": 1},
            ReturnValues="UPDATED_NEW",
        )
        return int(resp["Attributes"]["value"])
    except ClientError as e:
        logger.error("DynamoDB update_item error: %s", e)
        raise

@app.get("/api/counter")
def get_counter():
    value = _get_counter()
    return {"counter": value}

@app.post("/api/counter")
def increment_counter():
    value = _increment_counter()
    return {"counter": value}

# Create Mangum adapter with proper configuration for API Gateway
handler = Mangum(app)

def lambda_handler(event, context):
    """
    AWS Lambda handler function that processes API Gateway events.
    """
    try:
        # Log the incoming event
        logger.info(f"Received event: {event}")
        logger.info(f"Event type: {type(event)}")

        # Check if this is an API Gateway event
        if "httpMethod" in event or "requestContext" in event:
            logger.info("Processing API Gateway event")
            return handler(event, context)
        else:
            logger.error("Event does not appear to be from API Gateway")
            return {
                "statusCode": 400,
                "headers": {"Content-Type": "application/json"},
                "body": '{"error": "Invalid event source"}'
            }

    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": f'{{"error": "Internal server error: {str(e)}"}}'
        }