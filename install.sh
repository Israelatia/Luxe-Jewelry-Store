#!/bin/bash

# Create namespace if it doesn't exist
kubectl create namespace demo-app --dry-run=client -o yaml | kubectl apply -f -

# Install the Helm chart
helm upgrade --install luxe-jewelry ./luxe-jewelry-chart -n demo-app --create-namespace

# Wait for pods to be ready
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=luxe-jewelry -n demo-app --timeout=300s

# Get the Minikube IP
MINIKUBE_IP=$(minikube ip)

# Add host entry for Ingress
if ! grep -q "luxe-jewelry.local" /etc/hosts; then
  echo "Adding host entry for luxe-jewelry.local..."
  echo "$MINIKUBE_IP luxe-jewelry.local" | sudo tee -a /etc/hosts
fi

# Get the NodePort for the frontend service
NODE_PORT=$(kubectl get svc -n demo-app luxe-jewelry-frontend -o jsonpath='{.spec.ports[0].nodePort}')

# Print access information
echo ""
echo "========================================"
echo " Luxe Jewelry Store Deployment Complete "
echo "========================================"
echo ""
echo "Access the application using one of the following methods:"
echo ""
echo "1. Via NodePort:"
echo "   Frontend: http://$MINIKUBE_IP:$NODE_PORT"
echo ""
echo "2. Via Ingress (if enabled):"
echo "   Frontend: http://luxe-jewelry.local"
echo "   API:      http://luxe-jewelry.local/api"
echo ""
echo "3. Via port-forwarding:"
echo "   kubectl port-forward svc/luxe-jewelry-frontend -n demo-app 8080:80"
echo "   Then open: http://localhost:8080"
echo ""
echo "To view all resources:"
echo "   kubectl get all -n demo-app"
echo ""
echo "To view logs:"
echo "   Backend:  kubectl logs -l app.kubernetes.io/component=backend -n demo-app"
echo "   Frontend: kubectl logs -l app.kubernetes.io/component=frontend -n demo-app"
echo ""
echo "To uninstall:"
echo "   helm uninstall luxe-jewelry -n demo-app"
