#!/bin/bash
# Simple ECR setup

aws ecr create-repository --repository-name luxe-backend --region us-east-1
aws ecr create-repository --repository-name luxe-frontend --region us-east-1

echo "ECR repos created"
