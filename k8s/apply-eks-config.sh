#!/bin/bash

# Apply namespaces and network policies
echo "Applying namespaces and network policies..."
kubectl apply -f k8s/namespaces.yaml

# Create storage class for EBS if it doesn't exist
if ! kubectl get storageclass gp2 &> /dev/null; then
    echo "Creating EBS storage class..."
    cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp2
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
  fsType: ext4
  encrypted: "true"
EOF
fi

# Apply RBAC configuration
echo "Applying RBAC configuration..."
kubectl apply -f k8s/jenkins-rbac.yaml

# Apply Jenkins agent configuration
echo "Applying Jenkins agent configuration..."
kubectl apply -f k8s/jenkins-agent-config.yaml

# Apply Jenkins deployment
echo "Applying Jenkins deployment..."
kubectl apply -f k8s/jenkins-deployment.yaml

# Create an ingress for Jenkins
echo "Creating Jenkins ingress..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: jenkins
  namespace: israel-jenkins
  annotations:
    kubernetes.io/ingress.class: "alb"
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 443}, {"HTTP": 80}]'
    alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
spec:
  rules:
  - http:
      paths:
      - path: /jenkins
        pathType: Prefix
        backend:
          service:
            name: jenkins
            port:
              number: 8080
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ssl-redirect
            port:
              name: use-annotation
EOF

echo "Setup complete!"
echo "To get the Jenkins admin password, run:"
echo "kubectl exec -n israel-jenkins -it deploy/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword"
