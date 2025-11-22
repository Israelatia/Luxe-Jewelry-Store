#!/bin/bash
# Create ECR repositories for Luxe Jewelry Store
set -e

AWS_ACCOUNT_ID="992398098051"
AWS_REGION="us-east-1"
REPOS=("luxe-jewelry-store-frontend" "luxe-jewelry-store-backend")

echo "Creating ECR repositories..."

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Create repositories
for repo in "${REPOS[@]}"; do
    echo "Creating repository: $repo"
    aws ecr create-repository \
        --repository-name $repo \
        --image-scanning-configuration scanOnPush=true \
        --region $AWS_REGION || echo "Repository $repo already exists"
done

echo "ECR repositories created successfully!"
