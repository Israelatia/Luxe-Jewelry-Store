import pytest
import asyncio
from fastapi.testclient import TestClient
from unittest.mock import patch, AsyncMock
import sys
import os

# Add the backend directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))

from main import app, products_db, carts_db, user_carts_db

client = TestClient(app)

class TestLuxeJewelryAPI:
    """Test suite for Luxe Jewelry Store API"""

    def setup_method(self):
        """Setup method run before each test"""
        # Clear carts before each test
        carts_db.clear()
        user_carts_db.clear()

    def test_root_endpoint(self):
        """Test the root endpoint returns welcome message"""
        response = client.get("/")
        assert response.status_code == 200
        assert response.json() == {"message": "Welcome to Luxe Jewelry Store API"}

    def test_get_all_products(self):
        """Test getting all products"""
        response = client.get("/api/products")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) == len(products_db)
        assert data[0]["name"] == "Diamond Engagement Ring"

    def test_get_products_by_category(self):
        """Test filtering products by category"""
        response = client.get("/api/products?category=rings")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert all(product["category"] == "rings" for product in data)

    def test_get_product_by_id(self):
        """Test getting a specific product by ID"""
        response = client.get("/api/products/1")
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == 1
        assert data["name"] == "Diamond Engagement Ring"
        assert data["price"] == 2999.00

    def test_get_nonexistent_product(self):
        """Test getting a product that doesn't exist"""
        response = client.get("/api/products/999")
        assert response.status_code == 404
        assert response.json()["detail"] == "Product not found"

    def test_add_item_to_cart(self):
        """Test adding an item to cart"""
        session_id = "test_session"
        item_data = {"product_id": 1, "quantity": 2}
        
        response = client.post(f"/api/cart/{session_id}/add", json=item_data)
        assert response.status_code == 200
        data = response.json()
        assert data["message"] == "Item added to cart"
        assert data["cart_items"] == 1

    def test_add_nonexistent_product_to_cart(self):
        """Test adding a non-existent product to cart"""
        session_id = "test_session"
        item_data = {"product_id": 999, "quantity": 1}
        
        response = client.post(f"/api/cart/{session_id}/add", json=item_data)
        assert response.status_code == 404
        assert response.json()["detail"] == "Product not found"

    def test_get_empty_cart(self):
        """Test getting an empty cart"""
        response = client.get("/api/cart?session_id=empty_session")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) == 0

    def test_get_cart_with_items(self):
        """Test getting cart with items"""
        session_id = "test_session"
        # Add item to cart first
        item_data = {"product_id": 1, "quantity": 2}
        client.post(f"/api/cart/{session_id}/add", json=item_data)
        
        # Get cart
        response = client.get(f"/api/cart?session_id={session_id}")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["product_id"] == 1
        assert data[0]["quantity"] == 2

    def test_update_cart_item_quantity(self):
        """Test updating cart item quantity"""
        session_id = "test_session"
        # Add item to cart first
        item_data = {"product_id": 1, "quantity": 1}
        client.post(f"/api/cart/{session_id}/add", json=item_data)
        
        # Get the item ID
        cart_response = client.get(f"/api/cart?session_id={session_id}")
        item_id = cart_response.json()[0]["id"]
        
        # Update quantity
        response = client.put(f"/api/cart/{session_id}/item/{item_id}?quantity=5")
        assert response.status_code == 200
        assert response.json()["message"] == "Item quantity updated"

    def test_remove_cart_item(self):
        """Test removing an item from cart"""
        session_id = "test_session"
        # Add item to cart first
        item_data = {"product_id": 1, "quantity": 1}
        client.post(f"/api/cart/{session_id}/add", json=item_data)
        
        # Get the item ID
        cart_response = client.get(f"/api/cart?session_id={session_id}")
        item_id = cart_response.json()[0]["id"]
        
        # Remove item
        response = client.delete(f"/api/cart/{session_id}/item/{item_id}")
        assert response.status_code == 200
        assert response.json()["message"] == "Item removed from cart"

    def test_clear_cart(self):
        """Test clearing entire cart"""
        session_id = "test_session"
        # Add items to cart first
        item_data = {"product_id": 1, "quantity": 1}
        client.post(f"/api/cart/{session_id}/add", json=item_data)
        
        # Clear cart
        response = client.delete(f"/api/cart/{session_id}")
        assert response.status_code == 200
        assert response.json()["message"] == "Cart cleared"
        
        # Verify cart is empty
        cart_response = client.get(f"/api/cart?session_id={session_id}")
        assert len(cart_response.json()) == 0

    def test_get_categories(self):
        """Test getting all product categories"""
        response = client.get("/api/categories")
        assert response.status_code == 200
        data = response.json()
        assert "categories" in data
        assert isinstance(data["categories"], list)
        assert "rings" in data["categories"]
        assert "necklaces" in data["categories"]

    def test_add_duplicate_item_to_cart(self):
        """Test adding the same item twice increases quantity"""
        session_id = "test_session"
        item_data = {"product_id": 1, "quantity": 1}
        
        # Add item first time
        client.post(f"/api/cart/{session_id}/add", json=item_data)
        
        # Add same item again
        response = client.post(f"/api/cart/{session_id}/add", json=item_data)
        assert response.status_code == 200
        
        # Check cart has one item with quantity 2
        cart_response = client.get(f"/api/cart?session_id={session_id}")
        cart_data = cart_response.json()
        assert len(cart_data) == 1
        assert cart_data[0]["quantity"] == 2

    @patch('main.get_current_user')
    def test_authenticated_user_cart(self, mock_get_user):
        """Test cart functionality for authenticated users"""
        # Mock authenticated user
        mock_get_user.return_value = {"id": "user123", "email": "test@example.com"}
        
        session_id = "test_session"
        item_data = {"product_id": 1, "quantity": 1}
        
        # Add item to cart as authenticated user
        response = client.post(f"/api/cart/{session_id}/add", json=item_data)
        assert response.status_code == 200
        
        # Get cart as authenticated user
        response = client.get("/api/cart")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["product_id"] == 1

if __name__ == "__main__":
    pytest.main([__file__])
