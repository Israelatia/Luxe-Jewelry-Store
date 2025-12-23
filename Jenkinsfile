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
        // Hardcoded path for the Windows Jenkins environment
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
    }

      stage('Deploy to EKS') {
    steps {
        withAWS(region: 'us-east-1') {
            script {
                echo "Refreshing Kubeconfig..."
                bat 'aws eks update-kubeconfig --name student-eks-cluster --region us-east-1 --kubeconfig C:\\Users\\israel\\.kube\\config'
                
                echo "Deploying to namespace: app..."
                // Use -n app here
                bat 'kubectl apply -f k8s/ -n app --kubeconfig=C:\\Users\\israel\\.kube\\config'
                
                echo "Waiting for Kubernetes to register objects..."
                sleep(time: 10, unit: 'SECONDS') // Replaces the failing 'bat timeout'
                
                echo "Updating deployment image..."
                // Update the deployment name and namespace here
                bat 'kubectl set image deployment/luxe-jewelry-frontend frontend=992398098051.dkr.ecr.us-east-1.amazonaws.com/aws-project:99 -n app --kubeconfig=C:\\Users\\israel\\.kube\\config'
                
                echo "Waiting for rollout..."
                bat 'kubectl rollout status deployment/luxe-jewelry-frontend -n app --timeout=120s --kubeconfig=C:\\Users\\israel\\.kube\\config'
            }
        }
    }
}
}