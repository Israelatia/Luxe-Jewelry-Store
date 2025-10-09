@Library('luxe-shared-library') _

pipeline {
    agent {
        kubernetes {
            yaml '''
                apiVersion: v1
                kind: Pod
                metadata:
                  labels:
                    app: luxe-jenkins-agent
                spec:
                  serviceAccountName: jenkins-agent
                  containers:
                  - name: jnlp
                    image: jenkins/inbound-agent:latest
                    args: ['\$(JENKINS_SECRET)', '\$(JENKINS_NAME)']
                    resources:
                      limits:
                        cpu: "1"
                        memory: "1Gi"
                      requests:
                        cpu: "500m"
                        memory: "512Mi"
                  - name: docker
                    image: docker:20.10.21-dind
                    securityContext:
                      privileged: true
                    resources:
                      limits:
                        cpu: "1"
                        memory: "1Gi"
                      requests:
                        cpu: "500m"
                        memory: "512Mi"
                  - name: kubectl
                    image: bitnami/kubectl:latest
                    command:
                    - cat
                    tty: true
                    resources:
                      limits:
                        cpu: "500m"
                        memory: "512Mi"
                      requests:
                        cpu: "100m"
                        memory: "128Mi"
            '''
        }
    }

    environment {
        DOCKER_HUB_REGISTRY = 'docker.io/israelatia'
        NEXUS_REGISTRY = 'localhost:8082'
        DOCKER_REGISTRY = "${params.TARGET_REGISTRY == 'docker.io' ? DOCKER_HUB_REGISTRY : NEXUS_REGISTRY}"
        APP_NAME = 'luxe-jewelry-store'
        SEMVER_VERSION = "1.0.${env.BUILD_NUMBER}"
        DOCKER_BUILDKIT = 1
        COMPOSE_DOCKER_CLI_BUILD = 1
        SNYK_TOKEN = credentials('snyk')
        KUBECONFIG = "${env.WORKSPACE}/.kube/config"
        K8S_NAMESPACE = 'demo-app'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '30'))
        disableConcurrentBuilds()
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
    }

    parameters {
        choice(name: 'TARGET_REGISTRY', choices: ['docker.io', 'localhost:8082'], description: 'Target Docker registry')
        choice(name: 'DEPLOY_ENVIRONMENT', choices: ['development', 'staging', 'production', 'none'], description: 'Target environment for deployment')
        booleanParam(name: 'PUSH_TO_NEXUS', defaultValue: true, description: 'Push images to Nexus registry')
        booleanParam(name: 'PUSH_TO_DOCKERHUB', defaultValue: true, description: 'Push images to Docker Hub')
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
                    sh '''
                        git config --global --add safe.directory '*'
                        git config --global --add safe.directory ${WORKSPACE}
                    '''
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/main']],
                        userRemoteConfigs: [[
                            url: 'https://github.com/Israelatia/Luxe-Jewelry-Store.git',
                            credentialsId: '4ca4b912-d2aa-4af3-bc7b-0e12d9b88542'
                        ]],
                        extensions: [[ $class: 'CleanBeforeCheckout' ]]
                    ])
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
                        always {
                            junit allowEmptyResults: true, testResults: 'backend/results.xml'
                        }
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
                        script {
                            buildDockerImage(
                                imageName: "${APP_NAME}-backend",
                                dockerFile: 'backend/Dockerfile',
                                buildContext: '.',
                                registry: DOCKER_REGISTRY,
                                tags: [SEMVER_VERSION, IMAGE_TAG_COMMIT, 'latest']
                            )
                        }
                    }
                }

                stage('Frontend Image') {
                    steps {
                        script {
                            buildDockerImage(
                                imageName: "${APP_NAME}-frontend",
                                dockerFile: 'frontend/Dockerfile',
                                buildContext: '.',
                                registry: DOCKER_REGISTRY,
                                tags: [SEMVER_VERSION, IMAGE_TAG_COMMIT, 'latest']
                            )
                        }
                    }
                }
            }
        }

        stage('Push Images') {
            parallel {
                stage('Push to Docker Hub') {
                    when { expression { params.PUSH_TO_DOCKERHUB } }
                    steps {
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

                stage('Push to Nexus') {
                    when { expression { params.PUSH_TO_NEXUS && params.TARGET_REGISTRY == 'localhost:8082' } }
                    steps {
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

        stage('Security Scan') {
            steps {
                withEnv(["SNYK_TOKEN=${SNYK_TOKEN}"]) {
                    sh """
                        snyk container test ${DOCKER_REGISTRY}/${APP_NAME}-backend:latest --file=backend/Dockerfile --severity-threshold=high
                        snyk container test ${DOCKER_REGISTRY}/${APP_NAME}-frontend:latest --file=frontend/Dockerfile --severity-threshold=high
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            when { expression { params.DEPLOY_ENVIRONMENT != 'none' } }
            steps {
                script {
                    // Ensure namespace exists
                    sh """
                        kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                    """
                    
                    // Apply Kubernetes manifests
                    dir('k8s') {
                        // Apply PVCs first
                        sh 'kubectl apply -f pvc.yaml -n ${K8S_NAMESPACE}'
                        
                        // Apply secrets if they exist
                        if (fileExists('secrets.yaml')) {
                            sh 'kubectl apply -f secrets.yaml -n ${K8S_NAMESPACE}'
                        }
                        
                        // Apply config maps if they exist
                        if (fileExists('configmap.yaml')) {
                            sh 'kubectl apply -f configmap.yaml -n ${K8S_NAMESPACE}'
                        }
                        
                        // Apply deployments and services
                        sh 'kubectl apply -f backend-deployment.yaml,backend-service.yaml -n ${K8S_NAMESPACE}'
                        sh 'kubectl apply -f frontend-deployment.yaml,frontend-service.yaml -n ${K8S_NAMESPACE}'
                        
                        // Apply HPA if exists
                        if (fileExists('hpa.yaml')) {
                            sh 'kubectl apply -f hpa.yaml -n ${K8S_NAMESPACE}'
                        }
                        
                        // Apply ingress if exists and not in production
                        if (fileExists('ingress.yaml') && params.DEPLOY_ENVIRONMENT != 'production') {
                            sh 'kubectl apply -f ingress.yaml -n ${K8S_NAMESPACE}'
                        }
                    }
                    
                    // Wait for rollout to complete
                    sh """
                        kubectl rollout status deployment/luxe-backend -n ${K8S_NAMESPACE} --timeout=300s
                        kubectl rollout status deployment/luxe-frontend -n ${K8S_NAMESPACE} --timeout=300s
                    """
                    
                    // Get application URLs
                    def frontendUrl = sh(script: "minikube service --url luxe-frontend -n ${K8S_NAMESPACE}", returnStdout: true).trim()
                    echo "Frontend is available at: ${frontendUrl}"
                }
            }
                    deployApplication(
                        environment: params.DEPLOY_ENVIRONMENT,
                        registry: DOCKER_REGISTRY,
                        appName: APP_NAME,
                        composeFile: "docker-compose.${params.DEPLOY_ENVIRONMENT}.yml",
                        healthCheck: true,
                        timeout: 300
                    )
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up Docker images and temporary files from Jenkins agent...'
            sh 'docker system prune -f || true'
        }
    }
}
