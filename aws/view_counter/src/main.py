import logging
from fastapi import FastAPI
from mangum import Mangum

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

    return handler(event, context)