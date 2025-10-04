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
        booleanParam(name: 'PUSH_TO_NEXUS', defaultValue: false, description: 'Push images to Nexus')
        string(name: 'DEPLOY_ENVIRONMENT', defaultValue: 'none', description: 'Deployment environment (dev/stage/prod/none)')
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
        // SNYK_TOKEN is optional, will be set only if the credential exists
        SNYK_TOKEN = credentials('snyk-token', '') ?: ''
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
                        sh 'docker build -t ${DOCKER_IMAGE}-backend:${DOCKER_TAG} .'
                        
                        // Run tests if test files exist
                        if (fileExists('tests/')) {
                            sh '''
                                if ! docker run --rm ${DOCKER_IMAGE}-backend:${DOCKER_TAG} \
                                    python -m pytest tests/ -v; then
                                    echo "Tests failed"
                                    exit 1
                                fi
                            '''
                        }
                    }
                    
                    // Build frontend
                    dir('frontend') {
                        sh 'docker build -t ${DOCKER_IMAGE}-frontend:${DOCKER_TAG} .'
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
