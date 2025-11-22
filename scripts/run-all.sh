#!/bin/bash
# Run all simple scripts

echo "Setting up ECR..."
./simple-setup-ecr.sh

echo "Setting up SNS..."
./simple-sns.sh

echo "Creating secrets..."
./simple-secrets.sh

echo "Deploying to EKS..."
./simple-jenkins-eks.sh

echo "Done! Check AWS Console for resources."
