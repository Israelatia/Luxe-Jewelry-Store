# Final Checklist - What's Left to Do

## ✅ Already Done:
- [x] Jenkinsfile updated with agent selection
- [x] ECR scripts created
- [x] Namespaces YAML created
- [x] SNS notifications configured
- [x] Backup scripts ready
- [x] S3 static website script
- [x] Jenkins deployment for EKS

## ❌ Still Need to Do:

### 1. Create EKS Cluster
```bash
aws eks create-cluster --name luxe-jewelry-cluster --region us-east-1 --nodegroup-name standard-nodes --node-type t3.medium --nodes 2
aws eks update-kubeconfig --name luxe-jewelry-cluster --region us-east-1
```

### 2. Apply Kubernetes Resources
```bash
kubectl apply -f k8s/namespaces.yaml
kubectl apply -f k8s/secret-provider-class.yaml
kubectl apply -f k8s/jenkins-deployment.yaml
```

### 3. Create AWS Resources
```bash
cd scripts
./create-ecr-repos.sh
./create-sns-topic.sh
./setup-secrets-manager.sh
```

### 4. Create Secrets in AWS Secrets Manager
```bash
aws secretsmanager create-secret --name "luxe-jewelry-store/db-password" --secret-string "your-password"
aws secretsmanager create-secret --name "luxe-jewelry-store/api-key" --secret-string "your-api-key"
```

### 5. Update Jenkins Configuration
- Add AWS credentials to Jenkins
- Update Jenkins URL in agent configuration
- Test pipeline with both Kubernetes and EC2 agents

### 6. Optional: Static Website (Bonus)
```bash
./setup-s3-static.sh
aws s3 sync frontend/build/ s3://your-bucket-name/
```

### 7. Cleanup Old Resources
- Delete old EC2 instances after migration
- Remove Minikube cluster
- Clean up unused resources

## Quick Run Commands:
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run AWS setup
cd scripts
./create-ecr-repos.sh
./create-sns-topic.sh

# Apply K8s resources
kubectl apply -f k8s/namespaces.yaml
kubectl apply -f k8s/secret-provider-class.yaml

# Test pipeline
# Trigger Jenkins build with AGENT_TYPE=kubernetes
# Then with AGENT_TYPE=ec2
```

## After Migration:
1. Monitor pipeline runs
2. Verify ECR repositories have images
3. Check SNS notifications work
4. Test secrets mounting in pods
5. Verify application deployment on EKS

That's it! You're ready to complete the migration.
