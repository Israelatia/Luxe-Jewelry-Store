#!/bin/bash
# Create SNS topic for Jenkins notifications
set -e

AWS_REGION="us-east-1"
TOPIC_NAME="jenkins-build-notifications"

echo "Creating SNS topic: $TOPIC_NAME"

# Create SNS topic
TOPIC_ARN=$(aws sns create-topic \
    --name $TOPIC_NAME \
    --region $AWS_REGION \
    --output text --query 'TopicArn')

echo "SNS Topic created: $TOPIC_ARN"

# Subscribe email (replace with your email)
echo "Please subscribe to the topic with your email:"
echo "aws sns subscribe --topic-arn $TOPIC_ARN --protocol email --notification-endpoint your-email@example.com --region $AWS_REGION"

echo "SNS topic setup completed!"
