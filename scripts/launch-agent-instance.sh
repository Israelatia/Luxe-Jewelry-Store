#!/bin/bash

# Variables
INSTANCE_TYPE="t3.medium"
KEY_NAME="jenkins-agent-key-pair"
SECURITY_GROUP_NAME="jenkins-agent-sg"
SUBNET_ID=""  # Fill in your subnet ID
AMI_ID="ami-0c55b159cbfafe1f0"  # Amazon Linux 2

# Create security group
SG_ID=$(aws ec2 create-security-group \
  --group-name "$SECURITY_GROUP_NAME" \
  --description "Security group for Jenkins agent" \
  --vpc-id "$VPC_ID" \
  --query 'GroupId' \
  --output text)

# Allow SSH and required ports
aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

# Launch instance with user data
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SG_ID" \
  --subnet-id "$SUBNET_ID" \
  --user-data file://create-jenkins-agent-ami.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=jenkins-agent-ami-builder}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instance launched: $INSTANCE_ID"
echo "Waiting for instance to be running..."

aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

echo "Instance is running. Creating AMI..."

# Create AMI
AMI_ID=$(aws ec2 create-image \
  --instance-id "$INSTANCE_ID" \
  --name "jenkins-agent-ami-$(date +%Y%m%d%H%M%S)" \
  --description "AMI for Jenkins agent with Docker, kubectl, AWS CLI" \
  --tag-specifications 'ResourceType=image,Tags=[{Key=Name,Value=jenkins-agent-ami}]' \
  --query 'ImageId' \
  --output text)

echo "AMI creation started: $AMI_ID"
echo "Waiting for AMI to become available..."

aws ec2 wait image-available --image-ids "$AMI_ID"

echo "AMI is available: $AMI_ID"

# Terminate the temporary instance
aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"
echo "Temporary instance terminated"

echo "AMI ID: $AMI_ID"
echo "Security Group ID: $SG_ID"
