# Final Migration Steps - AWS Services Integration

## Section 1: AWS Secrets Manager Integration

### 1.1 Install Secrets Store CSI Driver
```bash
# Install the CSI driver
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/v0.0.26/deploy/rbac-secretproviderclass.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/v0.0.26/deploy/csidriver.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/v0.0.26/deploy/secrets-store.csi.x86_64.yaml

# Install AWS provider
kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider.yaml
```

### 1.2 Create Secrets in AWS Secrets Manager
```bash
cd scripts
chmod +x create-secrets.sh
./create-secrets.sh
```

### 1.3 Apply SecretProviderClass
```bash
kubectl apply -f k8s/secrets-provider-class.yaml
```

### 1.4 Update Deployments to Use Secrets
Add to your deployment YAMLs:
```yaml
volumes:
- name: secrets-store-inline
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: "aws-secrets"
volumeMounts:
- name: secrets-store-inline
  mountPath: "/mnt/secrets"
  readOnly: true
```

## Section 2: Migrate CI/CD to AWS CodePipeline and CodeBuild

### 2.1 Deploy CodePipeline Infrastructure
```bash
cd scripts
chmod +x deploy-codepipeline.sh
./deploy-codepipeline.sh
```

### 2.2 Update GitHub Token
You need to:
1. Create a GitHub Personal Access Token
2. Update the CloudFormation stack with your token:
```bash
aws cloudformation update-stack \
    --stack-name luxe-jewelry-pipeline \
    --template-file ../aws/codepipeline.yaml \
    --parameters ParameterKey=GitHubToken,ParameterValue=YOUR_TOKEN \
    --capabilities CAPABILITY_IAM \
    --region us-east-1
```

### 2.3 Disable Jenkins Job
```bash
chmod +x disable-jenkins-job.sh
./disable-jenkins-job.sh
```

### 2.4 Setup ArgoCD (Optional - Recommended)
```bash
chmod +x setup-argocd.sh
./setup-argocd.sh
```

## Complete Migration Commands

```bash
# 1. Secrets Manager Integration
cd scripts
./create-secrets.sh
kubectl apply -f ../k8s/secrets-provider-class.yaml

# 2. CodePipeline Setup
./deploy-codepipeline.sh

# 3. Disable Jenkins
./disable-jenkins-job.sh

# 4. Optional: Setup ArgoCD for GitOps
./setup-argocd.sh
```

## What Gets Created:

### AWS Resources:
- **S3 Bucket**: Pipeline artifacts storage
- **CodePipeline**: 3-stage pipeline (Source → Build → Deploy)
- **CodeBuild Projects**: 
  - Backend build & push to ECR
  - Frontend build & push to ECR
  - Deploy to EKS
- **IAM Roles**: Proper permissions for all services
- **SNS Topic**: Pipeline notifications

### Kubernetes Resources:
- **SecretProviderClass**: Mounts AWS secrets as files
- **ArgoCD**: GitOps deployment (optional)

## Benefits:
- **Fully managed CI/CD** on AWS
- **Cost-effective** with pay-as-you-go
- **Scalable** builds
- **Integrated notifications**
- **GitOps** with ArgoCD (optional)
- **Secure secret management**

## Post-Migration:
1. Monitor pipeline executions
2. Test deployments
3. Verify secrets are mounted correctly
4. Clean up old Jenkins resources
5. Update documentation

## Troubleshooting:
- Check CloudFormation logs for stack creation issues
- Verify GitHub token has proper permissions
- Ensure EKS cluster is accessible from CodeBuild
- Check IAM role permissions
- Monitor SNS notifications
