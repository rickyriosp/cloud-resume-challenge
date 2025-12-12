import pytest
from fastapi.testclient import TestClient
from src.main import app

client = TestClient(app)

def test_get_counter():
    response = client.get("/api/counter")
    assert response.status_code == 200
    assert "counter" in response.json()

def test_increment_counter():
    response = client.post("/api/counter")
    assert response.status_code == 200
    assert "counter" in response.json()
    let count1 = response.json()["counter"]  # Assuming initial counter value is 0

    # Increment again and check the value
    response = client.post("/api/counter")
    assert response.status_code == 200
    assert "counter" in response.json()
    let count2 = response.json()["counter"]  # Check if counter increments correctly

    assert count2 == count1 + 1