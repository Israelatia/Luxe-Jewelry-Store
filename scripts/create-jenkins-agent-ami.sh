#!/bin/bash
# User data script to create Jenkins agent AMI

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl enable docker
systemctl start docker
usermod -a -G docker ec2-user

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Java (Jenkins agent)
yum install -y java-17-amazon-corretto

# Install Git
yum install -y git

# Create Jenkins workspace directory
mkdir -p /var/jenkins
chown -R ec2-user:ec2-user /var/jenkins

# Add Jenkins user to docker group (already done above)
# Clean up
rm -rf awscliv2.zip aws kubectl

echo "Jenkins agent AMI setup complete"
