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

        stage('Build & Push') {
            steps {
                script {
                    def targetRegistry = params.TARGET_REGISTRY == 'docker.io' ? DOCKER_HUB_REGISTRY : NEXUS_REGISTRY
                    def imageFullName = "${targetRegistry}/${APP_NAME}-backend"

                    // Build Docker image
                    buildDockerImage(
                        imageName: "${APP_NAME}-backend",
                        dockerFile: 'backend/Dockerfile',
                        buildContext: '.',
                        registry: targetRegistry,
                        tags: [SEMVER_VERSION, IMAGE_TAG_COMMIT, 'latest']
                    )

                    // Push to Docker Hub
                    if (params.PUSH_TO_DOCKERHUB && params.TARGET_REGISTRY == 'docker.io') {
                        docker.withRegistry("https://${DOCKER_HUB_REGISTRY}", 'docker-hub') {
                            ["${SEMVER_VERSION}", "${IMAGE_TAG_COMMIT}", "latest"].each { tag ->
                                sh "docker tag ${APP_NAME}-backend:${tag} ${DOCKER_HUB_REGISTRY}/${APP_NAME}-backend:${tag}"
                                sh "docker push ${DOCKER_HUB_REGISTRY}/${APP_NAME}-backend:${tag}"
                            }
                        }
                    }

                    // Push to Nexus
                    if (params.PUSH_TO_NEXUS && params.TARGET_REGISTRY == 'localhost:8082') {
                        docker.withRegistry("http://${NEXUS_REGISTRY}", 'nexus-cred') {
                            sh "docker tag ${APP_NAME}-backend:${SEMVER_VERSION} ${NEXUS_REGISTRY}/${APP_NAME}-backend:${SEMVER_VERSION}"
                            sh "docker push ${NEXUS_REGISTRY}/${APP_NAME}-backend:${SEMVER_VERSION}"
                        }
                    }
                }
            }
        }

        stage('Security Scan') {
            steps {
                withCredentials([string(credentialsId: 'synk-token', variable: 'SNYK_TOKEN')]) {
                    script {
                        runSecurityScan(
                            scanType: 'container',
                            images: ["${params.TARGET_REGISTRY == 'docker.io' ? DOCKER_HUB_REGISTRY : NEXUS_REGISTRY}/${APP_NAME}-backend:${SEMVER_VERSION}"],
                            severityThreshold: 'high',
                            credentialsId: 'synk-token',
                            failOnIssues: false
                        )
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
            echo "Pipeline finished. Cleaning up workspace..."
            cleanWs()
        }
        success {
            echo "✅ Build succeeded!"
        }
        failure {
            echo "❌ Build failed!"
        }
    }
}
