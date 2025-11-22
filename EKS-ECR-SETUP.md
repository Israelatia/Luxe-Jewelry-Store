# EKS and ECR Integration Guide

This guide provides instructions for setting up and using the Jenkins pipeline with Amazon EKS and ECR.

## Prerequisites

1. AWS Account with appropriate permissions
2. AWS CLI configured with credentials
3. `kubectl` installed and configured
4. `aws-iam-authenticator` installed
5. Jenkins with necessary plugins:
   - AWS Credentials Plugin
   - Pipeline AWS Plugin
   - Kubernetes CLI Plugin
   - Docker Pipeline Plugin

## Setup Instructions

### 1. Create ECR Repositories

Create ECR repositories for the frontend and backend:

```bash
aws ecr create-repository --repository-name luxe-jewelry-store-backend
aws ecr create-repository --repository-name luxe-jewelry-store-frontend
```

### 2. Create EKS Cluster

Create an EKS cluster using the AWS Management Console or AWS CLI:

```bash
eksctl create cluster \
  --name luxe-jewelry-eks-cluster \
  --region ${AWS_REGION} \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3
```

### 3. Configure Jenkins

1. Add AWS credentials to Jenkins:
   - Go to Jenkins > Credentials > System > Global credentials > Add Credentials
   - Add AWS credentials with ID `aws-credentials`
   - Add Docker Hub credentials with ID `docker-hub`

2. Update Jenkinsfile environment variables:
   - Set `AWS_ACCOUNT_ID` to your AWS account ID
   - Set `AWS_REGION` to your AWS region (e.g., `us-west-2`)

### 4. Update Kubernetes Configuration

1. Update the following files with your AWS account ID and region:
   - `k8s/backend-deployment.yaml`
   - `k8s/frontend-deployment.yaml`

### 5. Configure IAM Roles

Create an IAM role for the worker nodes with the following policies:
- AmazonEKSWorkerNodePolicy
- AmazonEKS_CNI_Policy
- AmazonEC2ContainerRegistryReadOnly
- AmazonEKSClusterPolicy (for the cluster)

### 6. Configure kubectl

Update your kubeconfig:

```bash
aws eks --region ${AWS_REGION} update-kubeconfig --name luxe-jewelry-eks-cluster
```

### 7. Deploy the Application

1. Run the Jenkins pipeline with the following parameters:
   - `TARGET_REGISTRY`: `ecr`
   - `DEPLOY_ENVIRONMENT`: `production` (or your desired environment)
   - `PUSH_TO_ECR`: `true`

## Troubleshooting

### Image Pull Errors

If you encounter image pull errors:
1. Verify that the ECR repository exists
2. Check that the IAM role has the `AmazonEC2ContainerRegistryReadOnly` policy
3. Verify the image name and tag in the deployment files

### EKS Cluster Access

If you can't connect to the EKS cluster:
1. Verify your AWS credentials have the correct permissions
2. Check that the EKS cluster is in the `ACTIVE` state
3. Verify the kubeconfig is correctly configured

## Cleanup

To avoid unnecessary charges, clean up resources when not in use:

```bash
# Delete the EKS cluster
eksctl delete cluster --name luxe-jewelry-eks-cluster --region ${AWS_REGION}

# Delete ECR repositories
aws ecr delete-repository --repository-name luxe-jewelry-store-backend --force
aws ecr delete-repository --repository-name luxe-jewelry-store-frontend --force
```

## Monitoring

Monitor your EKS cluster and applications using:
- Amazon CloudWatch
- AWS X-Ray
- Prometheus and Grafana

## Security Best Practices

1. Use IAM roles for service accounts (IRSA) instead of instance profiles
2. Enable AWS Security Hub and GuardDuty
3. Regularly rotate IAM credentials
4. Use network policies to restrict pod-to-pod communication
5. Enable encryption at rest and in transit
