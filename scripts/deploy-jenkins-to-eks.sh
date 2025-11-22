#!/bin/bash
# Deploy Jenkins to EKS

set -e

AWS_REGION="us-east-1"
CLUSTER_NAME="luxe-cluster"
NAMESPACE="israel-jenkins"

echo "Creating namespace: $NAMESPACE"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create Jenkins service account with IAM role
echo "Creating IAM service account for Jenkins"
eksctl create iamserviceaccount \
  --cluster $CLUSTER_NAME \
  --namespace $NAMESPACE \
  --name jenkins \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonSNSFullAccess \
  --attach-policy-arn arn:aws:iam::aws:policy/SecretsManagerReadWrite \
  --approve \
  --override-existing-serviceaccounts

# Deploy Jenkins
echo "Deploying Jenkins to EKS"
kubectl apply -f k8s/jenkins-deployment.yaml -n $NAMESPACE
kubectl apply -f k8s/jenkins-service.yaml -n $NAMESPACE
kubectl apply -f k8s/jenkins-pvc.yaml -n $NAMESPACE

# Wait for Jenkins to be ready
echo "Waiting for Jenkins to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/jenkins -n $NAMESPACE

# Get Jenkins URL
JENKINS_URL=$(kubectl get service jenkins -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Jenkins deployed successfully!"
echo "Access Jenkins at: http://$JENKINS_URL"

# Get initial admin password
echo "Getting initial admin password..."
kubectl exec -n $NAMESPACE deployment/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
