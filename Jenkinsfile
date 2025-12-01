pipeline {
    parameters {
        string(name: 'AGENT_TYPE', defaultValue: 'kubernetes-pods', description: 'Enter agent type: kubernetes-pods or ec2')
        string(name: 'DEPLOY_TARGET', defaultValue: 'eks', description: 'Enter deployment target: eks, ec2, or both')
    }

    agent { label 'built-in' }

    environment {
        AWS_ACCOUNT_ID = '992398098051'
        AWS_REGION = 'us-east-1'
        ECR_REPOSITORY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        APP_NAME = 'aws-project'
        K8S_NAMESPACES = "jenkins,luxe-store-app,luxe-store-argo"
        EKS_CLUSTER_NAME = 'student-eks-cluster'
    }

    stages {

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push Frontend') {
            steps {
                dir('frontend') {

                    bat "docker build -t %ECR_REPOSITORY%/aws-project:%BUILD_NUMBER% ."
                    bat "docker tag %ECR_REPOSITORY%/aws-project:%BUILD_NUMBER% %ECR_REPOSITORY%/aws-project:latest"

                    withAWS(credentials: 'aws-credentials', region: AWS_REGION) {
                        bat "aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %ECR_REPOSITORY%"
                        bat "docker push %ECR_REPOSITORY%/aws-project:%BUILD_NUMBER%"
                        bat "docker push %ECR_REPOSITORY%/aws-project:latest"
                    }

                }
            }
        }

        stage('Deploy to EKS') {
            when {
                expression { params.DEPLOY_TARGET == 'eks' || params.DEPLOY_TARGET == 'both' }
            }
            steps {
                script {
                    withAWS(credentials: 'aws-credentials', region: AWS_REGION) {

                        echo "Updating kubeconfig for EKS..."
                        bat """
                        aws eks update-kubeconfig --name %EKS_CLUSTER_NAME% --region %AWS_REGION%
                        """

                        // Loop through all namespaces
                        def namespaces = K8S_NAMESPACES.split(',')
                        for (namespace in namespaces) {
                            echo "Deploying to namespace: ${namespace}..."
                            
                            echo "Creating namespace..."
                            bat """
                            kubectl create namespace ${namespace} --dry-run=client -o yaml | kubectl apply -f -
                            """

                            echo "Applying Kubernetes manifests..."
                            bat """
                            kubectl apply -f k8s/ -n ${namespace} --validate=false
                            """

                            echo "Updating deployment image..."
                            bat """
                            kubectl set image deployment/luxe-jewelry-frontend frontend=%ECR_REPOSITORY%/aws-project:%BUILD_NUMBER% -n ${namespace} || echo Deployment not created yet
                            """

                            echo "Waiting for rollout..."
                            bat """
                            kubectl rollout status deployment/luxe-jewelry-frontend -n ${namespace} --timeout=300s || echo Rollout failed or pending
                            """

                            bat "kubectl get pods -n ${namespace}"
                            bat "kubectl get svc -n ${namespace}"
                        }
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            when {
                expression { params.DEPLOY_TARGET == 'ec2' || params.DEPLOY_TARGET == 'both' }
            }
            steps {
                script {
                    withAWS(credentials: 'aws-credentials', region: AWS_REGION) {

                        echo "Fetching EC2 instance IP..."
                        def ec2Ip = bat(script: """
                            aws ec2 describe-instances --filters Name=tag:Name,Values=luxe-jewelry-app Name=instance-state-name,Values=running --query Reservations[0].Instances[0].PublicIpAddress --output text
                        """, returnStdout: true).trim()

                        echo "Deploying to EC2..."
                        bat """
                        ssh -o StrictHostKeyChecking=no -i C:/keys/key.pem ec2-user@${ec2Ip} "docker pull %ECR_REPOSITORY%/aws-project:latest && docker stop luxe-frontend || true && docker rm luxe-frontend || true && docker run -d -p 80:80 --name luxe-frontend %ECR_REPOSITORY%/aws-project:latest"
                        """
                    }
                }
            }
        }

    }

    post {
        always {
            script {
                withAWS(credentials: 'aws-credentials', region: 'us-east-1') {

                    def status = currentBuild.currentResult
                    def buildUrl = env.BUILD_URL
                    def projectName = env.JOB_NAME
                    def buildNumber = env.BUILD_NUMBER

                    def message = "Jenkins Build ${status}: ${projectName} #${buildNumber} - ${buildUrl}"

                    bat """
                    aws sns publish --topic-arn arn:aws:sns:us-east-1:992398098051:jenkins-build-notifications --subject "Jenkins Build ${status}" --message "${message}" --region us-east-1 || echo SNS failed
                    """
                }
            }
            echo 'Pipeline completed!'
        }

        success {
            echo '✅ Build and deployment successful! ✅'
        }

        failure {
            echo '❌ Build or deployment failed! ❌'
        }
    }
}
