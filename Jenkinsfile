pipeline {
    parameters {
        string(name: 'AGENT_TYPE', defaultValue: 'kubernetes-pods', description: 'Enter agent type: kubernetes-pods or ec2')
        string(name: 'DEPLOY_TARGET', defaultValue: 'eks', description: 'Enter deployment target: eks, ec2, or both')
    }
    agent {
        label params.AGENT_TYPE == 'ec2' ? 'ec2-agent || linux || docker' : 'kubernetes || linux || docker'
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
                    bat "docker build -t %ECR_REPOSITORY%/aws-project:latest ."
                    withAWS(credentials: 'aws-credentials', region: AWS_REGION) {
                        bat "aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %ECR_REPOSITORY%"
                        bat "docker push %ECR_REPOSITORY%/aws-project:latest"
                    }
                }
            }
        }
        
        stage('Build & Push Frontend') {
            steps {
                dir('frontend') {
                    bat "docker build -t %ECR_REPOSITORY%/aws-project:latest ."
                    withAWS(credentials: 'aws-credentials', region: AWS_REGION) {
                        bat "aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %ECR_REPOSITORY%"
                        bat "docker push %ECR_REPOSITORY%/aws-project:latest"
                    }
                }
            }
        }
        
        stage('Deploy to EKS') {
            when {
                anyOf {
                    expression { params.DEPLOY_TARGET == 'eks' }
                    expression { params.DEPLOY_TARGET == 'both' }
                }
            }
            steps {
                withKubeConfig([credentialsId: 'k8s-credentials']) {
                    bat "kubectl create namespace %K8S_NAMESPACE% --dry-run=client -o yaml | kubectl apply -f -"
                    bat "kubectl apply -f k8s/ -n %K8S_NAMESPACE%"
                    bat "kubectl get pods -n %K8S_NAMESPACE%"
                }
            }
        }
        
        stage('Deploy to EC2') {
            when {
                anyOf {
                    expression { params.DEPLOY_TARGET == 'ec2' }
                    expression { params.DEPLOY_TARGET == 'both' }
                }
            }
            steps {
                script {
                    // SSH to EC2 and deploy
                    withAWS(credentials: 'aws-credentials', region: AWS_REGION) {
                        // Get EC2 instance IP
                        def ec2Ip = bat(script: "aws ec2 describe-instances --filters Name=tag:Name,Values=luxe-jewelry-app Name=instance-state-name,Values=running --query Reservations[0].Instances[0].PublicIpAddress --output text", returnStdout: true).trim()
                        
                        // Deploy to EC2
                        bat "ssh -o StrictHostKeyChecking=no -i /path/to/key.pem ec2-user@${ec2Ip} 'docker pull %ECR_REPOSITORY%/aws-project:latest && docker stop luxe-app || true && docker rm luxe-app || true && docker run -d -p 80:3000 --name luxe-app %ECR_REPOSITORY%/aws-project:latest'"
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
