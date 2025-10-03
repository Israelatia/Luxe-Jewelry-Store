// Jenkins Shared Library
@Library('luxe-shared-library') _

pipeline {
    agent {
        docker {
            image 'israelatia/luxe-jenkins-agent:latest'
            args '--user root -v /var/run/docker.sock:/var/run/docker.sock -e GIT_DISCOVERY_ACROSS_FILESYSTEM=1'
        }
    }

    environment {
        // Docker registry configuration
        DOCKER_HUB_REGISTRY = 'docker.io/israelatia'
        NEXUS_REGISTRY = 'localhost:8082'
        DOCKER_REGISTRY = "${params.TARGET_REGISTRY == 'docker.io' ? DOCKER_HUB_REGISTRY : NEXUS_REGISTRY}"
        
        // Application configuration
        APP_NAME = 'luxe-jewelry-store'
        
        // Image tags
        SEMVER_VERSION = "1.0.${env.BUILD_NUMBER}"
        
        // Enable Docker BuildKit and CLI for better build performance
        DOCKER_BUILDKIT = 1
        COMPOSE_DOCKER_CLI_BUILD = 1
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '30'))
        disableConcurrentBuilds()
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
    }

    parameters {
        // Choice parameters: first option is the default
        choice(
            name: 'TARGET_REGISTRY',
            choices: ['docker.io', 'localhost:8082'],
            description: 'Target Docker registry for image deployment'
        )
        choice(
            name: 'DEPLOY_ENVIRONMENT',
            choices: ['development', 'staging', 'production', 'none'],
            description: 'Target environment for deployment'
        )
        // Boolean parameters
        booleanParam(
            name: 'PUSH_TO_NEXUS',
            defaultValue: true,
            description: 'Push images to Nexus registry'
        )
        booleanParam(
            name: 'PUSH_TO_DOCKERHUB',
            defaultValue: true,
            description: 'Push images to Docker Hub'
        )
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
                        extensions: [[
                            $class: 'CleanBeforeCheckout'
                        ]]
                    ])
                    env.GIT_COMMIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.IMAGE_TAG_COMMIT = "commit-${env.GIT_COMMIT_SHORT}"
                }
            }
        }

        stage('Test & Quality') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        script {
                            runTests(
                                framework: 'pytest',
                                testPath: 'tests/',
                                coverageThreshold: 80,
                                junitReport: true
                            )
                        }
                    }
                }
                stage('Code Quality') {
                    steps {
                        script {
                            runCodeQuality(
                                language: 'python',
                                sourcePath: 'backend/',
                                configFile: '.pylintrc',
                                failOnIssues: false
                            )
                        }
                    }
                }
                stage('Security Scan') {
                    steps {
                        script {
                            runSecurityScan(
                                scanType: 'container',
                                images: [
                                    "${DOCKER_REGISTRY}/${APP_NAME}-backend:${SEMVER_VERSION}",
                                    "${DOCKER_REGISTRY}/${APP_NAME}-frontend:${SEMVER_VERSION}"
                                ],
                                severityThreshold: 'high',
                                credentialsId: 'synk-token',
                                failOnIssues: false
                            )
                        }
                    }
                }
            }
        }

        stage('Build & Push') {
            parallel {
                stage('Backend') {
                    steps {
                        script {
                            buildDockerImage(
                                imageName: "${APP_NAME}-backend",
                                dockerFile: 'backend/Dockerfile',
                                buildContext: '.',
                                registry: DOCKER_REGISTRY,
                                tags: [SEMVER_VERSION, IMAGE_TAG_COMMIT, 'latest']
                            )
                            if (params.PUSH_TO_DOCKERHUB) {
                                pushToRegistry(
                                    imageName: "${DOCKER_HUB_REGISTRY}/${APP_NAME}-backend",
                                    tags: [SEMVER_VERSION, IMAGE_TAG_COMMIT, 'latest'],
                                    credentialsId: 'docker-hub',
                                    registry: 'docker.io'
                                )
                            }
                            if (params.PUSH_TO_NEXUS && params.TARGET_REGISTRY == 'localhost:8082') {
                                pushToRegistry(
                                    imageName: "${NEXUS_REGISTRY}/${APP_NAME}-backend",
                                    tags: [SEMVER_VERSION],
                                    credentialsId: 'nexus-cred',
                                    registry: NEXUS_REGISTRY
                                )
                            }
                        }
                    }
                }
                stage('Frontend') {
                    steps {
                        script {
                            buildDockerImage(
                                imageName: "${APP_NAME}-frontend",
                                dockerFile: 'frontend/Dockerfile',
                                buildContext: '.',
                                registry: DOCKER_REGISTRY,
                                tags: [SEMVER_VERSION, IMAGE_TAG_COMMIT, 'latest']
                            )
                            if (params.PUSH_TO_DOCKERHUB) {
                                pushToRegistry(
                                    imageName: "${DOCKER_HUB_REGISTRY}/${APP_NAME}-frontend",
                                    tags: [SEMVER_VERSION, IMAGE_TAG_COMMIT, 'latest'],
                                    credentialsId: 'docker-hub',
                                    registry: 'docker.io'
                                )
                            }
                            if (params.PUSH_TO_NEXUS && params.TARGET_REGISTRY == 'localhost:8082') {
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

        stage('Deploy') {
            when {
                expression { params.DEPLOY_ENVIRONMENT != 'none' }
            }
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
            script {
                echo "🧹 Cleaning up Docker resources..."
                sh '''
                    docker system prune -af || true
                    docker volume prune -f || true
                '''
                cleanWs()
            }
        }
        success {
            echo "✅ Pipeline succeeded!"
            notifySlack(
                status: 'success',
                channel: '#ci-cd',
                message: "Pipeline #${env.BUILD_NUMBER} completed successfully!"
            )
        }
        failure {
            echo "❌ Pipeline failed!"
            notifySlack(
                status: 'failure',
                channel: '#ci-cd',
                message: "Pipeline #${env.BUILD_NUMBER} failed! Check the logs for details."
            )
        }
        unstable {
            echo "⚠️ Pipeline completed with warnings"
            notifySlack(
                status: 'unstable',
                channel: '#ci-cd',
                message: "Pipeline #${env.BUILD_NUMBER} completed with warnings."
            )
        }
    }
}
