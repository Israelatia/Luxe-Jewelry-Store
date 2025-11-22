#!/bin/bash
# Deploy frontend static files to S3 with CloudFront

set -e

AWS_REGION="us-east-1"
BUCKET_NAME="luxe-jewelry-store-frontend-$(date +%s)"
DOMAIN_NAME="luxe-jewelry-store.com"  # Replace with your domain

echo "Creating S3 bucket: $BUCKET_NAME"
aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION

# Enable static website hosting
echo "Configuring static website hosting"
aws s3 website s3://$BUCKET_NAME \
  --index-document index.html \
  --error-document error.html

# Set bucket policy for public access
echo "Setting bucket policy"
cat > bucket-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
EOF

aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://bucket-policy.json

# Sync frontend files
echo "Uploading frontend files to S3"
aws s3 sync frontend/build/ s3://$BUCKET_NAME --delete

# Enable CORS
echo "Configuring CORS"
cat > cors-config.json <<EOF
{
    "CORSRules": [
        {
            "AllowedOrigins": ["*"],
            "AllowedHeaders": ["*"],
            "AllowedMethods": ["GET", "HEAD"],
            "MaxAgeSeconds": 3000
        }
    ]
}
EOF

aws s3api put-bucket-cors --bucket $BUCKET_NAME --cors-configuration file://cors-config.json

# Create CloudFront distribution
echo "Creating CloudFront distribution"
cat > cloudfront-config.json <<EOF
{
    "CallerReference": "luxe-frontend-$(date +%s)",
    "Comment": "CloudFront distribution for Luxe Jewelry Store frontend",
    "DefaultRootObject": "index.html",
    "Origins": {
        "Quantity": 1,
        "Items": [
            {
                "Id": "S3-$BUCKET_NAME",
                "DomainName": "$BUCKET_NAME.s3.amazonaws.com",
                "S3OriginConfig": {
                    "OriginAccessIdentity": ""
                }
            }
        ]
    },
    "DefaultCacheBehavior": {
        "TargetOriginId": "S3-$BUCKET_NAME",
        "ViewerProtocolPolicy": "redirect-to-https",
        "TrustedSigners": {
            "Enabled": false,
            "Quantity": 0
        },
        "ForwardedValues": {
            "QueryString": false,
            "Cookies": {
                "Forward": "none"
            }
        },
        "MinTTL": 0
    },
    "Enabled": true,
    "PriceClass": "PriceClass_100"
}
EOF

DISTRIBUTION_ID=$(aws cloudfront create-distribution --distribution-config file://cloudfront-config.json --query 'Distribution.Id' --output text)

echo "CloudFront distribution created: $DISTRIBUTION_ID"
echo "Waiting for distribution to deploy..."

aws cloudfront wait distribution-deployed --id $DISTRIBUTION_ID

DOMAIN_NAME=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.DomainName' --output text)

echo "Frontend deployed successfully!"
echo "S3 Bucket: s3://$BUCKET_NAME"
echo "CloudFront URL: https://$DOMAIN_NAME"

# Clean up temporary files
rm -f bucket-policy.json cors-config.json cloudfront-config.json
