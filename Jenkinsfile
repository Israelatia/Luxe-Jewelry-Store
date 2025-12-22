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
        // Hardcoded KUBECONFIG path for the Israel user on the Windows Jenkins node
        KUBECONFIG = "C:\\Users\\israel\\.kube\\config"
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
                    // Ensure 'aws-credentials' in Jenkins matches the 'aws-user' keys
                    withAWS(credentials: 'aws-credentials', region: AWS_REGION) {
                        bat """
                        aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %ECR_REPOSITORY%
                        docker build -t %ECR_REPOSITORY%/aws-project:%BUILD_NUMBER% .
                        docker tag %ECR_REPOSITORY%/aws-project:%BUILD_NUMBER% %ECR_REPOSITORY%/aws-project:latest
                        docker push %ECR_REPOSITORY%/aws-project:%BUILD_NUMBER%
                        docker push %ECR_REPOSITORY%/aws-project:latest
                        """
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            when {
                expression { params.DEPLOY_TARGET == 'eks' || params.DEPLOY_TARGET == 'both' }
            }
            steps {
                withAWS(credentials: 'aws-credentials', region: AWS_REGION) {
                    script {
                        // Pass Jenkins credentials to the environment for the 'aws' command
                        withEnv([
                            "AWS_ACCESS_KEY_ID=${env.AWS_ACCESS_KEY_ID}", 
                            "AWS_SECRET_ACCESS_KEY=${env.AWS_SECRET_ACCESS_KEY}",
                            "AWS_SESSION_TOKEN=${env.AWS_SESSION_TOKEN ?: ''}"
                        ]) {

                            echo "Verifying Active Identity..."
                            bat "aws sts get-caller-identity"

                            echo "Refreshing Kubeconfig for aws-user..."
                            // Delete old config to ensure no session conflicts
                            bat "if exist %KUBECONFIG% del %KUBECONFIG%"
                            bat "aws eks update-kubeconfig --name %EKS_CLUSTER_NAME% --region %AWS_REGION% --kubeconfig %KUBECONFIG%"
                            
                            echo "Testing EKS access..."
                            // This should now succeed because of the Access Policy association
                            bat "kubectl cluster-info --kubeconfig=%KUBECONFIG%"
                            
                            echo "Sending EKS deployment start notification..."
                            bat "aws sns publish --topic-arn arn:aws:sns:us-east-1:992398098051:jenkins-build-notifications --subject \"EKS Deployment Started\" --message \"Starting EKS deployment for build #%BUILD_NUMBER%\" --region %AWS_REGION%"

                            def namespaces = K8S_NAMESPACES.split(',')
                            for (namespace in namespaces) {
                                echo "Deploying to namespace: ${namespace}..."
                                
                                bat """
                                echo Applying manifests to ${namespace}...
                                kubectl apply -f k8s/ -n ${namespace} --validate=false --exclude=namespaces.yaml --kubeconfig=%KUBECONFIG%
                                
                                echo Updating deployment image...
                                kubectl set image deployment/luxe-jewelry-frontend frontend=%ECR_REPOSITORY%/aws-project:%BUILD_NUMBER% -n ${namespace} --kubeconfig=%KUBECONFIG% || echo 'Deployment not found'
                                
                                echo Waiting for rollout...
                                kubectl rollout status deployment/luxe-jewelry-frontend -n ${namespace} --timeout=120s --kubeconfig=%KUBECONFIG%
                                """
                            }
                            
                            bat "aws sns publish --topic-arn arn:aws:sns:us-east-1:992398098051:jenkins-build-notifications --subject \"EKS Deployment Completed\" --message \"Build #%BUILD_NUMBER% deployed to all namespaces.\" --region %AWS_REGION%"
                        } 
                    } 
                } 
            }
        }
    }

    post {
        always {
            script {
                withAWS(credentials: 'aws-credentials', region: AWS_REGION) {
                    def status = currentBuild.currentResult
                    def message = "Jenkins Build ${status}: ${env.JOB_NAME} #${env.BUILD_NUMBER} - ${env.BUILD_URL}"
                    bat "aws sns publish --topic-arn arn:aws:sns:us-east-1:992398098051:jenkins-build-notifications --subject \"Jenkins Build ${status}\" --message \"${message}\" --region %AWS_REGION%"
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