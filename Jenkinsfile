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
                        
                        // *** FINAL FIX: Explicitly define KUBECONFIG path to avoid Windows user/home directory confusion ***
                        withEnv([
                            "AWS_ACCESS_KEY_ID=${env.AWS_ACCESS_KEY_ID}", 
                            "AWS_SECRET_ACCESS_KEY=${env.AWS_SECRET_ACCESS_KEY}",
                            "AWS_DEFAULT_REGION=${AWS_REGION}",
                            "KUBECONFIG=C:\\Users\\israel\\.kube\\config" // Ensure using double backslashes for Groovy string literal
                        ]) {

                            echo "Updating kubeconfig for EKS..."
                            bat "if exist C:\\Users\\israel\\.kube\\config del C:\\Users\\israel\\.kube\\config"
                            bat "aws eks update-kubeconfig --name %EKS_CLUSTER_NAME% --region %AWS_REGION% --kubeconfig C:\\Users\\israel\\.kube\\config"
                            
                            echo "Testing EKS connectivity..."
                            bat "kubectl cluster-info --kubeconfig=C:\\Users\\israel\\.kube\\config"
                            
                            echo "Verifying AWS credentials and kubectl access..."
                            bat "aws sts get-caller-identity --region %AWS_REGION%"
                            bat "kubectl auth can-i get pods --kubeconfig=C:\\Users\\israel\\.kube\\config || echo Authentication failed - checking kubeconfig"
                            bat "type C:\\Users\\israel\\.kube\\config"
                            
                            echo "Sending EKS deployment start notification..."
                            bat "aws sns publish --topic-arn arn:aws:sns:us-east-1:992398098051:jenkins-build-notifications --subject \"EKS Deployment Started\" --message \"Starting EKS deployment for build #%BUILD_NUMBER% to cluster: %EKS_CLUSTER_NAME%\" --region us-east-1 || echo SNS start notification failed"

                            // Loop through all namespaces
                            def namespaces = K8S_NAMESPACES.split(',')
                            for (namespace in namespaces) {
                                echo "Deploying to namespace: ${namespace}..."
                                
                                // --- DEPLOYMENT BLOCK ---
                                bat """
                                echo Applying manifests for namespace: ${namespace}...
                                kubectl apply -f k8s/ -n ${namespace} --validate=false --exclude=namespaces.yaml --kubeconfig=C:\\Users\\israel\\.kube\\config
                                
                                echo Updating deployment image...
                                kubectl set image deployment/luxe-jewelry-frontend frontend=%ECR_REPOSITORY%/aws-project:%BUILD_NUMBER% -n ${namespace} --kubeconfig=C:\\Users\\israel\\.kube\\config || echo Deployment not created yet

                                echo Waiting for rollout...
                                kubectl rollout status deployment/luxe-jewelry-frontend -n ${namespace} --timeout=300s --kubeconfig=C:\\Users\\israel\\.kube\\config || echo Rollout failed or pending

                                kubectl get pods -n ${namespace} --kubeconfig=C:\\Users\\israel\\.kube\\config
                                kubectl get svc -n ${namespace} --kubeconfig=C:\\Users\\israel\\.kube\\config
                                """
                            }
                            
                            echo "Sending EKS deployment completion notification..."
                            bat "aws sns publish --topic-arn arn:aws:sns:us-east-1:992398098051:jenkins-build-notifications --subject \"EKS Deployment Completed\" --message \"EKS deployment completed for build #%BUILD_NUMBER% to cluster: %EKS_CLUSTER_NAME%. Deployed to namespaces: %K8S_NAMESPACES%\" --region us-east-1 || echo SNS completion notification failed"
                        } 
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