#!/bin/bash
# Simple EC2 agent setup

# Launch EC2 with Jenkins tools
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.micro \
  --key-name jenkins-agent-key-pair \
  --security-group-ids sg-xxxxxxxxx \
  --user-data file://simple-user-data.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=jenkins-agent}]'

echo "EC2 agent launched"
