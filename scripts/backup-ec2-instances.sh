#!/bin/bash
# Create snapshots of EC2 instances
set -e

AWS_REGION="us-east-1"
DESCRIPTION="Luxe Jewelry Store Backup - $(date +%Y-%m-%d-%H-%M-%S)"

echo "Creating EC2 instance snapshots..."

# Get all running instances
INSTANCE_IDS=$(aws ec2 describe-instances \
    --region $AWS_REGION \
    --filters "Name=instance-state-name,Values=running" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text)

for instance_id in $INSTANCE_IDS; do
    echo "Creating snapshot for instance: $instance_id"
    
    # Get instance name tag
    instance_name=$(aws ec2 describe-tags \
        --region $AWS_REGION \
        --filters "Name=resource-id,Values=$instance_id" "Name=key,Values=Name" \
        --query "Tags[0].Value" \
        --output text 2>/dev/null || echo "Unnamed")
    
    snapshot_id=$(aws ec2 create-snapshot \
        --region $AWS_REGION \
        --instance-id $instance_id \
        --description "$DESCRIPTION - Instance: $instance_name ($instance_id)" \
        --tag-specifications "ResourceType=snapshot,Tags=[{Key=Name,Value=Backup-$instance_name-$(date +%Y%m%d)}]" \
        --query "SnapshotId" \
        --output text)
    
    echo "Created snapshot: $snapshot_id"
done

echo "EC2 snapshots completed!"
