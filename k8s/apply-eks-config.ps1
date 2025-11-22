# Apply namespaces and network policies
Write-Host "Applying namespaces and network policies..."
kubectl apply -f .\k8s\namespaces.yaml

# Create storage class for EBS if it doesn't exist
$storageClassExists = kubectl get storageclass gp2 --no-headers -o name 2>$null
if (-not $storageClassExists) {
    Write-Host "Creating EBS storage class..."
    @"
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
"@ | kubectl apply -f -
}

# Apply RBAC configuration
Write-Host "Applying RBAC configuration..."
kubectl apply -f .\k8s\jenkins-rbac.yaml

# Apply Jenkins agent configuration
Write-Host "Applying Jenkins agent configuration..."
kubectl apply -f .\k8s\jenkins-agent-config.yaml

# Apply Jenkins deployment
Write-Host "Applying Jenkins deployment..."
kubectl apply -f .\k8s\jenkins-deployment.yaml

# Create an ingress for Jenkins
Write-Host "Creating Jenkins ingress..."
@"
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
"@ | kubectl apply -f -

Write-Host "`nSetup complete!"
Write-Host "To get the Jenkins admin password, run:"
Write-Host "kubectl exec -n israel-jenkins -it deploy/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword"
Write-Host "`nNote: It may take a few minutes for the ALB to be provisioned and the DNS to be available."
