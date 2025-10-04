@Library('luxe-shared-library') _

pipeline {
    agent {
        docker {
            image 'israelatia/luxe-jenkins-agent:latest'
            args '--user root -v /var/run/docker.sock:/var/run/docker.sock -e GIT_DISCOVERY_ACROSS_FILESYSTEM=1'
        }
    }

    environment {
        DOCKER_HUB_REGISTRY = 'docker.io/israelatia'
        NEXUS_REGISTRY = 'localhost:8082'
        APP_NAME = 'luxe-jewelry-store'
        SEMVER_VERSION = "1.0.${env.BUILD_NUMBER}"
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '30'))
        disableConcurrentBuilds()
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
    }

    parameters {
        choice(name: 'TARGET_REGISTRY', choices: ['docker.io', 'localhost:8082'], description: 'Target Docker registry')
        choice(name: 'DEPLOY_ENVIRONMENT', choices: ['development', 'staging', 'production', 'none'], description: 'Deployment environment')
        booleanParam(name: 'PUSH_TO_NEXUS', defaultValue: true, description: 'Push to Nexus')
        booleanParam(name: 'PUSH_TO_DOCKERHUB', defaultValue: true, description: 'Push to Docker Hub')
    }

    stages {

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
                    sh 'pip install -r requirements.txt'
                }
            }
        }

        stage('Unit Tests & Lint') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        dir('backend') {
                            sh 'python3 -m pytest --junitxml results.xml tests/*.py'
                        }
                    }
                    post {
                        always {
                            junit 'backend/results.xml'
                        }
                    }
                }
                stage('Code Lint') {
                    steps {
                        dir('backend') {
                            sh 'python3 -m pylint *.py > pylint.log || true'
                        }
                    }
                    post {
                        always {
                            archiveArtifacts 'backend/pylint.log'
                        }
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
                                registry: params.TARGET_REGISTRY == 'docker.io' ? DOCKER_HUB_REGISTRY : NEXUS_REGISTRY,
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
                                registry: params.TARGET_REGISTRY == 'docker.io' ? DOCKER_HUB_REGISTRY : NEXUS_REGISTRY,
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
                script {
                    withCredentials([string(credentialsId: 'synk-token', variable: 'SNYK_TOKEN')]) {
                        runSecurityScan(
                            scanType: 'container',
                            images: [
                                "${DOCKER_HUB_REGISTRY}/${APP_NAME}-backend:${SEMVER_VERSION}",
                                "${DOCKER_HUB_REGISTRY}/${APP_NAME}-frontend:${SEMVER_VERSION}"
                            ],
                            severityThreshold: 'high',
                            credentialsId: 'synk-token',
                            failOnIssues: false
                        )
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
                        registry: params.TARGET_REGISTRY == 'docker.io' ? DOCKER_HUB_REGISTRY : NEXUS_REGISTRY,
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
            echo 'Cleaning up Docker images from Jenkins agent...'
            sh 'docker system prune -f'
        }
    }
}
