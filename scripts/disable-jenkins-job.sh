#!/bin/bash
# Disable Jenkins job after migration to CodePipeline
set -e

echo "Disabling Jenkins job after migration to CodePipeline..."

# This script assumes you have Jenkins CLI or API access
# Update with your actual Jenkins job name and URL

JENKINS_URL="http://your-jenkins-server:8080"
JOB_NAME="luxe-jewelry-store"
JENKINS_USER="your-jenkins-user"
API_TOKEN="your-api-token"

# Method 1: Using Jenkins CLI (if installed)
# java -jar jenkins-cli.jar -s $JENKINS_URL -auth $JENKINS_USER:$API_TOKEN disable-job $JOB_NAME

# Method 2: Using Jenkins API
curl -X POST "$JENKINS_URL/job/$JOB_NAME/disable" \
    --user "$JENKINS_USER:$API_TOKEN" \
    --data ""

echo "Jenkins job disabled successfully!"
echo "Pipeline is now managed by AWS CodePipeline"
