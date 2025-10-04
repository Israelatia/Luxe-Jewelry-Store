import os
import sys
import pytest
from fastapi.testclient import TestClient

# Add the parent directory to the Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app

@pytest.fixture
def client():
    with TestClient(app) as test_client:
        yield test_client

def test_health_check(client):
    """Test the health check endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

def test_get_products(client):
    """Test getting all products"""
    response = client.get("/api/products")
    assert response.status_code == 200
    products = response.json()
    assert isinstance(products, list)
    assert len(products) > 0

def test_get_product(client):
    """Test getting a single product"""
    # First get the list of products to get a valid ID
    products = client.get("/api/products").json()
    if products:
        product_id = products[0]["id"]
        response = client.get(f"/api/products/{product_id}")
        assert response.status_code == 200
        product = response.json()
        assert product["id"] == product_id

def test_add_to_cart(client):
    """Test adding an item to cart"""
    # First get a valid product ID
    products = client.get("/api/products").json()
    if products:
        product_id = products[0]["id"]
        response = client.post(f"/api/cart/add/{product_id}", json={"quantity": 1})
        assert response.status_code == 200
        assert "item_id" in response.json()

def test_view_cart(client):
    """Test viewing the cart"""
    response = client.get("/api/cart")
    assert response.status_code == 200
    cart = response.json()
    assert isinstance(cart, dict)
    assert "items" in cart
    assert "total" in cart
