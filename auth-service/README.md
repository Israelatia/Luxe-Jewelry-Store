# Luxe Jewelry Store - Authentication Microservice

This is the authentication microservice for the Luxe Jewelry Store application, handling user registration, login, and profile management.

## Features

- **User Registration**: Create new user accounts with email validation
- **User Authentication**: JWT-based login system
- **Profile Management**: Update user profiles and change passwords
- **Token Validation**: Secure JWT token verification
- **Password Security**: Bcrypt password hashing
- **CORS Support**: Configured for React frontend integration




## API Endpoints

### Authentication
- `POST /auth/register` - Register a new user
- `POST /auth/login` - Login user and get access token
- `POST /auth/logout` - Logout user
- `POST /auth/change-password` - Change user password

### User Profile
- `GET /auth/me` - Get current user profile
- `PUT /auth/me` - Update current user profile

### Admin (Development)
- `GET /auth/users` - Get all users (admin endpoint)
- `GET /health` - Health check endpoint

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

3. Set environment variables (optional):
```bash
export JWT_SECRET_KEY="your-super-secret-jwt-key"
```

4. Run the service:
```bash
python main.py
```

The auth service will be available at `http://localhost:8001`

## API Documentation

FastAPI automatically generates interactive API documentation:
- Swagger UI: `http://localhost:8001/docs`
- ReDoc: `http://localhost:8001/redoc`

## Data Models

### User Registration
```json
{
  "email": "user@example.com",
  "password": "securepassword",
  "first_name": "John",
  "last_name": "Doe",
  "phone": "+1234567890"
}
```

### User Login
```json
{
  "email": "user@example.com",
  "password": "securepassword"
}
```


### Token Response
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "expires_in": 1800,
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "phone": "+1234567890",
    "created_at": "2024-01-01T00:00:00",
    "is_active": true
  }
}
```

## Security Features

- **JWT Tokens**: Secure authentication with configurable expiration
- **Password Hashing**: Bcrypt with salt for secure password storage
- **Email Validation**: Pydantic email validation
- **Token Verification**: Middleware for protected endpoints

## Microservice Architecture

This service runs independently on port 8001 and communicates with:
- **Main API Service** (port 8000): Product and cart management
- **React Frontend** (port 3000): User interface

## Development Notes

- Currently uses in-memory storage for simplicity
- In production, replace with a proper database (PostgreSQL, MongoDB, etc.)
- JWT secret key should be stored securely (environment variables, secrets manager)
- Add rate limiting for authentication endpoints in production
- Consider implementing refresh tokens for better security
- Add email verification for new user registrations

## Environment Variables

- `JWT_SECRET_KEY`: Secret key for JWT token signing (default: development key)

## Health Check

The service provides a health check endpoint at `/health` that returns:
- Service status
- Current timestamp
- Number of registered users
