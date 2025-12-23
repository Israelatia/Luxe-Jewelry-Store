pipeline {
    agent any

    environment {
        AWS_REGION      = 'us-east-1'
        AWS_ACCOUNT_ID  = '992398098051'
        ECR_REPO_NAME   = 'aws-project'
        ECR_REGISTRY    = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_NAME      = "${ECR_REGISTRY}/${ECR_REPO_NAME}"
        IMAGE_TAG       = "${env.BUILD_NUMBER}"
        
        EKS_CLUSTER     = 'student-eks-cluster'
        NAMESPACE       = 'app'
        KUBECONFIG      = 'C:\\Users\\israel\\.kube\\config'
        AWS_CRED_ID     = 'aws-credentials-id' // The ID of the credentials you saved in Jenkins
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('ECR Login & Build') {
            steps {
                withAWS(credentials: "${AWS_CRED_ID}", region: "${AWS_REGION}") {
                    script {
                        echo "Logging into Amazon ECR..."
                        // Windows-friendly ECR login
                        bat "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                        
                        echo "Building Docker Image: ${IMAGE_NAME}:${IMAGE_TAG}"
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
                        echo "Pushing images to ECR..."
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
                        bat "if exist ${KUBECONFIG} del ${KUBECONFIG}"
                        bat "aws eks update-kubeconfig --name ${EKS_CLUSTER} --region ${AWS_REGION} --kubeconfig ${KUBECONFIG}"

                        echo "Applying Kubernetes Manifests..."
                        // Apply all files in k8s folder to the 'app' namespace
                        bat "kubectl apply -f k8s/ -n ${NAMESPACE} --kubeconfig=${KUBECONFIG}"

                        echo "Updating Deployment with new ECR Image..."
                        // This updates the container to the exact version we just built
                        bat "kubectl set image deployment/luxe-jewelry-frontend frontend=${IMAGE_NAME}:${IMAGE_TAG} -n ${NAMESPACE} --kubeconfig=${KUBECONFIG}"
                    }
                }
            }
        }

        stage('Verify & Monitor') {
            steps {
                withAWS(credentials: "${AWS_CRED_ID}", region: "${AWS_REGION}") {
                    script {
                        echo "Monitoring Rollout Status..."
                        bat "kubectl rollout status deployment/luxe-jewelry-frontend -n ${NAMESPACE} --timeout=120s --kubeconfig=${KUBECONFIG}"
                        
                        echo "Verifying Pods in namespace: ${NAMESPACE}"
                        bat "kubectl get pods -n ${NAMESPACE} --kubeconfig=${KUBECONFIG}"
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Deployment Successful!"
            // Add SNS notification here if needed
        }
        failure {
            echo "Deployment Failed. Check the logs above for SecretProviderClass or Namespace errors."
        }
    }
}