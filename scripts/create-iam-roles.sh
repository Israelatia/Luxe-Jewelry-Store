#!/bin/bash
# Create IAM roles for EKS, EC2 agents, and other services
set -e

AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="992398098051"

echo "Creating IAM roles..."

# 1. EKS Cluster Role
echo "Creating EKS Cluster role..."
aws iam create-role \
    --role-name AmazonEKSClusterRole \
    --assume-role-policy-document file://trust-policy.json \
    --region $AWS_REGION || echo "Role may already exist"

aws iam attach-role-policy \
    --role-name AmazonEKSClusterRole \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

# 2. EKS Node Role
echo "Creating EKS Node role..."
aws iam create-role \
    --role-name AmazonEKSNodeRole \
    --assume-role-policy document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "ec2.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }' \
    --region $AWS_REGION || echo "Role may already exist"

aws iam attach-role-policy \
    --role-name AmazonEKSNodeRole \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

aws iam attach-role-policy \
    --role-name AmazonEKSNodeRole \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

aws iam attach-role-policy \
    --role-name AmazonEKSNodeRole \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

# 3. Jenkins EC2 Agent Role
echo "Creating Jenkins EC2 Agent role..."
aws iam create-role \
    --role-name jenkins-agent-role \
    --assume-role-policy document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "ec2.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }' \
    --region $AWS_REGION || echo "Role may already exist"

aws iam attach-role-policy \
    --role-name jenkins-agent-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess

aws iam attach-role-policy \
    --role-name jenkins-agent-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

aws iam attach-role-policy \
    --role-name jenkins-agent-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

# Create instance profile
aws iam create-instance-profile \
    --instance-profile-name jenkins-agent-role \
    --region $AWS_REGION || echo "Instance profile may already exist"

aws iam add-role-to-instance-profile \
    --instance-profile-name jenkins-agent-role \
    --role-name jenkins-agent-role

echo "IAM roles created successfully!"
echo "Note: Some roles may already exist"
