# Check Kubernetes cluster status (PowerShell version)
Write-Host "=== Checking Kubernetes Cluster Status ===" -ForegroundColor Green

# 1. Check cluster info
Write-Host "`n1. Cluster Info:" -ForegroundColor Yellow
kubectl cluster-info

# 2. Check nodes
Write-Host "`n2. Node Status:" -ForegroundColor Yellow
kubectl get nodes -o wide

# 3. Check namespaces
Write-Host "`n3. Namespaces:" -ForegroundColor Yellow
kubectl get namespaces

# 4. Check Israel namespaces specifically
Write-Host "`n4. Israel Namespaces:" -ForegroundColor Yellow
kubectl get namespaces | Where-Object { $_.Name -like "*israel*" }

# 5. Check pods in Israel namespaces
Write-Host "`n5. Pods in Israel namespaces:" -ForegroundColor Yellow
kubectl get pods -n israel-jenkins
kubectl get pods -n israel-app
kubectl get pods -n israel-argo

# 6. Check Jenkins specifically
Write-Host "`n6. Jenkins Deployment Status:" -ForegroundColor Yellow
kubectl get deployment jenkins -n israel-jenkins 2>$null

# 7. Check services
Write-Host "`n7. Services in Israel namespaces:" -ForegroundColor Yellow
kubectl get services -n israel-jenkins 2>$null
kubectl get services -n israel-app 2>$null

# 8. Check system pods
Write-Host "`n8. System Pods:" -ForegroundColor Yellow
kubectl get pods -n kube-system

Write-Host "`n=== Status Check Complete ===" -ForegroundColor Green
