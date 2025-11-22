pipeline {
    agent any

    environment {
        // AWS Configuration
        AWS_ACCOUNT_ID = '992398098051'
        AWS_REGION = 'us-east-1'
        ECR_REPOSITORY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        APP_NAME = 'luxe-jewelry-store'
        K8S_NAMESPACE = 'israel-app'
    }

    parameters {
        choice(
            name: 'AGENT_TYPE',
            choices: ['kubernetes', 'ec2'],
            description: 'Select agent type'
        )
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
                    sh "docker build -t ${ECR_REPOSITORY}/${APP_NAME}-backend:latest ."
                    withAWS(credentials: 'aws-credentials', region: AWS_REGION) {
                        sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPOSITORY}"
                        sh "docker push ${ECR_REPOSITORY}/${APP_NAME}-backend:latest"
                    }
                }
            }
        }

        stage('Build & Push Frontend') {
            steps {
                dir('frontend') {
                    sh "docker build -t ${ECR_REPOSITORY}/${APP_NAME}-frontend:latest ."
                    withAWS(credentials: 'aws-credentials', region: AWS_REGION) {
                        sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPOSITORY}"
                        sh "docker push ${ECR_REPOSITORY}/${APP_NAME}-frontend:latest"
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            when {
                branch 'main'
            }
            steps {
                withKubeConfig([credentialsId: 'k8s-credentials']) {
                    sh "kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -"
                    sh "kubectl apply -f k8s/ -n ${K8S_NAMESPACE}"
                    sh "kubectl get pods -n ${K8S_NAMESPACE}"
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

                    def message = """
Jenkins Build Notification
Project: ${projectName}
Build Number: ${buildNumber}
Status: ${status}
Build URL: ${buildUrl}
Timestamp: ${new Date().format('yyyy-MM-dd HH:mm:ss')}
"""

                    sh """
                        aws sns publish \
                            --topic-arn arn:aws:sns:${AWS_REGION}:${AWS_ACCOUNT_ID}:jenkins-build-notifications \
                            --subject "Jenkins Build ${status}: ${projectName} #${buildNumber}" \
                            --message "${message}" \
                            --region ${AWS_REGION} || echo "SNS notification failed"
                    """
                }
            }
            echo 'Pipeline completed!'
        }
        success {
            echo 'Build and deployment successful!'
        }
        failure {
            echo 'Build or deployment failed!'
        }
    }
}

