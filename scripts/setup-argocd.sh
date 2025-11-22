#!/bin/bash
# Setup ArgoCD for GitOps deployment (Optional)
set -e

echo "Setting up ArgoCD for GitOps deployment..."

# Create ArgoCD namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
echo "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Get ArgoCD admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "ArgoCD setup completed!"
echo "Username: admin"
echo "Password: $ARGOCD_PASSWORD"
echo "Access ArgoCD: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "Then open: http://localhost:8080"

# Create ArgoCD application for Luxe Jewelry Store
cat > argocd-app.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: luxe-jewelry-store
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/Israelatia/Luxe-Jewelry-Store.git
    targetRevision: HEAD
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: israel-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

kubectl apply -f argocd-app.yaml
echo "ArgoCD application created!"
