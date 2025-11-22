#!/bin/bash
# Create Auto Scaling Group for Jenkins agents
set -e

AWS_REGION="us-east-1"
LAUNCH_TEMPLATE="jenkins-agent-template"
VPC_ZONE_ID="subnet-xxxxxxxx,subnet-yyyyyyyy"  # Update with your subnets

echo "Creating Auto Scaling Group for Jenkins agents..."

aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name jenkins-agent-asg \
    --launch-template LaunchTemplateName=$LAUNCH_TEMPLATE,Version='$Latest' \
    --vpc-zone-identifier $VPC_ZONE_ID \
    --min-size 0 \
    --max-size 3 \
    --desired-capacity 1 \
    --target-tracking-configurations '[{"PredefinedMetricSpecification":{"PredefinedMetricType":"ASGAverageCPUUtilization"},"TargetValue":50.0,"DisableScaleIn":false}]' \
    --region $AWS_REGION

echo "Auto Scaling Group created successfully!"
echo "Min: 0, Desired: 1, Max: 3 instances"
