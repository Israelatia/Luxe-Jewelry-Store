import os
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer
from pydantic import BaseModel
from typing import List, Optional

app = FastAPI(title="Simple Jewelry Store API", version="1.0.0")

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Auth service configuration
AUTH_SERVICE_URL = os.getenv("AUTH_SERVICE_URL", "http://localhost:8001")
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"

security = HTTPBearer(auto_error=False)

# Data Models
class Product(BaseModel):
    id: int
    name: str
    price: float
    description: str = ""
    category: str = "jewelry"

# Simple in-memory database
products_db = [
    {
        "id": 1,
        "name": "Diamond Engagement Ring",
        "price": 2999.00,
        "image": "https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=300&h=300&fit=crop",
        "description": "Elegant 1.5 carat diamond ring in 18k white gold",
        "category": "rings",
        "in_stock": True
    },
    {
        "id": 2,
        "name": "Pearl Necklace",
        "price": 899.00,
        "image": "https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=300&h=300&fit=crop",
        "description": "Classic freshwater pearl necklace with sterling silver clasp",
        "category": "necklaces",
        "in_stock": True
    },
    {
        "id": 3,
        "name": "Gold Bracelet",
        "price": 1299.00,
        "image": "https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=300&h=300&fit=crop",
        "description": "Handcrafted 14k gold chain bracelet",
        "category": "bracelets",
        "in_stock": True
    },
    {
        "id": 4,
        "name": "Sapphire Earrings",
        "price": 1599.00,
        "image": "https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=300&h=300&fit=crop",
        "description": "Blue sapphire stud earrings in white gold setting",
        "category": "earrings",
        "in_stock": True
    },
    {
        "id": 5,
        "name": "Ruby Tennis Bracelet",
        "price": 3499.00,
        "image": "https://images.unsplash.com/photo-1573408301185-9146fe634ad0?w=300&h=300&fit=crop",
        "description": "Stunning ruby tennis bracelet with 18k white gold setting",
        "category": "bracelets",
        "in_stock": True
    },
    {
        "id": 6,
        "name": "Emerald Pendant",
        "price": 2199.00,
        "image": "https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=300&h=300&fit=crop",
        "description": "Exquisite emerald pendant with diamond accents",
        "category": "necklaces",
        "in_stock": True
    }
]

# Simple in-memory cart
cart = {}

@app.get("/")
async def root():
    return {"message": "Welcome to Simple Jewelry Store API"}

# Products endpoints
@app.get("/products", response_model=List[Dict])
async def get_products():
    """Get all products"""
    return products_db

@app.get("/products/{product_id}", response_model=Dict)
async def get_product(product_id: int):
    """Get a specific product by ID"""
    for product in products_db:
        if product["id"] == product_id:
            return product
    raise HTTPException(status_code=404, detail="Product not found")

@app.post("/cart/{item_id}")
async def add_to_cart(item_id: int, quantity: int = 1):
    """Add item to cart"""
    product = next((p for p in products_db if p["id"] == item_id), None)
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    if item_id in cart:
        cart[item_id]["quantity"] += quantity
    else:
        cart[item_id] = {
            "product": product,
            "quantity": quantity
        }
    
    return {"message": f"Added {quantity}x {product['name']} to cart"}

@app.get("/cart")
async def view_cart():
    """View cart contents"""
    items = []
    total = 0
    
    for item_id, item in cart.items():
        product = item["product"]
        quantity = item["quantity"]
        subtotal = product["price"] * quantity
        total += subtotal
        
        items.append({
            "product_id": item_id,
            "name": product["name"],
            "price": product["price"],
            "quantity": quantity,
            "subtotal": subtotal
        })
    
    return {
        "items": items,
        "total": total,
        "item_count": len(items)
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000)
