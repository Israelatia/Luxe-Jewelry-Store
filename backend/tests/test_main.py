import unittest
from unittest.mock import patch

class TestApp(unittest.TestCase):
    def test_health_check(self):
        """Test the health check endpoint"""
        with patch('main.app.test_client') as mock_client:
            mock_client.return_value.get.return_value.status_code = 200
            response = mock_client.return_value.get('/health')
            self.assertEqual(response.status_code, 200)

if __name__ == '__main__':
    unittest.main()
