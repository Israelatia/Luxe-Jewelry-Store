#!/bin/bash
# Simple EC2 backup

INSTANCE_ID="i-xxxxxxxxxx"  # Your Jenkins instance ID
aws ec2 create-snapshot --volume-id vol-xxxxxxxxxx --description "Jenkins backup"

echo "Snapshot created"
