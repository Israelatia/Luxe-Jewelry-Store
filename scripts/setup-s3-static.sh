#!/bin/bash
# Setup S3 bucket for static website with CloudFront
set -e

BUCKET_NAME="luxe-jewelry-store-static-$(date +%s)"
AWS_REGION="us-east-1"

echo "Creating S3 bucket: $BUCKET_NAME"

# Create S3 bucket
aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region $AWS_REGION

# Enable static website hosting
aws s3 website s3://$BUCKET_NAME/ \
    --index-document index.html \
    --error-document error.html

# Set bucket policy for public read
cat > bucket-policy.json << EOF
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

aws s3api put-bucket-policy \
    --bucket $BUCKET_NAME \
    --policy file://bucket-policy.json

echo "S3 bucket created: $BUCKET_NAME"
echo "Next steps:"
echo "1. Upload your static files to: s3://$BUCKET_NAME"
echo "2. Create CloudFront distribution pointing to this bucket"
echo "3. Update your DNS to point to CloudFront distribution"
