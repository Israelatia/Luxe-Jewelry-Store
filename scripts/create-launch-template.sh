#!/bin/bash
# Create Launch Template for Jenkins EC2 agents
set -e

AWS_REGION="us-east-1"
AMI_ID="ami-0c02fb55956c7d316"  # Amazon Linux 2 - update with your AMI
INSTANCE_TYPE="t3.medium"
KEY_NAME="your-key-pair"  # Update with your key pair
SECURITY_GROUP_ID="sg-xxxxxxxx"  # Update with your SG
SUBNET_ID="subnet-xxxxxxxx"  # Update with your subnet
IAM_ROLE="jenkins-agent-role"  # Create this role first

echo "Creating Launch Template for Jenkins agents..."

# Create launch template
aws ec2 create-launch-template \
    --launch-template-name jenkins-agent-template \
    --launch-template-data "{
        \"ImageId\": \"$AMI_ID\",
        \"InstanceType\": \"$INSTANCE_TYPE\",
        \"KeyName\": \"$KEY_NAME\",
        \"SecurityGroupIds\": [\"$SECURITY_GROUP_ID\"],
        \"SubnetId\": \"$SUBNET_ID\",
        \"IamInstanceProfile\": {
            \"Name\": \"$IAM_ROLE\"
        },
        \"UserData\": \"$(base64 -w 0 << EOF
#!/bin/bash
cd /home/ec2-user/jenkins-agent
java -jar agent.jar -jnlpUrl http://your-jenkins:8080/computer/ec2-agent/jenkins-agent.jnlp -secret YOUR_SECRET -workDir /home/ec2-user
EOF
)\",
        \"TagSpecifications\": [
            {
                \"ResourceType\": \"instance\",
                \"Tags\": [
                    {\"Key\": \"Name\", \"Value\": \"jenkins-agent\"},
                    {\"Key\": \"Environment\", \"Value\": \"dev\"}
                ]
            }
        ]
    }" \
    --region $AWS_REGION

echo "Launch template created successfully!"
echo "Next: Create Auto Scaling Group"
