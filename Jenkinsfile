pipeline {
    agent any
    
    environment {
        // AWS Configuration
        AWS_ACCOUNT_ID = '992398098051'
        AWS_REGION = 'us-east-1'
        ECR_REPOSITORY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        APP_NAME = 'luxe-jewelry-store'
        K8S_NAMESPACE = 'demo-app'
    }
    
    parameters {
        choice(
            name: 'AGENT_TYPE',
            choices: ['kubernetes', 'ec2'],
            description: 'Select agent type',
            defaultValue: 'kubernetes'
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
                        sh "aws ecr get-login-password | docker login --username AWS --password-stdin ${ECR_REPOSITORY}"
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
                        sh "aws ecr get-login-password | docker login --username AWS --password-stdin ${ECR_REPOSITORY}"
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
            echo 'Pipeline completed!'
        }
        success {
            echo '✅ Build and deployment successful! ✅'
        }
        failure {
            echo '❌ Build or deployment failed! ❌'
        }
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '30'))
        disableConcurrentBuilds()
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
    }

    parameters {
        choice(name: 'TARGET_REGISTRY', choices: ['ecr', 'docker.io', 'localhost:8082'], description: 'Target Docker registry')
        choice(name: 'DEPLOY_ENVIRONMENT', choices: ['development', 'staging', 'production', 'none'], description: 'Target environment for deployment')
        booleanParam(name: 'PUSH_TO_NEXUS', defaultValue: true, description: 'Push images to Nexus registry')
        booleanParam(name: 'PUSH_TO_DOCKERHUB', defaultValue: false, description: 'Push images to Docker Hub')
        booleanParam(name: 'PUSH_TO_ECR', defaultValue: true, description: 'Push images to AWS ECR')
    }

    stages {

        stage('Clean Workspace') {
            steps {
                deleteDir()
            }
        }

        stage('Checkout') {
            steps {
                script {
                    sh """
                        git config --global --add safe.directory '*'
                        git config --global --add safe.directory ${WORKSPACE}
                        git config --global user.email "jenkins@localhost"
                        git config --global user.name "Jenkins"
                    """
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/main']],
                        userRemoteConfigs: [[
                            url: 'https://github.com/Israelatia/Luxe-Jewelry-Store.git',
                            credentialsId: '4ca4b912-d2aa-4af3-bc7b-0e12d9b88542'
                        ]],
                        extensions: [[ $class: 'CleanBeforeCheckout' ]]
                    ])
                    sh 'ls -la'
                    env.GIT_COMMIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.IMAGE_TAG_COMMIT = "commit-${env.GIT_COMMIT_SHORT}"
                }
            }
        }

        stage('Backend Setup & Tests') {
            steps {
                dir('backend') {
                    sh '''
                        python3 -m venv venv
                        . venv/bin/activate
                        pip install --upgrade pip
                        pip install -r requirements.txt
                    '''
                }
            }
        }

        stage('Unit Tests & Lint') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        dir('backend') {
                            sh '''
                                . venv/bin/activate
                                python3 -m pytest --junitxml results.xml tests/*.py
                            '''
                        }
                    }
                    post {
                        always { junit allowEmptyResults: true, testResults: 'backend/results.xml' }
                    }
                }

                stage('Code Lint') {
                    steps {
                        dir('backend') {
                            sh '''
                                . venv/bin/activate
                                python3 -m pylint *.py --exit-zero --output-format=parseable > pylint-report.txt || true
                            '''
                        }
                        publishWarnings parsers: [pylint(pattern: 'backend/pylint-report.txt')]
                    }
                }
            }
        }

        stage('Build Docker Images') {
            parallel {
                stage('Backend Image') {
                    steps {
                        container('jenkins-agent') {
                            script {
                                def imageName = params.TARGET_REGISTRY == 'ecr' ? 
                                    "${ECR_REPOSITORY}/${ECR_IMAGE_NAME}-backend" : 
                                    "${DOCKER_REGISTRY}/${APP_NAME}-backend"
                                
                                buildDockerImage(
                                    imageName: imageName,
                                    dockerFile: 'backend/Dockerfile',
                                    buildContext: '.',
                                    registry: params.TARGET_REGISTRY == 'ecr' ? ECR_REPOSITORY : DOCKER_REGISTRY,
                                    tags: [SEMVER_VERSION, IMAGE_TAG_COMMIT, 'latest']
                                )
                            }
                        }
                    }
                }

                stage('Frontend Image') {
                    steps {
                        container('jenkins-agent') {
                            script {
                                def imageName = params.TARGET_REGISTRY == 'ecr' ? 
                                    "${ECR_REPOSITORY}/${ECR_IMAGE_NAME}-frontend" : 
                                    "${DOCKER_REGISTRY}/${APP_NAME}-frontend"
                                
                                buildDockerImage(
                                    imageName: imageName,
                                    dockerFile: 'frontend/Dockerfile',
                                    buildContext: '.',
                                    registry: params.TARGET_REGISTRY == 'ecr' ? ECR_REPOSITORY : DOCKER_REGISTRY,
                                    tags: [SEMVER_VERSION, IMAGE_TAG_COMMIT, 'latest']
                                )
                            }
                        }
                    }
                }
            }
        }

        stage('Push Images') {
            parallel {
                stage('Push to Docker Hub') {
                    when { 
                        allOf {
                            expression { params.PUSH_TO_DOCKERHUB }
                            expression { params.TARGET_REGISTRY == 'docker.io' }
                        }
                    }
                    steps {
                        container('jenkins-agent') {
                            script {
                                pushToRegistry(
                                    imageName: "${DOCKER_HUB_REGISTRY}/${APP_NAME}-backend",
                                    tags: [SEMVER_VERSION, IMAGE_TAG_COMMIT, 'latest'],
                                    credentialsId: 'docker-hub',
                                    registry: 'docker.io'
                                )
                                pushToRegistry(
                                    imageName: "${DOCKER_HUB_REGISTRY}/${APP_NAME}-frontend",
                                    tags: [SEMVER_VERSION, IMAGE_TAG_COMMIT, 'latest'],
                                    credentialsId: 'docker-hub',
                                    registry: 'docker.io'
                                )
                            }
                        }
                    }
                }
                
                stage('Push to ECR') {
                    when { 
                        allOf {
                            expression { params.PUSH_TO_ECR }
                            expression { params.TARGET_REGISTRY == 'ecr' }
                        }
                    }
                    steps {
                        container('jenkins-agent') {
                            script {
                                // Login to ECR
                                withAWS(credentials: 'aws-credentials', region: AWS_REGION) {
                                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPOSITORY}"
                                    
                                    // Push backend image
                                    def backendImage = "${ECR_REPOSITORY}/${ECR_IMAGE_NAME}-backend:${SEMVER_VERSION}"
                                    sh "docker tag ${ECR_REPOSITORY}/${ECR_IMAGE_NAME}-backend:${SEMVER_VERSION} ${backendImage}"
                                    sh "docker push ${backendImage}"
                                    
                                    // Push frontend image
                                    def frontendImage = "${ECR_REPOSITORY}/${ECR_IMAGE_NAME}-frontend:${SEMVER_VERSION}"
                                    sh "docker tag ${ECR_REPOSITORY}/${ECR_IMAGE_NAME}-frontend:${SEMVER_VERSION} ${frontendImage}"
                                    sh "docker push ${frontendImage}"
                                }
                            }
                        }
                    }
                }

                stage('Push to Nexus') {
                    when { expression { params.PUSH_TO_NEXUS && params.TARGET_REGISTRY == 'localhost:8082' } }
                    steps {
                        container('jenkins-agent') {
                            script {
                                pushToRegistry(
                                    imageName: "${NEXUS_REGISTRY}/${APP_NAME}-backend",
                                    tags: [SEMVER_VERSION],
                                    credentialsId: 'nexus-cred',
                                    registry: NEXUS_REGISTRY
                                )
                                pushToRegistry(
                                    imageName: "${NEXUS_REGISTRY}/${APP_NAME}-frontend",
                                    tags: [SEMVER_VERSION],
                                    credentialsId: 'nexus-docker',
                                    registry: NEXUS_REGISTRY
                                )
                            }
                        }
                    }
                }
            }
        }

        stage('Security Scan') {
            steps {
                container('jenkins-agent') {
                    withEnv(["SNYK_TOKEN=${SNYK_TOKEN}"]) {
                        sh """
                            snyk container test ${DOCKER_REGISTRY}/${APP_NAME}-backend:latest --file=backend/Dockerfile --severity-threshold=high
                            snyk container test ${DOCKER_REGISTRY}/${APP_NAME}-frontend:latest --file=frontend/Dockerfile --severity-threshold=high
                        """
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            when { expression { params.DEPLOY_ENVIRONMENT != 'none' } }
            steps {
                container('jenkins-agent') {
                    script {
                        sh "kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -"
                        dir('k8s') {
                            sh 'kubectl apply -f pvc.yaml -n ${K8S_NAMESPACE}'
                            if (fileExists('secrets.yaml')) { sh 'kubectl apply -f secrets.yaml -n ${K8S_NAMESPACE}' }
                            if (fileExists('configmap.yaml')) { sh 'kubectl apply -f configmap.yaml -n ${K8S_NAMESPACE}' }
                            sh 'kubectl apply -f backend-deployment.yaml,backend-service.yaml -n ${K8S_NAMESPACE}'
                            sh 'kubectl apply -f frontend-deployment.yaml,frontend-service.yaml -n ${K8S_NAMESPACE}'
                            if (fileExists('hpa.yaml')) { sh 'kubectl apply -f hpa.yaml -n ${K8S_NAMESPACE}' }
                            if (fileExists('ingress.yaml') && params.DEPLOY_ENVIRONMENT != 'production') {
                                sh 'kubectl apply -f ingress.yaml -n ${K8S_NAMESPACE}'
                            }
                        }
                        sh """
                            kubectl rollout status deployment/luxe-backend -n ${K8S_NAMESPACE} --timeout=300s
                            kubectl rollout status deployment/luxe-frontend -n ${K8S_NAMESPACE} --timeout=300s
                        """
                        def frontendUrl = sh(script: "minikube service --url luxe-frontend -n ${K8S_NAMESPACE}", returnStdout: true).trim()
                        echo "Frontend is available at: ${frontendUrl}"
                        echo 'Deployment completed successfully'
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                // Send SNS notification
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
            echo "Pipeline completed."
        }
    }
}

