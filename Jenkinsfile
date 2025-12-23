pipeline {
    agent any

    environment {
        // AWS & ECR Config
        AWS_REGION      = 'us-east-1'
        AWS_ACCOUNT_ID  = '992398098051'
        ECR_REPO_NAME   = 'aws-project'
        ECR_REGISTRY    = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_NAME      = "${ECR_REGISTRY}/${ECR_REPO_NAME}"
        IMAGE_TAG       = "${env.BUILD_NUMBER}"
        
        // EKS Config
        EKS_CLUSTER     = 'student-eks-cluster'
        NAMESPACE       = 'app'
        KUBECONFIG_PATH = 'C:\\Users\\israel\\.kube\\config'
        AWS_CRED_ID     = 'aws-credentials'
    }

    stages {
        stage('Checkout Source') {
            steps {
                checkout scm
            }
        }

        stage('ECR Authenticate & Build') {
            steps {
                withAWS(credentials: "${AWS_CRED_ID}", region: "${AWS_REGION}") {
                    script {
                        echo "Logging into Amazon ECR..."
                        bat "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                        
                        echo "Building Image: ${IMAGE_NAME}:${IMAGE_TAG}"
                        bat "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                        bat "docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest"
                    }
                }
            }
        }

        stage('Push to ECR') {
            steps {
                withAWS(credentials: "${AWS_CRED_ID}", region: "${AWS_REGION}") {
                    script {
                        echo "Pushing ${IMAGE_TAG} and latest to ECR..."
                        bat "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
                        bat "docker push ${IMAGE_NAME}:latest"
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                withAWS(credentials: "${AWS_CRED_ID}", region: "${AWS_REGION}") {
                    script {
                        echo "Refreshing Kubeconfig..."
                        bat "if exist ${KUBECONFIG_PATH} del ${KUBECONFIG_PATH}"
                        bat "aws eks update-kubeconfig --name ${EKS_CLUSTER} --region ${AWS_REGION} --kubeconfig ${KUBECONFIG_PATH}"

                        echo "Applying Manifests to namespace: ${NAMESPACE}"
                        // This applies your YAMLs (Service, Deployment, etc.)
                        bat "kubectl apply -f k8s/ -n ${NAMESPACE} --kubeconfig=${KUBECONFIG_PATH}"

                        echo "Updating Image to ECR Migrated Image..."
                        // Dynamically update the deployment to use the new ECR image tag
                        bat "kubectl set image deployment/luxe-jewelry-frontend frontend=${IMAGE_NAME}:${IMAGE_TAG} -n ${NAMESPACE} --kubeconfig=${KUBECONFIG_PATH}"
                    }
                }
            }
        }

        stage('Verify & Monitor') {
            steps {
                withAWS(credentials: "${AWS_CRED_ID}", region: "${AWS_REGION}") {
                    script {
                        echo "Waiting for Rollout..."
                        bat "kubectl rollout status deployment/luxe-jewelry-frontend -n ${NAMESPACE} --timeout=120s --kubeconfig=${KUBECONFIG_PATH}"
                        
                        echo "Verifying Image Source in Running Pods..."
                        // This command confirms the pod is pulling from YOUR ECR repo
                        bat "kubectl get pods -n ${NAMESPACE} -o jsonpath=\"{.items[*].spec.containers[*].image}\" --kubeconfig=${KUBECONFIG_PATH}"
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Successfully migrated and deployed to EKS!"
        }
        failure {
            echo "Deployment failed. Check ECR login or SecretProviderClass CRDs."
        }
    }
}
