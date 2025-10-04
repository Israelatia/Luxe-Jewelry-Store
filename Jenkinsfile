@Library('luxe-shared-library') _

pipeline {
    agent {
        docker {
            image 'israelatia/luxe-jenkins-agent:latest'
            args '--user root -v /var/run/docker.sock:/var/run/docker.sock -e GIT_DISCOVERY_ACROSS_FILESYSTEM=1'
        }
    }

    parameters {
        string(name: 'TARGET_REGISTRY', defaultValue: 'docker.io', description: 'Target registry (docker.io or localhost:8082)')
        booleanParam(name: 'PUSH_TO_DOCKERHUB', defaultValue: true, description: 'Push images to Docker Hub')
        booleanParam(name: 'PUSH_TO_NEXUS', defaultValue: true, description: 'Push images to Nexus')
        choice(
            name: 'DEPLOY_ENVIRONMENT',
            choices: ['none', 'dev', 'stage', 'prod'],
            description: 'Deployment environment'
        )
    }

    environment {
        DOCKER_HUB_REGISTRY = 'docker.io/israelatia'
        NEXUS_REGISTRY = 'localhost:8082'
        DOCKER_REGISTRY = "${params.TARGET_REGISTRY == 'docker.io' ? DOCKER_HUB_REGISTRY : NEXUS_REGISTRY}"
        DOCKER_IMAGE = 'israelatia/luxe-jewelry-store'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        IMAGE_TAG_COMMIT = "${env.GIT_COMMIT.take(7)}"
        APP_NAME = 'luxe-jewelry-store'
        SEMVER_VERSION = "1.0.${env.BUILD_NUMBER}"
        DOCKER_BUILDKIT = 1
        COMPOSE_DOCKER_CLI_BUILD = 1
        // Snyk token configuration
        SNYK_TOKEN = credentials('synk')
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '5'))
        disableConcurrentBuilds()
        timestamps()
        timeout(time: 15, unit: 'MINUTES')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Test') {
            steps {
                script {
                    // Build and test backend
                    dir('backend') {
                        // Install buildx if not present
                        sh '''
                            # Install buildx if not present
                            if ! command -v docker-buildx &> /dev/null; then
                                echo "Installing buildx..."
                                mkdir -p ~/.docker/cli-plugins/
                                curl -sSL https://github.com/docker/buildx/releases/download/v0.8.2/buildx-v0.8.2.linux-amd64 -o ~/.docker/cli-plugins/docker-buildx
                                chmod +x ~/.docker/cli-plugins/docker-buildx
                            fi
                            
                            # Build with BuildKit
                            DOCKER_BUILDKIT=1 docker build \
                                -t ${DOCKER_IMAGE}-backend:${DOCKER_TAG} \
                                -t ${DOCKER_IMAGE}-backend:latest \
                                .
                            
                            # Run tests in the container with proper Python path
                            if [ -d "tests" ]; then
                                echo "Running tests..."
                                if ! docker run --rm \
                                    -v ${WORKSPACE}/backend:/app \
                                    -w /app \
                                    -e PYTHONPATH=/app \
                                    ${DOCKER_IMAGE}-backend:${DOCKER_TAG} \
                                    python -m pytest tests/ -v --import-mode=importlib; then
                                    echo "Tests failed"
                                    exit 1
                                fi
                            fi
                        '''
                    }
                    
                    // Build frontend
                    dir('frontend') {
                        sh '''
                            DOCKER_BUILDKIT=1 docker build \
                                -t ${DOCKER_IMAGE}-frontend:${DOCKER_TAG} \
                                -t ${DOCKER_IMAGE}-frontend:latest \
                                .
                        '''
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
                            withCredentials([usernamePassword(
                                credentialsId: 'docker-hub',
                                usernameVariable: 'DOCKER_USER',
                                passwordVariable: 'DOCKER_PASS'
                            )]) {
                                sh """
                                    docker login -u $DOCKER_USER -p $DOCKER_PASS
                                    docker tag ${DOCKER_IMAGE}-backend:latest ${DOCKER_HUB_REGISTRY}/${APP_NAME}-backend:${SEMVER_VERSION}
                                    docker tag ${DOCKER_IMAGE}-backend:latest ${DOCKER_HUB_REGISTRY}/${APP_NAME}-backend:${IMAGE_TAG_COMMIT}
                                    docker tag ${DOCKER_IMAGE}-backend:latest ${DOCKER_HUB_REGISTRY}/${APP_NAME}-backend:latest
                                    docker push ${DOCKER_HUB_REGISTRY}/${APP_NAME}-backend:${SEMVER_VERSION}
                                    docker push ${DOCKER_HUB_REGISTRY}/${APP_NAME}-backend:${IMAGE_TAG_COMMIT}
                                    docker push ${DOCKER_HUB_REGISTRY}/${APP_NAME}-backend:latest
                                    
                                    docker tag ${DOCKER_IMAGE}-frontend:latest ${DOCKER_HUB_REGISTRY}/${APP_NAME}-frontend:${SEMVER_VERSION}
                                    docker tag ${DOCKER_IMAGE}-frontend:latest ${DOCKER_HUB_REGISTRY}/${APP_NAME}-frontend:${IMAGE_TAG_COMMIT}
                                    docker tag ${DOCKER_IMAGE}-frontend:latest ${DOCKER_HUB_REGISTRY}/${APP_NAME}-frontend:latest
                                    docker push ${DOCKER_HUB_REGISTRY}/${APP_NAME}-frontend:${SEMVER_VERSION}
                                    docker push ${DOCKER_HUB_REGISTRY}/${APP_NAME}-frontend:${IMAGE_TAG_COMMIT}
                                    docker push ${DOCKER_HUB_REGISTRY}/${APP_NAME}-frontend:latest
                                """
                            }
                        }
                    }
                }

                stage('Push to Nexus') {
                    when { expression { params.PUSH_TO_NEXUS && params.TARGET_REGISTRY == 'localhost:8082' } }
                    steps {
                        script {
                            withCredentials([usernamePassword(
                                credentialsId: 'nexus-docker',
                                usernameVariable: 'NEXUS_USER',
                                passwordVariable: 'NEXUS_PASS'
                            )]) {
                                sh """
                                    docker login -u $NEXUS_USER -p $NEXUS_PASS ${NEXUS_REGISTRY}
                                    
                                    docker tag ${DOCKER_IMAGE}-backend:latest ${NEXUS_REGISTRY}/${APP_NAME}-backend:${SEMVER_VERSION}
                                    docker push ${NEXUS_REGISTRY}/${APP_NAME}-backend:${SEMVER_VERSION}
                                    
                                    docker tag ${DOCKER_IMAGE}-frontend:latest ${NEXUS_REGISTRY}/${APP_NAME}-frontend:${SEMVER_VERSION}
                                    docker push ${NEXUS_REGISTRY}/${APP_NAME}-frontend:${SEMVER_VERSION}
                                """
                            }
                        }
                    }
                }
            }
        }

        stage('Security Scan') {
            when {
                environment name: 'SNYK_TOKEN', value: /.+/
            }
            steps {
                script {
                    withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
                        sh """
                            snyk auth ${SNYK_TOKEN}
                            snyk container test ${DOCKER_IMAGE}-backend:${DOCKER_TAG} --file=backend/Dockerfile --severity-threshold=high
                            snyk container test ${DOCKER_IMAGE}-frontend:${DOCKER_TAG} --file=frontend/Dockerfile --severity-threshold=high
                        """
                    }
                }
            }
        }

        stage('Deploy') {
            when { expression { params.DEPLOY_ENVIRONMENT != 'none' } }
            steps {
                script {
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
            cleanWs()
        }

        failure {
            mail to: 'you@example.com',
                 subject: "Build Failed: ${currentBuild.fullDisplayName}",
                 body: "Check Jenkins logs for details."
        }
    }
}
