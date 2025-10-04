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
                    def imageFullName = "${targetRegistry}/${APP_NAME}-backend:${SEMVER_VERSION}"

                    // Build Docker image
                    sh "docker build -t ${imageFullName} -f backend/Dockerfile ."
                    sh "docker tag ${imageFullName} ${targetRegistry}/${APP_NAME}-backend:latest"
                    sh "docker tag ${imageFullName} ${targetRegistry}/${APP_NAME}-backend:${env.IMAGE_TAG_COMMIT}"

                    // Push to Docker Hub
                    if (params.PUSH_TO_DOCKERHUB && params.TARGET_REGISTRY == 'docker.io') {
                        withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
                            sh "echo $DOCKERHUB_PASS | docker login -u $DOCKERHUB_USER --password-stdin docker.io"
                            sh "docker push ${DOCKER_HUB_REGISTRY}/${APP_NAME}-backend:${SEMVER_VERSION}"
                            sh "docker push ${DOCKER_HUB_REGISTRY}/${APP_NAME}-backend:latest"
                            sh "docker push ${DOCKER_HUB_REGISTRY}/${APP_NAME}-backend:${env.IMAGE_TAG_COMMIT}"
                        }
                    }

                    // Push to Nexus
                    if (params.PUSH_TO_NEXUS && params.TARGET_REGISTRY == 'localhost:8082') {
                        withCredentials([usernamePassword(credentialsId: 'nexus-cred', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                            sh "echo $NEXUS_PASS | docker login -u $NEXUS_USER --password-stdin ${NEXUS_REGISTRY}"
                            sh "docker push ${NEXUS_REGISTRY}/${APP_NAME}-backend:${SEMVER_VERSION}"
                        }
                    }
                }
            }
        }

        stage('Security Scan') {
            steps {
                script {
                    echo "🔒 Security scan placeholder: implement your scanner (Snyk, Trivy, etc.) here"
                    // Example: sh "snyk container test ${imageFullName} --severity-threshold=high --org=<org-id> --token=<token>"
                }
            }
        }

        stage('Deploy') {
            when {
                expression { params.DEPLOY_ENVIRONMENT != 'none' }
            }
            steps {
                script {
                    echo "🚀 Deploying to ${params.DEPLOY_ENVIRONMENT} environment..."
                    sh """
                        docker-compose -f docker-compose.${params.DEPLOY_ENVIRONMENT}.yml up -d --build
                    """
                }
            }
        }
    }

    post {
        always {
            echo "🧹 Pipeline finished. Cleaning up workspace..."
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
