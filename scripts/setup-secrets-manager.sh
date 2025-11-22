#!/bin/bash
# Setup AWS Secrets Manager for Kubernetes
set -e

AWS_REGION="us-east-1"

echo "Setting up AWS Secrets Manager integration..."

# Install Secrets Store CSI Driver
echo "Installing Secrets Store CSI Driver..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/v0.0.26/deploy/rbac-secretproviderclass.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/v0.0.26/deploy/csidriver.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/v0.0.26/deploy/secrets-store.csi.x86_64.yaml

# Install AWS Provider
echo "Installing AWS Secrets and Configuration Provider..."
kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider.yaml

# Example: Create a secret in Secrets Manager
echo "Creating example secret in Secrets Manager..."
aws secretsmanager create-secret \
    --name "luxe-jewelry-store/db-password" \
    --description "Database password for Luxe Jewelry Store" \
    --secret-string "your-secure-password-here" \
    --region $AWS_REGION || echo "Secret may already exist"

echo "AWS Secrets Manager integration setup completed!"
echo "Next steps:"
echo "1. Create your secrets in AWS Secrets Manager"
echo "2. Create SecretProviderClass manifests"
echo "3. Update your deployments to mount secrets"
