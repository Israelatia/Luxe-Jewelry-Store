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
                    
                    // Build and push backend
                    docker.withRegistry("https://${targetRegistry}", 'docker-hub') {
                        def backendImage = docker.build("${APP_NAME}-backend:${SEMVER_VERSION}", "-f backend/Dockerfile .")
                        
                        // Tag with multiple tags
                        backendImage."${targetRegistry}/${APP_NAME}-backend:${SEMVER_VERSION}"
                        
                        // Push images
                        if (params.PUSH_TO_DOCKERHUB && params.TARGET_REGISTRY == 'docker.io') {
                            backendImage.push("${SEMVER_VERSION}")
                        }
                        
                        if (params.PUSH_TO_NEXUS && params.TARGET_REGISTRY == 'localhost:8082') {
                            backendImage.push("${SEMVER_VERSION}")
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
                    // Deploy using docker-compose
                    sh """
                        # Update docker-compose with the correct image tag
                        sed -i 's|${APP_NAME}-backend:latest|${params.TARGET_REGISTRY == 'docker.io' ? DOCKER_HUB_REGISTRY : NEXUS_REGISTRY}/${APP_NAME}-backend:${SEMVER_VERSION}|g' docker-compose.yml
                        
                        # Deploy
                        docker-compose down || true
                        docker-compose up -d
                        
                        # Verify deployment
                        docker-compose ps
                    """
                    echo "✅ Successfully deployed to ${params.DEPLOY_ENVIRONMENT}"
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
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
