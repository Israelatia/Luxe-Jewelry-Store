# Luxe Jewelry Store - FastAPI Backend

This is the Python FastAPI backend for the Luxe Jewelry Store application.

## Features

- **Product Management**: Get all products, filter by category, get individual products
- **Cart Operations**: Add items, remove items, update quantities, clear cart
- **Session-based Carts**: Each user session maintains its own cart
- **CORS Support**: Configured for React frontend integration
- **RESTful API**: Clean, well-documented endpoints

## API Endpoints

### Products
- `GET /api/products` - Get all products (optional `category` query parameter)
- `GET /api/products/{product_id}` - Get specific product
- `GET /api/categories` - Get all product categories

### Cart Operations
- `POST /api/cart/{session_id}/add` - Add item to cart
- `GET /api/cart/{session_id}` - Get cart contents
- `PUT /api/cart/{session_id}/item/{item_id}` - Update item quantity
- `DELETE /api/cart/{session_id}/item/{item_id}` - Remove item from cart
- `DELETE /api/cart/{session_id}` - Clear entire cart

## Installation & Setup

1. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Run the server:
```bash
python main.py
```

The API will be available at `http://localhost:8000`

## API Documentation

FastAPI automatically generates interactive API documentation:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Data Models


### Product
- `id`: Unique product identifier
- `name`: Product name
- `price`: Product price
- `image`: Product image URL
- `description`: Product description
- `category`: Product category
- `in_stock`: Availability status

### Cart Item
- `id`: Unique cart item identifier
- `product_id`: Reference to product
- `quantity`: Item quantity
- `added_at`: Timestamp when added

## Development Notes

- Currently uses in-memory storage for simplicity
- In production, replace with a proper database (PostgreSQL, MongoDB, etc.)
- Session management is basic - consider JWT tokens for production
- Add authentication and user management for production use
