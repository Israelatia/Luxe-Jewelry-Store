#!/bin/bash
# Simple CodePipeline migration

# Create CodeBuild project
aws codebuild create-project \
  --name luxe-build \
  --source github \
  --source-type GITHUB \
  --source-location https://github.com/Israelatia/Luxe-Jewelry-Store.git \
  --artifacts type=NO_ARTIFACTS \
  --environment computeType=BUILD_GENERAL1_SMALL,image=aws/codebuild/standard:5.0,type=LINUX_CONTAINER,privilegedMode=true \
  --service-role arn:aws:iam::992398098051:role/codebuild-service-role

echo "CodeBuild project created"
echo "Create CodePipeline in AWS Console for simplicity"
