#!/bin/bash
# Create CloudFront distribution for S3 static website
set -e

AWS_REGION="us-east-1"
BUCKET_NAME="luxe-jewelry-store-static-$(date +%s)"

echo "Creating CloudFront distribution for S3 bucket: $BUCKET_NAME"

# Get S3 bucket region
BUCKET_REGION=$(aws s3api get-bucket-location --bucket $BUCKET_NAME --region $AWS_REGION --output text)

# Create CloudFront distribution
DISTRIBUTION_ID=$(aws cloudfront create-distribution \
    --distribution-config '{
        "CallerReference": "'$(date +%s)'",
        "Comment": "Luxe Jewelry Store Static Website",
        "DefaultRootObject": "index.html",
        "Origins": {
            "Quantity": 1,
            "Items": [{
                "Id": "S3-'$BUCKET_NAME'",
                "DomainName": "'$BUCKET_NAME'.s3.'$BUCKET_REGION'.amazonaws.com",
                "S3OriginConfig": {
                    "OriginAccessIdentity": ""
                }
            }]
        },
        "DefaultCacheBehavior": {
            "TargetOriginId": "S3-'$BUCKET_NAME'",
            "ViewerProtocolPolicy": "redirect-to-https",
            "TrustedSigners": {
                "Enabled": false,
                "Quantity": 0
            },
            "ForwardedValues": {
                "QueryString": false,
                "Cookies": {"Forward": "none"}
            },
            "MinTTL": 0
        },
        "Enabled": true,
        "PriceClass": "PriceClass_100"
    }' \
    --region $AWS_REGION \
    --output text --query 'Distribution.Id')

echo "CloudFront distribution created: $DISTRIBUTION_ID"
echo "Waiting for distribution to deploy..."

# Wait for distribution to be deployed
aws cloudfront wait distribution-deployed --id $DISTRIBUTION_ID --region $AWS_REGION

# Get distribution domain name
DOMAIN_NAME=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --region $AWS_REGION --output text --query 'Distribution.DomainName')

echo "CloudFront distribution is ready!"
echo "Domain: https://$DOMAIN_NAME"
echo "Next: Upload your files to S3 bucket: $BUCKET_NAME"
