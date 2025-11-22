#!/bin/bash
# Create EKS Cluster
set -e

AWS_REGION="us-east-1"
CLUSTER_NAME="luxe-jewelry-cluster"
NODE_TYPE="t3.medium"
NODE_COUNT=2

echo "Creating EKS Cluster: $CLUSTER_NAME"

# Create cluster (this takes 15-20 minutes)
aws eks create-cluster \
    --name $CLUSTER_NAME \
    --region $AWS_REGION \
    --version "1.27" \
    --kubernetes-network-config '{"ipFamily":"ipv4","serviceIpv4Cidr":"10.100.0.0/16"}' \
    --role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/AmazonEKSClusterRole \
    --resources-vpc-config '{"subnetIds":["subnet-xxxxxxxx","subnet-yyyyyyyy"],"endpointPublicAccess":true,"endpointPrivateAccess":false}'

# Wait for cluster to be active
echo "Waiting for cluster to become active..."
aws eks wait cluster-active --name $CLUSTER_NAME --region $AWS_REGION

# Create node group
aws eks create-nodegroup \
    --cluster-name $CLUSTER_NAME \
    --nodegroup-name standard-nodes \
    --region $AWS_REGION \
    --node-type $NODE_TYPE \
    --nodes $NODE_COUNT \
    --subnets "subnet-xxxxxxxx,subnet-yyyyyyyy" \
    --instance-types $NODE_TYPE \
    --ami-type AL2_x86_64 \
    --ssh-key-name your-key-pair \
    --scaling-config minSize=1,maxSize=3,desiredSize=$NODE_COUNT

# Wait for node group to be active
echo "Waiting for node group to become active..."
aws eks wait nodegroup-active --cluster-name $CLUSTER_NAME --nodegroup-name standard-nodes --region $AWS_REGION

# Update kubeconfig
aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION

echo "EKS Cluster created successfully!"
echo "Run: kubectl get nodes to verify"
