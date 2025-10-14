pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: jenkins-agent
    image: 'YOUR_DOCKERHUB_USERNAME/jenkins-agent:latest'

    command:
    - cat
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
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
            steps { deleteDir() }
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

    post {
        always {
            echo "Pipeline completed."
        }
    }
}
