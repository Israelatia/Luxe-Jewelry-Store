# AWS Migration Guide for Luxe Jewelry Store

## Overview
This guide helps you migrate your Jenkins pipeline and applications to AWS services.

## 1. ECR Repository Setup

### Create ECR Repositories
```bash
cd scripts
chmod +x create-ecr-repos.sh
./create-ecr-repos.sh
```

### What this does:
- Creates ECR repositories for frontend and backend
- Enables image scanning on push
- Logs you into ECR

## 2. EC2 Auto Scaling Group with Jenkins Agents

### Create EC2 Agent AMI
1. Launch an EC2 instance (Amazon Linux 2, t3.medium)
2. Connect and run:
```bash
cd scripts
chmod +x setup-ec2-agent.sh
./setup-ec2-agent.sh
```
3. Download agent.jar from your Jenkins server
4. Create AMI from the instance

### Create Launch Template
- AMI: The one you just created
- Instance type: t3.medium
- IAM role with ECR access
- User data: Start Jenkins agent

### Create Auto Scaling Group
- Min: 0, Desired: 1, Max: 3
- Use the launch template

## 3. EC2 Instance Backup

### Manual Snapshot
1. Go to EC2 Console
2. Select instance
3. Right-click > Create Snapshot
4. Add descriptive name

### Automated Backup
```bash
cd scripts
chmod +x backup-ec2-instances.sh
./backup-ec2-instances.sh
```

## 4. Static Website on S3 with CloudFront (Bonus)

### Setup S3 Bucket
```bash
cd scripts
chmod +x setup-s3-static.sh
./setup-s3-static.sh
```

### Upload Files
```bash
aws s3 sync frontend/build/ s3://your-bucket-name/
```

### Create CloudFront Distribution
1. Go to CloudFront Console
2. Create Distribution
3. Origin: S3 bucket
4. Enable HTTPS

## 5. Migrate to EKS

### Create EKS Cluster
```bash
# Create cluster
aws eks create-cluster --name luxe-jewelry-cluster --region us-east-1 --nodegroup-name standard-nodes --node-type t3.medium --nodes 2

# Update kubeconfig
aws eks update-kubeconfig --name luxe-jewelry-cluster --region us-east-1
```

### Create Namespaces
```bash
cd scripts
chmod +x create-eks-namespaces.sh
./create-eks-namespaces.sh
```

### Move Jenkins to EKS
1. Install Jenkins Helm chart
2. Configure to use EKS
3. Update Jenkinsfile to use EKS

## 6. Update Jenkins Pipeline

Your Jenkinsfile now supports:
- Agent type selection (Kubernetes/EC2)
- ECR integration
- SNS notifications
- EKS deployment

## 7. SNS Notifications

### Create SNS Topic
```bash
cd scripts
chmod +x create-sns-topic.sh
./create-sns-topic.sh
```

### Subscribe to Notifications
```bash
aws sns subscribe --topic-arn arn:aws:sns:us-east-1:992398098051:jenkins-build-notifications --protocol email --notification-endpoint your-email@example.com
```

## 8. AWS Secrets Manager Integration

### Setup CSI Driver
```bash
cd scripts
chmod +x setup-secrets-manager.sh
./setup-secrets-manager.sh
```

### Create Secrets
```bash
aws secretsmanager create-secret --name "luxe-jewelry-store/db-password" --secret-string "your-password"
```

### Use in Kubernetes
Create SecretProviderClass and mount in pods.

## 9. Cleanup

After migration:
1. Delete old EC2 instances
2. Remove Minikube
3. Clean up unused resources

## Quick Start Commands

```bash
# 1. Make all scripts executable
cd scripts
chmod +x *.sh

# 2. Run setup in order
./create-ecr-repos.sh
./create-eks-namespaces.sh
./create-sns-topic.sh
./setup-secrets-manager.sh
./setup-s3-static.sh
./backup-ec2-instances.sh
```

## Important Notes

- Update your AWS credentials in Jenkins
- Replace placeholder values (email, passwords)
- Test each step before proceeding
- Monitor costs in AWS Console

## Troubleshooting

### ECR Issues
- Check IAM permissions
- Verify AWS credentials

### EKS Issues
- Ensure kubectl is configured
- Check node status

### SNS Issues
- Verify topic ARN
- Check subscriptions
