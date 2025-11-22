#!/bin/bash
# Simple S3 + CloudFront deploy

BUCKET="luxe-frontend-$(date +%s)"
aws s3 mb s3://$BUCKET
aws s3 sync frontend/build/ s3://$BUCKET
aws s3 website s3://$BUCKET --index-document index.html

echo "Frontend deployed to: http://$BUCKET.s3-website-us-east-1.amazonaws.com"
