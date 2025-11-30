pipeline {
    parameters {
        string(name: 'AGENT_TYPE', defaultValue: 'kubernetes-pods', description: 'Enter agent type: kubernetes-pods or ec2')
        string(name: 'DEPLOY_TARGET', defaultValue: 'eks', description: 'Enter deployment target: eks, ec2, or both')
    }
    agent {
        label 'built-in'
    }    
    environment {
        AWS_ACCOUNT_ID = '992398098051'
        AWS_REGION = 'us-east-1'
        ECR_REPOSITORY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        APP_NAME = 'aws-project'
        K8S_NAMESPACE = 'israel-app'
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
            steps {
                script {
                    withAWS(credentials: 'aws-credentials', region: AWS_REGION) {
                        // Update kubeconfig with IAM role authentication
                        bat "aws eks update-kubeconfig --name %EKS_CLUSTER_NAME% --region %AWS_REGION%"
                        
                        // Get IAM role ARN for the cluster
                        def roleArn = bat(script: "aws eks describe-cluster --name %EKS_CLUSTER_NAME% --region %AWS_REGION% --query cluster.roleArn --output text", returnStdout: true).trim()
                        
                        // Update kubeconfig to use IAM role
                        bat "kubectl config set-context %EKS_CLUSTER_NAME% --user=aws"
                        bat "kubectl config set-credentials aws --exec-command=aws --exec-command-api-version=client.authentication.k8s.io/v1beta1 --exec-command-arg=eks --exec-command-arg=get-token --exec-command-arg=cluster-name=%EKS_CLUSTER_NAME% --exec-command-arg=region=%AWS_REGION%"
                        
                        // Create namespace with validation disabled
                        bat "kubectl create namespace %K8S_NAMESPACE% --dry-run=client -o yaml | kubectl apply -f - --validate=false"
                        
                        // Apply all configurations
                        bat "kubectl apply -f k8s/ -n %K8S_NAMESPACE% --validate=false"
                        
                        // Update deployment with new image tag
                        bat "kubectl set image deployment/luxe-jewelry-frontend frontend=%ECR_REPOSITORY%/aws-project:%BUILD_NUMBER% -n %K8S_NAMESPACE% || echo 'Deployment may not exist yet'"
                        
                        // Wait for rollout
                        bat "kubectl rollout status deployment/luxe-jewelry-frontend -n %K8S_NAMESPACE% --timeout=300s || echo 'Rollout may not be ready'"
                        
                        // Show status
                        bat "kubectl get pods -n %K8S_NAMESPACE%"
                        bat "kubectl get services -n %K8S_NAMESPACE%"
                    }
                }
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                script {
                    withAWS(credentials: 'aws-credentials', region: AWS_REGION) {
                        // Get EC2 instance IP
                        def ec2Ip = bat(script: "aws ec2 describe-instances --filters Name=tag:Name,Values=luxe-jewelry-app Name=instance-state-name,Values=running --query Reservations[0].Instances[0].PublicIpAddress --output text", returnStdout: true).trim()
                        
                        // Deploy latest image to EC2
                        bat "ssh -o StrictHostKeyChecking=no -i /path/to/key.pem ec2-user@${ec2Ip} 'docker pull %ECR_REPOSITORY%/aws-project:latest && docker stop luxe-frontend || true && docker rm luxe-frontend || true && docker run -d -p 80:80 --name luxe-frontend %ECR_REPOSITORY%/aws-project:latest'"
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
