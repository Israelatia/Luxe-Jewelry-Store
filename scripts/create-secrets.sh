#!/bin/bash
# Create secrets in AWS Secrets Manager
set -e

AWS_REGION="us-east-1"

echo "Creating secrets in AWS Secrets Manager..."

# Create database password secret
aws secretsmanager create-secret \
    --name "luxe-jewelry-store/db-password" \
    --description "Database password for Luxe Jewelry Store" \
    --secret-string "SecurePassword123!" \
    --region $AWS_REGION || echo "Secret may already exist"

# Create API key secret
aws secretsmanager create-secret \
    --name "luxe-jewelry-store/api-key" \
    --description "API key for Luxe Jewelry Store" \
    --secret-string "luxe-api-key-$(openssl rand -hex 16)" \
    --region $AWS_REGION || echo "Secret may already exist"

# Create JWT secret
aws secretsmanager create-secret \
    --name "luxe-jewelry-store/jwt-secret" \
    --description "JWT secret for authentication" \
    --secret-string "jwt-secret-$(openssl rand -hex 32)" \
    --region $AWS_REGION || echo "Secret may already exist"

echo "Secrets created successfully!"
echo "Note: Update the secret values with your actual secrets"
