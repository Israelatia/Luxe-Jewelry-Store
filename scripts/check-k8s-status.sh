#!/bin/bash
# Check Kubernetes cluster status
set -e

echo "=== Checking Kubernetes Cluster Status ==="

# 1. Check cluster info
echo "1. Cluster Info:"
kubectl cluster-info

# 2. Check nodes
echo -e "\n2. Node Status:"
kubectl get nodes -o wide

# 3. Check namespaces
echo -e "\n3. Namespaces:"
kubectl get namespaces

# 4. Check pods in all namespaces
echo -e "\n4. Pods in all namespaces:"
kubectl get pods --all-namespaces

# 5. Check services
echo -e "\n5. Services in all namespaces:"
kubectl get services --all-namespaces

# 6. Check Jenkins specifically
echo -e "\n6. Jenkins Deployment Status:"
kubectl get deployment jenkins -n israel-jenkins
kubectl get pods -n israel-jenkins -l app=jenkins

# 7. Check if Jenkins is accessible
echo -e "\n7. Jenkins Service:"
kubectl get service jenkins -n israel-jenkins

# 8. Check system pods
echo -e "\n8. System Pods:"
kubectl get pods -n kube-system

# 9. Check events
echo -e "\n9. Recent Events:"
kubectl get events --sort-by=.metadata.creationTimestamp -n israel-jenkins | tail -10

echo -e "\n=== Status Check Complete ==="
