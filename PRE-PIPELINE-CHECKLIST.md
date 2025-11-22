# Pre-Pipeline Checklist

## Before You Commit & Run Pipeline:

### 1. Update These Values First:
- **GitHub Token**: Update in `deploy-codepipeline.sh`
- **Key Pair Name**: Update in `create-launch-template.sh` and `create-eks-cluster.sh`
- **Subnet IDs**: Update in AWS scripts
- **Security Group IDs**: Update in AWS scripts
- **Jenkins URL**: Update in `disable-jenkins-job.sh`

### 2. Verify AWS CLI is Configured:
```powershell
aws sts get-caller-identity
```

### 3. Check kubectl is Connected:
```powershell
kubectl cluster-info
```

### 4. Git Commands:
```bash
git add .
git commit -m "Add complete AWS migration setup"
git push origin main
```

### 5. Run Pipeline Order:
```bash
# First, create AWS resources
cd scripts
chmod +x *.sh
./create-iam-roles.sh
./create-ecr-repos.sh

# Then create EKS cluster (takes 15-20 minutes)
./create-eks-cluster.sh

# Apply Kubernetes resources
kubectl apply -f ../k8s/namespaces.yaml
kubectl apply -f ../k8s/secrets-provider-class.yaml

# Create secrets
./create-secrets.sh

# Deploy CodePipeline
./deploy-codepipeline.sh

# Optional: Setup ArgoCD
./setup-argocd.sh
```

### 6. Monitor Pipeline:
- **Jenkins**: http://your-jenkins-server:8080
- **AWS CodePipeline**: https://console.aws.amazon.com/codesuite/codepipeline/
- **EKS**: `kubectl get pods -n israel-app`

### 7. Test Both Agent Types:
- Jenkins with `AGENT_TYPE=kubernetes`
- Jenkins with `AGENT_TYPE=ec2`

## Expected Timeline:
- **IAM/ECR**: 2-3 minutes
- **EKS Cluster**: 15-20 minutes
- **CodePipeline**: 5-10 minutes
- **Total**: ~30-40 minutes

## Troubleshooting:
- If EKS creation fails, check IAM roles
- If CodeBuild fails, check GitHub token
- If secrets don't mount, check CSI driver

Good luck! 🚀
