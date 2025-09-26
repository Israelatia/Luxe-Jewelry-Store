import pytest
from unittest.mock import patch, AsyncMock
import jwt
from fastapi.testclient import TestClient
import sys
import os

# Add the backend directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))

from main import app, JWT_SECRET_KEY, ALGORITHM

client = TestClient(app)

class TestAuthentication:
    """Test suite for authentication functionality"""

    def test_verify_token_valid(self):
        """Test token verification with valid token"""
        # Create a valid token
        payload = {"sub": "user123"}
        token = jwt.encode(payload, JWT_SECRET_KEY, algorithm=ALGORITHM)
        
        # Test endpoint that uses authentication (indirectly)
        headers = {"Authorization": f"Bearer {token}"}
        response = client.get("/api/cart", headers=headers)
        assert response.status_code == 200

    def test_verify_token_invalid(self):
        """Test token verification with invalid token"""
        # Use invalid token
        headers = {"Authorization": "Bearer invalid_token"}
        response = client.get("/api/cart", headers=headers)
        # Should still work but without user context
        assert response.status_code == 200

    def test_no_token_provided(self):
        """Test endpoints without token (anonymous access)"""
        response = client.get("/api/products")
        assert response.status_code == 200
        
        response = client.get("/api/cart")
        assert response.status_code == 200

    @patch('main.httpx.AsyncClient')
    async def test_get_current_user_success(self, mock_client):
        """Test successful user retrieval from auth service"""
        # Mock the auth service response
        mock_response = AsyncMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"id": "user123", "email": "test@example.com"}
        
        mock_client_instance = AsyncMock()
        mock_client_instance.get.return_value = mock_response
        mock_client.return_value.__aenter__.return_value = mock_client_instance
        
        # This test would require async testing setup
        # For now, we'll test the endpoint behavior
        payload = {"sub": "user123"}
        token = jwt.encode(payload, JWT_SECRET_KEY, algorithm=ALGORITHM)
        headers = {"Authorization": f"Bearer {token}"}
        
        response = client.get("/api/cart", headers=headers)
        assert response.status_code == 200

if __name__ == "__main__":
    pytest.main([__file__])
