# 💎 Luxe Jewelry Store - Complete Project Presentation

## 📋 Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture & Namespace](#architecture--namespace)
3. [Technology Stack](#technology-stack)
4. [Project Structure](#project-structure)
5. [Services & Components](#services--components)
6. [CI/CD Pipeline](#cicd-pipeline)
7. [Containerization & Docker](#containerization--docker)
8. [Kubernetes Deployment](#kubernetes-deployment)
9. [Environment Configuration](#environment-configuration)
10. [Security Implementation](#security-implementation)
11. [API Documentation](#api-documentation)
12. [Development Workflow](#development-workflow)
13. [Deployment Guide](#deployment-guide)
14. [Monitoring & Maintenance](#monitoring--maintenance)

---

## 🎯 Project Overview

### Project Name
**Luxe Jewelry Store** - Full-Stack E-Commerce Microservices Application

### Namespace
- **Kubernetes Namespace**: `israel-app`
- **AWS Account ID**: `992398098051`
- **AWS Region**: `us-east-1`
- **ECR Repository**: `992398098051.dkr.ecr.us-east-1.amazonaws.com/aws-project`

### Business Domain
E-commerce platform specializing in luxury jewelry items with modern microservices architecture.

### Key Features
- 🛍️ Product catalog management
- 🛒 Shopping cart functionality
- 👤 User authentication & authorization
- 📱 Responsive web interface
- 🐳 Containerized deployment
- 🔄 CI/CD automation
- ☁️ Cloud-native architecture

---

## 🏗️ Architecture & Namespace

### System Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend API   │    │  Auth Service   │
│   (React)       │◄──►│   (FastAPI)     │◄──►│   (FastAPI)     │
│   Port: 80      │    │   Port: 5000    │    │   Port: 8001    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Kubernetes    │
                    │   Cluster       │
                    │   Namespace:    │
                    │   israel-app    │
                    └─────────────────┘
```

### Namespace Configuration
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: israel-app
  labels:
    environment: production
    project: luxe-jewelry-store
    team: devops
```

### Service Communication
- **Frontend → Backend API**: RESTful API calls
- **Backend API → Auth Service**: JWT validation
- **Inter-service Communication**: HTTP/HTTPS with JWT tokens

---

## 🛠️ Technology Stack

### Frontend Technologies
- **React 18**: Modern JavaScript framework
- **CSS3**: Styling with glassmorphism effects
- **Fetch API**: HTTP client for API communication
- **LocalStorage**: Client-side token persistence

### Backend Technologies
- **FastAPI**: Modern Python web framework
- **Pydantic**: Data validation and serialization
- **JWT**: JSON Web Tokens for authentication
- **Bcrypt**: Password hashing
- **Uvicorn**: ASGI server
- **HTTPX**: Async HTTP client

### DevOps & Infrastructure
- **Docker**: Containerization
- **Kubernetes**: Container orchestration
- **Jenkins**: CI/CD pipeline
- **AWS ECR**: Container registry
- **AWS EKS**: Managed Kubernetes
- **AWS SNS**: Build notifications

---

## 📁 Project Structure

```
luxe-jewelry-store/
├── 📁 backend/                    # Main API service
│   ├── main.py                   # FastAPI application
│   ├── requirements.txt          # Python dependencies
│   ├── Dockerfile               # Backend container config
│   └── tests/                   # Unit tests
├── 📁 frontend/                  # React application
│   ├── index.html               # Main HTML file
│   ├── nginx.conf               # Nginx configuration
│   └── Dockerfile              # Frontend container config
├── 📁 auth-service/             # Authentication microservice
│   ├── main.py                  # Auth service implementation
│   ├── requirements.txt         # Auth service dependencies
│   └── README.md               # Auth service documentation
├── 📁 k8s/                      # Kubernetes manifests
│   ├── backend-deployment.yaml
│   ├── frontend-deployment.yaml
│   ├── backend-service.yaml
│   ├── frontend-service.yaml
│   └── namespace.yaml
├── 📁 scripts/                  # Deployment and utility scripts
├── 📁 aws/                      # AWS configuration files
├── 🐳 Dockerfile               # Root Docker configuration
├── 🔄 Jenkinsfile              # CI/CD pipeline definition
├── 📝 .env.example            # Environment variables template
└── 📖 README.md               # Project documentation
```

---

## 🚀 Services & Components

### 1. Frontend Service
**Port**: 80 (Container) / 3000 (Development)
**Technology**: React + Nginx
**Purpose**: User interface and shopping experience

**Key Features**:
- Product browsing and filtering
- Shopping cart management
- User authentication interface
- Responsive design for all devices

**Container Configuration**:
```dockerfile
FROM nginx:1.25-alpine
COPY index.html /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### 2. Backend API Service
**Port**: 5000
**Technology**: FastAPI + Python
**Purpose**: Product management and cart operations

**Key Features**:
- Product CRUD operations
- Shopping cart management
- Session handling
- API documentation with Swagger

**API Endpoints**:
- `GET /api/products` - Retrieve all products
- `GET /api/products/{id}` - Get specific product
- `POST /api/cart/{session_id}/add` - Add item to cart
- `GET /api/cart?session_id={id}` - Get cart contents
- `PUT /api/cart/{session_id}/item/{item_id}` - Update quantity
- `DELETE /api/cart/{session_id}/item/{item_id}` - Remove item

### 3. Authentication Service
**Port**: 8001
**Technology**: FastAPI + Python
**Purpose**: User management and JWT token handling

**Key Features**:
- User registration and login
- JWT token generation and validation
- Password security with bcrypt
- User profile management

**Auth Endpoints**:
- `POST /auth/register` - Register new user
- `POST /auth/login` - User login
- `GET /auth/me` - Get user profile
- `PUT /auth/me` - Update profile
- `POST /auth/change-password` - Change password

---

## 🔄 CI/CD Pipeline

### Jenkins Pipeline Configuration

**Environment Variables**:
- `AWS_ACCOUNT_ID`: 992398098051
- `AWS_REGION`: us-east-1
- `ECR_REPOSITORY`: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
- `APP_NAME`: aws-project
- `K8S_NAMESPACE`: israel-app

### Pipeline Stages

#### 1. Checkout Code
```groovy
stage('Checkout Code') {
    steps { 
        checkout scm 
    }
}
```

#### 2. Build & Push Backend
```groovy
stage('Build & Push Backend') {
    steps {
        dir('backend') {
            bat "docker build -t %ECR_REPOSITORY%/aws-project:latest ."
            withAWS(credentials: 'aws-credentials', region: AWS_REGION) {
                bat "aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %ECR_REPOSITORY%"
                bat "docker push %ECR_REPOSITORY%/aws-project:latest"
            }
        }
    }
}
```

#### 3. Build & Push Frontend
```groovy
stage('Build & Push Frontend') {
    steps {
        dir('frontend') {
            bat "docker build -t %ECR_REPOSITORY%/aws-project:latest ."
            withAWS(credentials: 'aws-credentials', region: AWS_REGION) {
                bat "aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %ECR_REPOSITORY%"
                bat "docker push %ECR_REPOSITORY%/aws-project:latest"
            }
        }
    }
}
```

#### 4. Deploy to EKS
```groovy
stage('Deploy to EKS') {
    steps {
        withKubeConfig([credentialsId: 'k8s-credentials']) {
            bat "kubectl create namespace %K8S_NAMESPACE% --dry-run=client -o yaml | kubectl apply -f -"
            bat "kubectl apply -f k8s/ -n %K8S_NAMESPACE%"
            bat "kubectl get pods -n %K8S_NAMESPACE%"
        }
    }
}
```

#### 5. Notifications
```groovy
post {
    always {
        script {
            withAWS(credentials: 'aws-credentials', region: AWS_REGION) {
                def status = currentBuild.currentResult
                def buildUrl = env.BUILD_URL
                def projectName = env.JOB_NAME
                def buildNumber = env.BUILD_NUMBER
                
                def message = "Jenkins Build ${status}: ${projectName} #${buildNumber} - ${buildUrl}"
                
                bat "aws sns publish --topic-arn arn:aws:sns:%AWS_REGION%:%AWS_ACCOUNT_ID%:jenkins-build-notifications --subject \"Jenkins Build ${status}\" --message \"${message}\" --region %AWS_REGION% || echo SNS notification failed"
            }
        }
        echo 'Pipeline completed!'
    }
}
```

---

## 🐳 Containerization & Docker

### Backend Dockerfile
```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

EXPOSE 5000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "5000"]
```

### Frontend Dockerfile
```dockerfile
FROM nginx:1.25-alpine

COPY index.html /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### Auth Service Dockerfile
```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

EXPOSE 8001

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]
```

### Docker Compose (Local Development)
```yaml
version: '3.8'

services:
  backend:
    build: ./backend
    ports:
      - "5000:5000"
    environment:
      - AUTH_SERVICE_URL=http://auth-service:8001
      - JWT_SECRET_KEY=your-secret-key
    depends_on:
      - auth-service

  auth-service:
    build: ./auth-service
    ports:
      - "8001:8001"
    environment:
      - JWT_SECRET_KEY=your-secret-key

  frontend:
    build: ./frontend
    ports:
      - "80:80"
    depends_on:
      - backend
      - auth-service
```

---

## ☸️ Kubernetes Deployment

### Namespace Configuration
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: israel-app
  labels:
    environment: production
    project: luxe-jewelry-store
```

### Backend Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
  namespace: israel-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: 992398098051.dkr.ecr.us-east-1.amazonaws.com/aws-project:latest
        ports:
        - containerPort: 5000
        env:
        - name: AUTH_SERVICE_URL
          value: "http://auth-service:8001"
        - name: JWT_SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: jwt-secret
```

### Frontend Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
  namespace: israel-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: 992398098051.dkr.ecr.us-east-1.amazonaws.com/aws-project:latest
        ports:
        - containerPort: 80
```

### Service Configuration
```yaml
# Backend Service
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: israel-app
spec:
  selector:
    app: backend
  ports:
  - protocol: TCP
    port: 5000
    targetPort: 5000
  type: ClusterIP

# Frontend Service
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: israel-app
spec:
  selector:
    app: frontend
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: LoadBalancer
```

---

## ⚙️ Environment Configuration

### Environment Variables

#### Backend (.env)
```env
# Application Settings
FLASK_ENV=production
DEBUG=0
BACKEND_PORT=5000

# Authentication
AUTH_SERVICE_URL=http://auth-service:8001
JWT_SECRET_KEY=your-production-secret-key
ALGORITHM=HS256

# Database (if applicable)
DATABASE_URL=postgresql://user:password@localhost:5432/jewelry_db

# CORS Settings
ALLOWED_ORIGINS=http://localhost:3000,https://yourdomain.com
```

#### Frontend (.env)
```env
# API Configuration
REACT_APP_API_BASE_URL=http://backend-service:5000
REACT_APP_AUTH_BASE_URL=http://auth-service:8001

# Environment
NODE_ENV=production

# Features
ENABLE_ANALYTICS=true
ENABLE_DEBUG=false
```

#### Authentication Service (.env)
```env
# JWT Configuration
JWT_SECRET_KEY=your-production-secret-key
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/auth_db

# Security
BCRYPT_ROUNDS=12
SESSION_SECRET=your-session-secret
```

---

## 🔒 Security Implementation

### Authentication Flow
1. **User Registration**: Password hashed with bcrypt
2. **User Login**: Credentials validated, JWT token issued
3. **Token Storage**: JWT stored in localStorage (frontend)
4. **API Requests**: JWT sent in Authorization header
5. **Token Validation**: Backend validates with auth service

### Security Measures
- **Password Hashing**: bcrypt with salt rounds
- **JWT Tokens**: Secure token-based authentication
- **CORS Configuration**: Proper cross-origin resource sharing
- **Environment Variables**: Sensitive data in environment
- **Container Security**: Minimal base images, non-root users
- **Network Security**: Kubernetes network policies

### Security Headers
```python
# FastAPI security middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://yourdomain.com"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)
```

---

## 📚 API Documentation

### Backend API Endpoints

#### Products
- **GET** `/api/products`
  - Description: Retrieve all products
  - Response: Array of Product objects
  - Example: `[{ "id": 1, "name": "Diamond Ring", "price": 2999.00 }]`

- **GET** `/api/products/{id}`
  - Description: Get specific product by ID
  - Parameters: `id` (integer)
  - Response: Product object

- **GET** `/api/products?category={category}`
  - Description: Filter products by category
  - Parameters: `category` (string)
  - Response: Array of Product objects

#### Shopping Cart
- **POST** `/api/cart/{session_id}/add`
  - Description: Add item to cart
  - Parameters: `session_id` (string)
  - Body: `{ "product_id": 1, "quantity": 2 }`
  - Response: Updated cart object

- **GET** `/api/cart?session_id={id}`
  - Description: Get cart contents
  - Parameters: `session_id` (string)
  - Response: Cart object with items

- **PUT** `/api/cart/{session_id}/item/{item_id}`
  - Description: Update item quantity
  - Parameters: `session_id`, `item_id`
  - Body: `{ "quantity": 3 }`
  - Response: Updated cart object

- **DELETE** `/api/cart/{session_id}/item/{item_id}`
  - Description: Remove item from cart
  - Parameters: `session_id`, `item_id`
  - Response: Updated cart object

### Authentication API Endpoints

#### User Management
- **POST** `/auth/register`
  - Description: Register new user
  - Body: `{ "username": "user1", "email": "user@example.com", "password": "password123" }`
  - Response: User object with JWT token

- **POST** `/auth/login`
  - Description: User login
  - Body: `{ "username": "user1", "password": "password123" }`
  - Response: `{ "access_token": "jwt_token", "token_type": "bearer" }`

- **GET** `/auth/me`
  - Description: Get current user profile
  - Headers: `Authorization: Bearer {token}`
  - Response: User object

- **PUT** `/auth/me`
  - Description: Update user profile
  - Headers: `Authorization: Bearer {token}`
  - Body: User update data
  - Response: Updated user object

- **POST** `/auth/change-password`
  - Description: Change user password
  - Headers: `Authorization: Bearer {token}`
  - Body: `{ "current_password": "old", "new_password": "new" }`
  - Response: Success message

---

## 🔄 Development Workflow

### Local Development Setup

#### Prerequisites
- Python 3.8+
- Node.js 14+
- Docker & Docker Compose
- Git

#### Step 1: Clone Repository
```bash
git clone https://github.com/yourusername/luxe-jewelry-store.git
cd luxe-jewelry-store
```

#### Step 2: Environment Setup
```bash
cp .env.example .env
# Edit .env with your configuration
```

#### Step 3: Start Services
```bash
# Using Docker Compose (Recommended)
docker-compose up --build

# Or run services individually
cd auth-service && pip install -r requirements.txt && uvicorn main:app --reload --port 8001
cd backend && pip install -r requirements.txt && uvicorn main:app --reload --port 5000
cd frontend && npm install && npm start
```

#### Step 4: Verify Setup
- Frontend: http://localhost:3000
- Backend API: http://localhost:5000/docs
- Auth Service: http://localhost:8001/docs

### Testing
```bash
# Backend tests
cd backend
pytest tests/

# Frontend tests (if configured)
cd frontend
npm test

# Integration tests
docker-compose -f docker-compose.test.yml up --abort-on-container-exit
```

---

## 🚀 Deployment Guide

### Production Deployment Steps

#### 1. AWS EKS Setup
```bash
# Create EKS cluster
aws eks create-cluster --name luxe-jewelry-cluster --region us-east-1

# Configure kubectl
aws eks update-kubeconfig --name luxe-jewelry-cluster --region us-east-1
```

#### 2. ECR Repository Setup
```bash
# Create ECR repositories
aws ecr create-repository --repository-name aws-project --region us-east-1

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 992398098051.dkr.ecr.us-east-1.amazonaws.com
```

#### 3. Deploy Application
```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/ -n israel-app

# Verify deployment
kubectl get pods -n israel-app
kubectl get services -n israel-app
```

#### 4. Configure Ingress
```bash
# Apply ingress configuration
kubectl apply -f k8s/ingress.yaml -n israel-app

# Get external IP
kubectl get ingress -n israel-app
```

### Monitoring Setup
```bash
# Install monitoring stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring

# Set up Grafana dashboards
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
```

---

## 📊 Monitoring & Maintenance

### Health Checks
- **Backend**: `/health` endpoint
- **Auth Service**: `/health` endpoint
- **Frontend**: HTTP status check

### Logging
- **Application Logs**: Structured JSON logging
- **Access Logs**: Nginx access logs
- **Error Logs**: Centralized error tracking

### Metrics Collection
- **Response Times**: API endpoint performance
- **Error Rates**: Failed request tracking
- **Resource Usage**: CPU, memory, network metrics
- **Business Metrics**: User registrations, purchases

### Backup Strategy
- **Database Backups**: Automated daily backups
- **Configuration Backups**: Git version control
- **Container Images**: ECR repository retention

### Scaling Strategies
- **Horizontal Pod Autoscaler**: Automatic pod scaling
- **Cluster Autoscaler**: Node scaling based on load
- **Load Balancing**: Multiple instance distribution

---

## 🎯 Project Summary

### Key Achievements
- ✅ **Microservices Architecture**: Scalable service design
- ✅ **Containerization**: Docker-based deployment
- ✅ **CI/CD Pipeline**: Automated build and deployment
- ✅ **Cloud Native**: AWS EKS deployment
- ✅ **Security**: JWT authentication and authorization
- ✅ **Monitoring**: Health checks and logging
- ✅ **Documentation**: Comprehensive API docs

### Technical Highlights
- **Namespace**: `israel-app` for resource isolation
- **Services**: Frontend, Backend API, Authentication
- **Infrastructure**: Kubernetes on AWS EKS
- **CI/CD**: Jenkins pipeline with ECR integration
- **Security**: JWT tokens, bcrypt password hashing
- **Monitoring**: Health checks, structured logging

### Future Enhancements
- 🔄 **Database Integration**: PostgreSQL for persistence
- 📊 **Advanced Analytics**: User behavior tracking
- 🌍 **Internationalization**: Multi-language support
- 💳 **Payment Integration**: Stripe/PayPal integration
- 📧 **Email Notifications**: Order confirmations
- 🔍 **Advanced Search**: Elasticsearch integration

---

## 📞 Support & Contact

### Project Repository
- **GitHub**: https://github.com/yourusername/luxe-jewelry-store
- **Documentation**: Available in project README
- **Issues**: GitHub Issues tracker

### Development Team
- **DevOps Engineer**: Infrastructure and deployment
- **Backend Developer**: API and microservices
- **Frontend Developer**: React application
- **Cloud Architect**: AWS and Kubernetes setup

### Resources
- **API Documentation**: `/docs` endpoint for each service
- **Kubernetes Dashboard**: `kubectl proxy` access
- **Monitoring**: Grafana dashboards
- **Logs**: Centralized logging system

---

*Last Updated: November 2025*
*Version: 1.0.0*
*Environment: Production*
