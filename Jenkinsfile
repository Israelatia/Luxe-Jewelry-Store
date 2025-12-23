pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        EKS_CLUSTER_NAME = 'student-eks-cluster'
        NAMESPACE = 'app'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        ECR_REPO = "992398098051.dkr.ecr.us-east-1.amazonaws.com/aws-project"
        KUBECONFIG_PATH = 'C:\\Users\\israel\\.kube\\config'
    }

    stages {
        // ... (Build and Docker Push stages would go here)

        stage('Deploy to EKS') {
            steps {
                withAWS(region: "${AWS_REGION}") {
                    script {
                        echo "Refreshing Kubeconfig..."
                        // Delete old config to ensure a fresh session
                        bat "if exist ${KUBECONFIG_PATH} del ${KUBECONFIG_PATH}"
                        bat "aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION} --kubeconfig ${KUBECONFIG_PATH}"

                        echo "Testing EKS access..."
                        bat "kubectl cluster-info --kubeconfig=${KUBECONFIG_PATH}"

                        echo "Deploying manifests to namespace: ${NAMESPACE}..."
                        // Using -n app to override or set the namespace
                        bat "kubectl apply -f k8s/ -n ${NAMESPACE} --kubeconfig=${KUBECONFIG_PATH}"

                        echo "Waiting for Kubernetes to register objects..."
                        sleep(time: 10, unit: 'SECONDS')

                        echo "Updating deployment image to: ${ECR_REPO}:${IMAGE_TAG}..."
                        bat "kubectl set image deployment/luxe-jewelry-frontend frontend=${ECR_REPO}:${IMAGE_TAG} -n ${NAMESPACE} --kubeconfig=${KUBECONFIG_PATH}"

                        echo "Waiting for rollout..."
                        bat "kubectl rollout status deployment/luxe-jewelry-frontend -n ${NAMESPACE} --timeout=120s --kubeconfig=${KUBECONFIG_PATH}"
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                echo "Pipeline completed!"
            }
        }
        success {
            withAWS(region: 'us-east-1') {
                bat 'aws sns publish --topic-arn arn:aws:sns:us-east-1:992398098051:jenkins-build-notifications --subject "Jenkins Build SUCCESS" --message "Build #' + env.BUILD_NUMBER + ' deployed successfully to app namespace." --region us-east-1'
            }
        }
        failure {
            withAWS(region: 'us-east-1') {
                bat 'aws sns publish --topic-arn arn:aws:sns:us-east-1:992398098051:jenkins-build-notifications --subject "Jenkins Build FAILURE" --message "Build #' + env.BUILD_NUMBER + ' failed during deployment to app namespace." --region us-east-1'
            }
        }
    }
}