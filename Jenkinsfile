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
                        bat "docker build -f dockerfile.web -t ${IMAGE_NAME}:${IMAGE_TAG} ."
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

        // --- שלב חדש: הגדרת הסודות בקלאסטר ---
        stage('Prepare Secrets') {
            steps {
                withAWS(credentials: "${AWS_CRED_ID}", region: "${AWS_REGION}") {
                    script {
                        echo "Applying SecretProviderClass..."
                        // מחיל את הקובץ שיצרנו קודם כדי שהקלאסטר יכיר את הסוד מ-AWS
                        bat "kubectl apply -f ExampleSecretProviderClass.yaml -n ${NAMESPACE} --kubeconfig=${KUBECONFIG_PATH}"
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

                        echo "Detecting Actual Container Name..."
                        def containerName = bat(
                            script: "kubectl get deployment luxe-frontend -n ${NAMESPACE} --kubeconfig=${KUBECONFIG_PATH} -o jsonpath=\"{.spec.template.spec.containers[0].name}\"",
                            returnStdout: true
                        ).trim()

                        containerName = containerName.split('\n').last().trim()
                        echo "Found Container: ${containerName}"

                        echo "Updating deployment image and mounting secrets..."
                        // כאן אנחנו מעדכנים את האימג'
                        bat "kubectl set image deployment/luxe-frontend ${containerName}=${IMAGE_NAME}:${IMAGE_TAG} -n ${NAMESPACE} --kubeconfig=${KUBECONFIG_PATH}"
                    }
                }
            }
        }

        stage('Verify & Monitor') {
            steps {
                withAWS(credentials: "${AWS_CRED_ID}", region: "${AWS_REGION}") {
                    script {
                        echo "Waiting for Rollout in namespace: ${NAMESPACE}..."
                        bat "kubectl rollout status deployment/luxe-frontend -n ${NAMESPACE} --timeout=120s --kubeconfig=${KUBECONFIG_PATH}"
                        
                        echo "Verifying Secrets Mount..."
                        // פקודה לבדיקה אם הקובץ של הסוד קיים בתוך הפוד החדש
                        bat "kubectl get pods -n ${NAMESPACE} --kubeconfig=${KUBECONFIG_PATH}"
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Successfully migrated and deployed to EKS with AWS Secrets!"
        }
        failure {
            echo "Deployment failed. Check ECR login, Container names, or SecretProviderClass."
        }
    }
}