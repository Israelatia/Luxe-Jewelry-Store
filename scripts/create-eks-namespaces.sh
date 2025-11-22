#!/bin/bash
# Create EKS namespaces with your name prefix
set -e

# Replace 'yourname' with your actual name/nickname
YOUR_NAME="israel"

NAMESPACES=("${YOUR_NAME}-jenkins" "${YOUR_NAME}-app" "${YOUR_NAME}-argo")

echo "Creating EKS namespaces..."

for ns in "${NAMESPACES[@]}"; do
    echo "Creating namespace: $ns"
    kubectl create namespace $ns --dry-run=client -o yaml | kubectl apply -f -
done

echo "Namespaces created successfully!"
