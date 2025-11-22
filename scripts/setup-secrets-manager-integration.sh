#!/bin/bash
# Setup AWS Secrets Manager integration with EKS

set -e

AWS_REGION="us-east-1"
CLUSTER_NAME="luxe-cluster"

echo "Setting up AWS Secrets Manager integration with EKS..."

# Install Secrets Store CSI Driver and ASCP provider
echo "Installing Secrets Store CSI Driver..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/v1.3.0/deploy/rbac-secretproviderclass.yaml

# Install AWS provider
echo "Installing AWS Secrets and Configuration Provider (ASCP)..."
helm repo add aws-secrets-manager https://aws.github.io/secrets-store-csi-driver-provider-aws
helm repo update
helm install -n kube-system secrets-store-csi-driver-provider-aws aws-secrets-manager/secrets-store-csi-driver-provider-aws

# Create secrets in Secrets Manager
echo "Creating secrets in AWS Secrets Manager..."

# Database credentials
aws secretsmanager create-secret \
  --name "luxe-app/database-credentials" \
  --description "Database credentials for luxe app" \
  --secret-string '{"username":"admin","password":"your-password","host":"database.example.com","port":"5432"}' \
  --region $AWS_REGION || echo "Secret already exists"

# API keys
aws secretsmanager create-secret \
  --name "luxe-app/api-keys" \
  --description "API keys for external services" \
  --secret-string '{"stripe_key":"sk_test_123","aws_access_key":"AKIAIOSFODNN7EXAMPLE","aws_secret_key":"wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"}' \
  --region $AWS_REGION || echo "Secret already exists"

# Create SecretProviderClass
echo "Creating SecretProviderClass..."
kubectl apply -f - <<EOF
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: luxe-app-secrets
  namespace: israel-app
spec:
  provider: aws
  parameters:
    objects: |
      - objectName: "luxe-app/database-credentials"
        objectType: "secretsmanager"
        jmesPath:
          - path: "username"
            objectAlias: "db_username"
          - path: "password"
            objectAlias: "db_password"
      - objectName: "luxe-app/api-keys"
        objectType: "secretsmanager"
        jmesPath:
          - path: "stripe_key"
            objectAlias: "stripe_key"
  secretObjects:
  - secretName: luxe-app-secrets
    type: Opaque
    data:
    - objectName: db_username
      key: DB_USERNAME
    - objectName: db_password
      key: DB_PASSWORD
    - objectName: stripe_key
      key: STRIPE_KEY
EOF

# Update deployment to mount secrets
echo "Updating deployments to use secrets..."
kubectl patch deployment luxe-backend -n israel-app -p '{"spec":{"template":{"spec":{"volumes":[{"name":"secrets-store","csi":{"driver":"secrets-store.csi.k8s.io","readOnly":true,"volumeAttributes":{"secretProviderClass":"luxe-app-secrets"}}}]}}}}'

kubectl patch deployment luxe-backend -n israel-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"backend","volumeMounts":[{"name":"secrets-store","mountPath":"/mnt/secrets-store","readOnly":true}],"env":[{"name":"DB_USERNAME","valueFrom":{"secretKeyRef":{"name":"luxe-app-secrets","key":"DB_USERNAME"}}},{"name":"DB_PASSWORD","valueFrom":{"secretKeyRef":{"name":"luxe-app-secrets","key":"DB_PASSWORD"}}},{"name":"STRIPE_KEY","valueFrom":{"secretKeyRef":{"name":"luxe-app-secrets","key":"STRIPE_KEY"}}}]}]}}}}'

echo "AWS Secrets Manager integration completed!"
echo "Secrets are now available as Kubernetes secrets and mounted files in pods."
