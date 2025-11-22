#!/bin/bash
# Run all setup scripts in order
set -e

echo "Starting complete AWS setup for Luxe Jewelry Store..."

# Make all scripts executable
chmod +x *.sh

# 1. Create IAM roles first
echo "Step 1: Creating IAM roles..."
./create-iam-roles.sh

# 2. Create ECR repositories
echo "Step 2: Creating ECR repositories..."
./create-ecr-repos.sh

# 3. Create EKS cluster (takes 15-20 minutes)
echo "Step 3: Creating EKS cluster (this will take 15-20 minutes)..."
./create-eks-cluster.sh

# 4. Apply Kubernetes resources
echo "Step 4: Applying Kubernetes resources..."
kubectl apply -f ../k8s/namespaces.yaml
kubectl apply -f ../k8s/secret-provider-class.yaml
kubectl apply -f ../k8s/jenkins-deployment.yaml

# 5. Create SNS topic
echo "Step 5: Creating SNS topic..."
./create-sns-topic.sh

# 6. Setup Secrets Manager
echo "Step 6: Setting up Secrets Manager..."
./setup-secrets-manager.sh

# 7. Create Launch Template
echo "Step 7: Creating Launch Template..."
./create-launch-template.sh

# 8. Create Auto Scaling Group
echo "Step 8: Creating Auto Scaling Group..."
./create-autoscaling-group.sh

# 9. Setup S3 and CloudFront (optional)
echo "Step 9: Setting up S3 static website (optional)..."
./setup-s3-static.sh

# 10. Create CloudFront distribution (optional)
echo "Step 10: Creating CloudFront distribution (optional)..."
./create-cloudfront.sh

echo "Setup completed!"
echo ""
echo "Next steps:"
echo "1. Update placeholder values in scripts (key pairs, subnets, etc.)"
echo "2. Create secrets in AWS Secrets Manager"
echo "3. Subscribe to SNS topic"
echo "4. Test Jenkins pipeline"
echo "5. Deploy your application"
