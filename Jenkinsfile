pipeline {
    parameters {
        string(name: 'AGENT_TYPE', defaultValue: 'kubernetes-pods', description: 'Enter agent type: kubernetes-pods or ec2')
        string(name: 'DEPLOY_TARGET', defaultValue: 'eks', description: 'Enter deployment target: eks, ec2, or both')
    }
    agent {
        label 'built-in || master || any'
    }    
    environment {
        AWS_ACCOUNT_ID = '992398098051'
        AWS_REGION = 'us-east-1'
        ECR_REPOSITORY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        APP_NAME = 'aws-project'
        K8S_NAMESPACE = 'israel-app'
    }
    
    stages {
        stage('Checkout Code') {
            steps { 
                checkout scm 
            }
        }
        
        stage('Build & Push Backend') {
            steps {
                dir('backend') {
                    bat "docker build -t %ECR_REPOSITORY%/luxe-jewelry-backend:%BUILD_NUMBER% ."
                    bat "docker tag %ECR_REPOSITORY%/luxe-jewelry-backend:%BUILD_NUMBER% %ECR_REPOSITORY%/luxe-jewelry-backend:latest"
                    withAWS(credentials: 'aws-credentials', region: AWS_REGION) {
                        bat "aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %ECR_REPOSITORY%"
                        bat "docker push %ECR_REPOSITORY%/luxe-jewelry-backend:%BUILD_NUMBER%"
                        bat "docker push %ECR_REPOSITORY%/luxe-jewelry-backend:latest"
                    }
                }
            }
        }
        
        stage('Build & Push Frontend') {
            steps {
                dir('frontend') {
                    bat "docker build -t %ECR_REPOSITORY%/luxe-jewelry-frontend:%BUILD_NUMBER% ."
                    bat "docker tag %ECR_REPOSITORY%/luxe-jewelry-frontend:%BUILD_NUMBER% %ECR_REPOSITORY%/luxe-jewelry-frontend:latest"
                    withAWS(credentials: 'aws-credentials', region: AWS_REGION) {
                        bat "aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %ECR_REPOSITORY%"
                        bat "docker push %ECR_REPOSITORY%/luxe-jewelry-frontend:%BUILD_NUMBER%"
                        bat "docker push %ECR_REPOSITORY%/luxe-jewelry-frontend:latest"
                    }
                }
            }
        }
        
        stage('Deploy to EKS') {
            steps {
                withKubeConfig([credentialsId: 'k8s-credentials']) {
                    bat "kubectl create namespace %K8S_NAMESPACE% --dry-run=client -o yaml | kubectl apply -f -"
                    
                    // Update deployment with new image tags
                    bat "kubectl set image deployment/luxe-jewelry-backend backend=%ECR_REPOSITORY%/luxe-jewelry-backend:%BUILD_NUMBER% -n %K8S_NAMESPACE%"
                    bat "kubectl set image deployment/luxe-jewelry-frontend frontend=%ECR_REPOSITORY%/luxe-jewelry-frontend:%BUILD_NUMBER% -n %K8S_NAMESPACE%"
                    
                    // Apply all configurations
                    bat "kubectl apply -f k8s/ -n %K8S_NAMESPACE%"
                    
                    // Wait for rollout
                    bat "kubectl rollout status deployment/luxe-jewelry-backend -n %K8S_NAMESPACE% --timeout=300s"
                    bat "kubectl rollout status deployment/luxe-jewelry-frontend -n %K8S_NAMESPACE% --timeout=300s"
                    
                    // Show status
                    bat "kubectl get pods -n %K8S_NAMESPACE%"
                    bat "kubectl get services -n %K8S_NAMESPACE%"
                }
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                script {
                    withAWS(credentials: 'aws-credentials', region: AWS_REGION) {
                        // Get EC2 instance IP
                        def ec2Ip = bat(script: "aws ec2 describe-instances --filters Name=tag:Name,Values=luxe-jewelry-app Name=instance-state-name,Values=running --query Reservations[0].Instances[0].PublicIpAddress --output text", returnStdout: true).trim()
                        
                        // Deploy latest images to EC2
                        bat "ssh -o StrictHostKeyChecking=no -i /path/to/key.pem ec2-user@${ec2Ip} 'docker pull %ECR_REPOSITORY%/luxe-jewelry-backend:latest && docker pull %ECR_REPOSITORY%/luxe-jewelry-frontend:latest && docker stop luxe-backend || true && docker rm luxe-backend || true && docker stop luxe-frontend || true && docker rm luxe-frontend || true && docker run -d -p 3000:3000 --name luxe-backend %ECR_REPOSITORY%/luxe-jewelry-backend:latest && docker run -d -p 80:80 --name luxe-frontend %ECR_REPOSITORY%/luxe-jewelry-frontend:latest'"
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
                    
                    bat "aws sns publish --topic-arn arn:aws:sns:us-east-1:992398098051:jenkins-build-notifications --subject \"Jenkins Build ${status}\" --message \"${message}\" --region us-east-1 || echo SNS notification failed"
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
