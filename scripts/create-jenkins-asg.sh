#!/bin/bash

# Variables
AMI_ID=""  # Fill in the AMI ID from previous step
INSTANCE_TYPE="t3.medium"
KEY_NAME="jenkins-agent-key-pair"
SECURITY_GROUP_ID=""  # Fill in from previous step
SUBNET_ID=""  # Fill in your subnet ID
VPC_ID=""  # Fill in your VPC ID
MIN_SIZE=1
MAX_SIZE=3
DESIRED_CAPACITY=1

# Create IAM instance profile for Jenkins agents
aws iam create-role \
  --role-name jenkins-agent-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {"Service": "ec2.amazonaws.com"},
        "Action": "sts:AssumeRole"
      }
    ]
  }'

# Attach policies
aws iam attach-role-policy \
  --role-name jenkins-agent-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess

aws iam attach-role-policy \
  --role-name jenkins-agent-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

aws iam attach-role-policy \
  --role-name jenkins-agent-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

aws iam attach-role-policy \
  --role-name jenkins-agent-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

# Create instance profile
aws iam create-instance-profile --instance-profile-name jenkins-agent-profile

# Add role to instance profile
aws iam add-role-to-instance-profile \
  --instance-profile-name jenkins-agent-profile \
  --role-name jenkins-agent-role

# Create launch template
LAUNCH_TEMPLATE_ID=$(aws ec2 create-launch-template \
  --launch-template-name jenkins-agent-template \
  --launch-template-data '{
    "ImageId": "'$AMI_ID'",
    "InstanceType": "'$INSTANCE_TYPE'",
    "KeyName": "'$KEY_NAME'",
    "SecurityGroupIds": ["'$SECURITY_GROUP_ID'"],
    "IamInstanceProfile": {"Name": "jenkins-agent-profile"},
    "UserData": "",
    "TagSpecifications": [
      {
        "ResourceType": "instance",
        "Tags": [
          {"Key": "Name", "Value": "jenkins-agent"},
          {"Key": "Type", "Value": "jenkins-agent"}
        ]
      }
    ]
  }' \
  --query 'LaunchTemplate.LaunchTemplateId' \
  --output text)

echo "Launch template created: $LAUNCH_TEMPLATE_ID"

# Create Auto Scaling Group
ASG_NAME="jenkins-agent-asg"

aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name "$ASG_NAME" \
  --launch-template "LaunchTemplateName=jenkins-agent-template" \
  --min-size "$MIN_SIZE" \
  --max-size "$MAX_SIZE" \
  --desired-capacity "$DESIRED_CAPACITY" \
  --vpc-zone-identifier "$SUBNET_ID" \
  --tags ResourceId="$ASG_NAME",ResourceType=auto-scaling-group,Key=Name,Value=jenkins-agent-asg,PropagateAtLaunch=true \
  --health-check-type EC2 \
  --health-check-grace-period 300

echo "Auto Scaling Group created: $ASG_NAME"
echo "Current instances:"

aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "$ASG_NAME" \
  --query 'AutoScalingGroups[0].Instances[*].[InstanceId,LifecycleState]' \
  --output table
