#!/bin/bash
# Deploy application to EC2 instance
set -e

AWS_REGION="us-east-1"
ECR_REPOSITORY="992398098051.dkr.ecr.us-east-1.amazonaws.com"
APP_NAME="luxe-app"

echo "🚀 Deploying to EC2..."

# Get EC2 instance IP
EC2_IP=$(aws ec2 describe-instances \
    --region $AWS_REGION \
    --filters "Name=tag:Name,Values=luxe-jewelry-app" "Name=instance-state-name,Values=running" \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

if [ -z "$EC2_IP" ] || [ "$EC2_IP" = "None" ]; then
    echo "❌ No running EC2 instance found with tag 'luxe-jewelry-app'"
    exit 1
fi

echo "📍 Found EC2 instance: $EC2_IP"

# Deploy commands
DEPLOY_COMMANDS="
    sudo docker pull $ECR_REPOSITORY/aws-project:latest
    sudo docker stop $APP_NAME || true
    sudo docker rm $APP_NAME || true
    sudo docker run -d -p 80:3000 --name $APP_NAME $ECR_REPOSITORY/aws-project:latest
    sudo docker ps
"

echo "🔄 Deploying application..."
ssh -o StrictHostKeyChecking=no -i /path/to/key.pem ec2-user@$EC2_IP "$DEPLOY_COMMANDS"

echo "✅ Deployment completed!"
echo "🌐 Application available at: http://$EC2_IP"
