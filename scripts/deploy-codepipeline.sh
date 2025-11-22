#!/bin/bash
# Deploy CodePipeline and CodeBuild resources
set -e

AWS_REGION="us-east-1"
STACK_NAME="luxe-jewelry-pipeline"

echo "Deploying CodePipeline and CodeBuild resources..."

# Deploy CloudFormation stack
aws cloudformation deploy \
    --template-file ../aws/codepipeline.yaml \
    --stack-name $STACK_NAME \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides \
        GitHubOwner=Israelatia \
        GitHubRepo=Luxe-Jewelry-Store \
        Branch=main \
    --region $AWS_REGION

echo "CodePipeline deployed successfully!"
echo "Pipeline URL: https://console.aws.amazon.com/codesuite/codepipeline/pipelines/luxe-jewelry-pipeline/view"

# Get SNS topic ARN for notifications
SNS_ARN=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $AWS_REGION \
    --output text \
    --query 'Stacks[0].Outputs[?OutputKey==`SNSTopicArn`].OutputValue')

echo "SNS Topic ARN: $SNS_ARN"
echo "Subscribe to this topic for notifications"
