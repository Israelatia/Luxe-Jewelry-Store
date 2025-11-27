pipeline {
    agent {
        label params.AGENT_TYPE
    }
    
    parameters {
        choice(
            name: 'AGENT_TYPE',
            choices: ['ec2-agents', 'kubernetes-pods'],
            description: 'Choose agent type: EC2 Auto Scaling Group or Kubernetes pods'
        )
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
            steps {
                withKubeConfig([credentialsId: 'k8s-credentials']) {
                    bat "kubectl create namespace %K8S_NAMESPACE% --dry-run=client -o yaml | kubectl apply -f -"
                    bat "kubectl apply -f k8s/ -n %K8S_NAMESPACE%"
                    bat "kubectl get pods -n %K8S_NAMESPACE%"
                }
            }
        }
    }
    
    post {
        always {
            script {
                withAWS(credentials: 'aws-credentials', region: AWS_REGION) {
                    def status = currentBuild.currentResult
                    def buildUrl = env.BUILD_URL
                    def projectName = env.JOB_NAME
                    def buildNumber = env.BUILD_NUMBER
                    
                    def message = "Jenkins Build ${status}: ${projectName} #${buildNumber} - ${buildUrl}"
                    
                    bat "aws sns publish --topic-arn arn:aws:sns:%AWS_REGION%:%AWS_ACCOUNT_ID%:jenkins-build-notifications --subject \"Jenkins Build ${status}\" --message \"${message}\" --region %AWS_REGION% || echo SNS notification failed"
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
