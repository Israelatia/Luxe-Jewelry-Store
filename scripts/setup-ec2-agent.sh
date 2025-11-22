#!/bin/bash
# Setup EC2 instance for Jenkins agent
set -e

echo "Setting up EC2 instance for Jenkins agent..."

# Update system
sudo yum update -y

# Install Docker
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo usermod -a -G docker ec2-user

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install kubectl
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# Install Java (for Jenkins agent)
sudo amazon-linux-extras install java-openjdk11 -y

# Create Jenkins agent directory
mkdir -p /home/ec2-user/jenkins-agent
cd /home/ec2-user/jenkins-agent

# Download Jenkins agent JAR (replace with your Jenkins URL)
echo "Please update this script with your Jenkins URL and download agent.jar"
# wget http://your-jenkins-server:8080/jnlpJars/agent.jar

echo "EC2 agent setup completed!"
echo "Next steps:"
echo "1. Download agent.jar from your Jenkins server"
echo "2. Create AMI from this instance"
echo "3. Create Launch Template and Auto Scaling Group"
