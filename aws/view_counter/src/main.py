import logging
from mangum import Mangum
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()

app = FastAPI(title="View Counter", description="Lambda View Counter API", version="1.0.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_methods=["*"],
    allow_headers=["*"],
    allow_credentials=True,
)

counter = {"value": 0}

@app.get("/")
async def root():
    return {"message": "View Counter API - Use /api/counter to interact with the counter"}

@app.get("/api/counter")
def get_counter():
    return {"counter": counter["value"]}

@app.post("/api/counter")
def increment_counter():
    counter["value"] += 1
    return {"counter": counter["value"]}

handler = Mangum(app)

def lambda_handler(event, context):
    """
    AWS Lambda handler function that processes API Gateway events.
    """

    # Log the incoming event
    logger.info(f"Received event: {event}")
    logger.info(f"Event type: {type(event)}")

    # Check if this is an API Gateway event
    if "httpMethod" in event or "requestContext" in event:
        logger.info("Processing API Gateway event")
        # return handler(event, context)
    else:
        logger.error("Event does not appear to be from API Gateway")
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "body": '{"error": "Invalid event source"}'
        }

    return handler(event, context)

    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": f'{{"error": "Internal server error: {str(e)}"}}'
        }