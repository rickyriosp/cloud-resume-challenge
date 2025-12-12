# Lambda Counter API

This project implements a simple counter API using FastAPI and AWS Lambda. It provides endpoints to retrieve and increment a counter value.

## Project Structure

```
view_counter
├── src
│   ├── main.py          # Main logic for the Lambda function and FastAPI application
│   └── requirements.txt  # Dependencies required for the project
├── tests
│   └── test_main.py     # Unit tests for the API endpoints
└── README.md            # Project documentation
```

## Setup Instructions

1. **Clone the repository:**
   ```
   git clone <repository-url>
   cd view_counter
   ```

2. **Install dependencies:**
   Navigate to the `src` directory and install the required packages:
   ```
   cd src
   pip install -r requirements.txt
   ```

## Usage

To run the FastAPI application locally, you can use the following command:
```
uvicorn main:app --reload
```

This will start the server at `http://127.0.0.1:8000`.

### API Endpoints

- **GET /api/counter**
  - Retrieves the current counter value.
  
- **POST /api/counter**
  - Increments the counter value by 1 and returns the updated value.

## Testing

To run the unit tests, navigate to the `tests` directory and execute:
```
pytest test_main.py
```

## License

This project is licensed under the MIT License.