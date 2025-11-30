#!/bin/bash
# Simple AWS Secrets Manager setup for EKS
set -e

AWS_REGION="us-east-1"
NAMESPACE="israel-app"

echo "🔐 Setting up AWS Secrets Manager..."

# Install Secrets Store CSI Driver
echo "Installing CSI Driver..."
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install -n kube-system csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver

# Install AWS Provider
echo "Installing AWS Provider..."
kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml

# Create sample secret
echo "Creating sample secret..."
aws secretsmanager create-secret \
    --name "luxe-jewelry-db-password" \
    --secret-string "SecurePassword123!" \
    --region $AWS_REGION || echo "Secret exists"

# Create SecretProviderClass
echo "Creating SecretProviderClass..."
cat > secretproviderclass.yaml << EOF
apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
kind: SecretProviderClass
metadata:
  name: aws-secrets
  namespace: $NAMESPACE
spec:
  provider: aws
  parameters:
    objects: |
      - objectName: "luxe-jewelry-db-password"
        objectType: "secretsmanager"
EOF

kubectl apply -f secretproviderclass.yaml

# Example pod
echo "Creating example pod..."
cat > example-pod.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: app-with-secrets
  namespace: $NAMESPACE
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: secrets-store
      mountPath: "/mnt/secrets"
  volumes:
  - name: secrets-store
    csi:
      driver: secrets-store.csi.k8s.io
      volumeAttributes:
        secretProviderClass: "aws-secrets"
EOF

kubectl apply -f example-pod.yaml

echo "✅ Setup complete!"
echo "Check secrets: kubectl exec -it app-with-secrets -n $NAMESPACE -- ls /mnt/secrets"

rm -f secretproviderclass.yaml example-pod.yaml
