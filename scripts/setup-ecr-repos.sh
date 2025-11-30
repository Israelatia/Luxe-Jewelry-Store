#!/bin/bash
# Create ECR repositories for Luxe Jewelry Store
set -e

AWS_ACCOUNT_ID="992398098051"
AWS_REGION="us-east-1"

echo "🔧 Creating ECR repositories..."

# Create backend repository
aws ecr create-repository \
    --repository-name luxe-jewelry-backend \
    --region $AWS_REGION \
    --image-scanning-configuration scanOnPush=true \
    --image-tag-mutability MUTABLE || echo "Backend repository may already exist"

# Create frontend repository  
aws ecr create-repository \
    --repository-name luxe-jewelry-frontend \
    --region $AWS_REGION \
    --image-scanning-configuration scanOnPush=true \
    --image-tag-mutability MUTABLE || echo "Frontend repository may already exist"

echo "✅ ECR repositories created!"
echo ""
echo "📋 Repository URIs:"
echo "Backend:  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/luxe-jewelry-backend"
echo "Frontend: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/luxe-jewelry-frontend"
echo ""
echo "🚀 You can now run your Jenkins pipeline!"
