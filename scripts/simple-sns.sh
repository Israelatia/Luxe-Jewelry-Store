#!/bin/bash
# Simple SNS setup

aws sns create-topic --name jenkins-build-notifications
echo "SNS topic created. Subscribe your email to receive notifications."
