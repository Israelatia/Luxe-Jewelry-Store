#!/bin/bash
# Create EBS snapshot for backup

INSTANCE_ID="i-xxxxxxxxxx"  # Replace with your Jenkins EC2 instance ID
DESCRIPTION="Jenkins backup snapshot - $(date +%Y-%m-%d-%H-%M-%S)"

echo "Creating snapshot for instance: $INSTANCE_ID"

# Get the root volume ID
VOLUME_ID=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId" \
    --output text)

echo "Root Volume ID: $VOLUME_ID"

# Create snapshot
SNAPSHOT_ID=$(aws ec2 create-snapshot \
    --volume-id $VOLUME_ID \
    --description "$DESCRIPTION" \
    --tag-specifications 'ResourceType=snapshot,Tags=[{Key=Name,Value=jenkins-backup-snapshot},{Key=Environment,Value=production}]' \
    --query 'SnapshotId' \
    --output text)

echo "Snapshot creation started: $SNAPSHOT_ID"

# Wait for snapshot to complete
echo "Waiting for snapshot to complete..."
aws ec2 wait snapshot-completed --snapshot-ids $SNAPSHOT_ID

echo "Snapshot completed: $SNAPSHOT_ID"

# Optional: Create backup plan with AWS Backup
echo "Creating AWS Backup plan..."
BACKUP_PLAN_ARN=$(aws backup create-backup-plan \
    --backup-plan file://backup-plan.json \
    --query 'BackupPlanId' \
    --output text)

echo "Backup plan created: $BACKUP_PLAN_ARN"
