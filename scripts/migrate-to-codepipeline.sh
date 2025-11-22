#!/bin/bash
# Migrate CI/CD to AWS CodePipeline and CodeBuild

set -e

AWS_REGION="us-east-1"
GITHUB_REPO="Israelatia/Luxe-Jewelry-Store"
GITHUB_BRANCH="main"
GITHUB_TOKEN="your-github-token"  # Store in Secrets Manager
CODEPIPELINE_NAME="luxe-jewelry-pipeline"

echo "Creating CodeBuild projects..."

# Create CodeBuild project for build and test
cat > buildspec.yml <<EOF
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
      - IMAGE_TAG=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c1-7)
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...
      - cd backend
      - docker build -t $ECR_REPOSITORY/$APP_NAME-backend:$IMAGE_TAG .
      - docker tag $ECR_REPOSITORY/$APP_NAME-backend:$IMAGE_TAG $ECR_REPOSITORY/$APP_NAME-backend:latest
      - cd ../frontend
      - docker build -t $ECR_REPOSITORY/$APP_NAME-frontend:$IMAGE_TAG .
      - docker tag $ECR_REPOSITORY/$APP_NAME-frontend:$IMAGE_TAG $ECR_REPOSITORY/$APP_NAME-frontend:latest
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker images...
      - docker push $ECR_REPOSITORY/$APP_NAME-backend:$IMAGE_TAG
      - docker push $ECR_REPOSITORY/$APP_NAME-backend:latest
      - docker push $ECR_REPOSITORY/$APP_NAME-frontend:$IMAGE_TAG
      - docker push $ECR_REPOSITORY/$APP_NAME-frontend:latest
      - printf '[{"name":"luxe-backend","imageUri":"%s"},{"name":"luxe-frontend","imageUri":"%s"}]' $ECR_REPOSITORY/$APP_NAME-backend:$IMAGE_TAG $ECR_REPOSITORY/$APP_NAME-frontend:$IMAGE_TAG > imagedefinitions.json
artifacts:
  files: imagedefinitions.json
EOF

# Create build project
aws codebuild create-project \
  --name luxe-build-project \
  --source github \
  --source-type GITHUB \
  --source-location "https://github.com/$GITHUB_REPO.git" \
  --artifacts type=NO_ARTIFACTS \
  --environment computeType=BUILD_GENERAL1_SMALL,image=aws/codebuild/standard:5.0,type=LINUX_CONTAINER,privilegedMode=true \
  --service-role arn:aws:iam::$AWS_ACCOUNT_ID:role/codebuild-service-role \
  --timeout-in-minutes 15

# Create CodeBuild project for EKS deployment
cat > buildspec-deploy.yml <<EOF
version: 0.2

phases:
  install:
    runtime-versions:
      kubernetes: 1.21
  pre_build:
    commands:
      - echo Updating kubeconfig...
      - aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region $AWS_REGION
  build:
    commands:
      - echo Deploying to EKS...
      - kubectl apply -f k8s/ -n $K8S_NAMESPACE
      - kubectl rollout status deployment/luxe-backend -n $K8S_NAMESPACE
      - kubectl rollout status deployment/luxe-frontend -n $K8S_NAMESPACE
EOF

aws codebuild create-project \
  --name luxe-deploy-project \
  --source github \
  --source-type GITHUB \
  --source-location "https://github.com/$GITHUB_REPO.git" \
  --artifacts type=NO_ARTIFACTS \
  --environment computeType=BUILD_GENERAL1_SMALL,image=aws/codebuild/standard:5.0,type=LINUX_CONTAINER \
  --service-role arn:aws:iam::$AWS_ACCOUNT_ID:role/codebuild-service-role \
  --timeout-in-minutes 10

echo "Creating CodePipeline..."

# Create CodePipeline
cat > pipeline.json <<EOF
{
    "pipeline": {
        "name": "$CODEPIPELINE_NAME",
        "roleArn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/codepipeline-service-role",
        "artifactStore": {
            "type": "S3",
            "location": "codepipeline-artifacts-$AWS_ACCOUNT_ID"
        },
        "stages": [
            {
                "name": "Source",
                "actions": [
                    {
                        "name": "SourceAction",
                        "actionTypeId": {
                            "category": "Source",
                            "owner": "ThirdParty",
                            "provider": "GitHub",
                            "version": "1"
                        },
                        "configuration": {
                            "Owner": "Israelatia",
                            "Repo": "Luxe-Jewelry-Store",
                            "Branch": "$GITHUB_BRANCH",
                            "OAuthToken": "$GITHUB_TOKEN"
                        },
                        "outputArtifacts": [
                            {
                                "name": "SourceCode"
                            }
                        ]
                    }
                ]
            },
            {
                "name": "Build",
                "actions": [
                    {
                        "name": "BuildAction",
                        "actionTypeId": {
                            "category": "Build",
                            "owner": "AWS",
                            "provider": "CodeBuild",
                            "version": "1"
                        },
                        "configuration": {
                            "ProjectName": "luxe-build-project"
                        },
                        "inputArtifacts": [
                            {
                                "name": "SourceCode"
                            }
                        ],
                        "outputArtifacts": [
                            {
                                "name": "BuildOutput"
                            }
                        ]
                    }
                ]
            },
            {
                "name": "Deploy",
                "actions": [
                    {
                        "name": "DeployAction",
                        "actionTypeId": {
                            "category": "Deploy",
                            "owner": "AWS",
                            "provider": "CodeBuild",
                            "version": "1"
                        },
                        "configuration": {
                            "ProjectName": "luxe-deploy-project"
                        },
                        "inputArtifacts": [
                            {
                                "name": "BuildOutput"
                            }
                        ]
                    }
                ]
            }
        ]
    }
}
EOF

aws codepipeline create-pipeline --cli-input-json file://pipeline.json

echo "CodePipeline created successfully!"
echo "Pipeline name: $CODEPIPELINE_NAME"

# Add SNS notifications to CodePipeline
aws sns create-topic --name codepipeline-notifications --region $AWS_REGION

aws codepipeline put-pipeline-notification \
  --pipeline-name $CODEPIPELINE_NAME \
  --notification-rules file://notification-rules.json

# Clean up
rm -f buildspec.yml buildspec-deploy.yml pipeline.json
