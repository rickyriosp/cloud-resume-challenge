import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()

def lambda_handler(event, context):
    """
    AWS Lambda handler function that processes API Gateway events.
    """

    # Log the incoming event
    logger.info(f"Received event: {event}")

    # Simulate incrementing a view counter (in a real scenario, this would interact with a database)
    view_count = event.get('view_count', 0) + 1

    # Log the updated view count
    logger.info(f"Updated view count: {view_count}")

    # Return the updated view count
    return {
        'statusCode': 200,
        'body': {
            'view_count': view_count
        }
    }

