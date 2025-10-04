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
                        backendImage."${targetRegistry}/${APP_NAME}-backend:${IMAGE_TAG_COMMIT}"
                        backendImage."${targetRegistry}/${APP_NAME}-backend:latest"
                        
                        // Push images
                        if (params.PUSH_TO_DOCKERHUB && params.TARGET_REGISTRY == 'docker.io') {
                            backendImage.push("${SEMVER_VERSION}")
                            backendImage.push("${IMAGE_TAG_COMMIT}")
                            backendImage.push("latest")
                        }
                        
                        if (params.PUSH_TO_NEXUS && params.TARGET_REGISTRY == 'localhost:8082') {
                            backendImage.push("${SEMVER_VERSION}")
                        }
                    }
                    
                    // Build and push frontend
                    docker.withRegistry("https://${targetRegistry}", 'docker-hub') {
                        def frontendImage = docker.build("${APP_NAME}-frontend:${SEMVER_VERSION}", "-f frontend/Dockerfile .")
                        
                        // Tag with multiple tags
                        frontendImage."${targetRegistry}/${APP_NAME}-frontend:${SEMVER_VERSION}"
                        frontendImage."${targetRegistry}/${APP_NAME}-frontend:${IMAGE_TAG_COMMIT}"
                        frontendImage."${targetRegistry}/${APP_NAME}-frontend:latest"
                        
                        // Push images
                        if (params.PUSH_TO_DOCKERHUB && params.TARGET_REGISTRY == 'docker.io') {
                            frontendImage.push("${SEMVER_VERSION}")
                            frontendImage.push("${IMAGE_TAG_COMMIT}")
                            frontendImage.push("latest")
                        }
                        
                        if (params.PUSH_TO_NEXUS && params.TARGET_REGISTRY == 'localhost:8082') {
                            frontendImage.push("${SEMVER_VERSION}")
                        }
                    }
                }
            }
        }

        stage('Unit Tests') {
            steps {
                script {
                    sh 'pip install -r backend/requirements.txt'
                    sh 'python -m pytest backend/tests/ -v --junitxml=test-results.xml'
                }
            }
            post {
                always {
                    junit 'test-results.xml'
                }
            }
        }

        stage('Linting') {
            steps {
                script {
                    sh 'pip install pylint'
                    sh 'pylint --version'
                    sh 'pylint --rcfile=backend/.pylintrc backend/ || true'  // Continue even if linting fails
                }
            }
        }

        stage('Security Scan') {
            when {
                expression { params.DEPLOY_ENVIRONMENT in ['staging', 'production'] }
            }
            environment {
                SNYK_TOKEN = credentials('snyk-token')
            }
            steps {
                script {
                    sh 'snyk auth ${SNYK_TOKEN}'
                    
                    // Scan backend
                    dir('backend') {
                        try {
                            sh 'snyk test --severity-threshold=high --file=Dockerfile'
                        } catch (e) {
                            echo '⚠️ High severity vulnerabilities found in backend. Please review and update dependencies.'
                            if (env.BRANCH_NAME == 'main') {
                                error('High severity vulnerabilities found in production dependencies')
                            }
                        }
                    }
                    
                    // Scan frontend
                    dir('frontend') {
                        try {
                            sh 'snyk test --severity-threshold=high --file=Dockerfile'
                        } catch (e) {
                            echo '⚠️ High severity vulnerabilities found in frontend. Please review and update dependencies.'
                            if (env.BRANCH_NAME == 'main') {
                                error('High severity vulnerabilities found in production dependencies')
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
                    def targetRegistry = params.TARGET_REGISTRY == 'docker.io' ? DOCKER_HUB_REGISTRY : NEXUS_REGISTRY
                    
                    // Update docker-compose with the correct image tags
                    sh """
                        sed -i 's|${APP_NAME}-backend:latest|${targetRegistry}/${APP_NAME}-backend:${SEMVER_VERSION}|g' docker-compose.yml
                        sed -i 's|${APP_NAME}-frontend:latest|${targetRegistry}/${APP_NAME}-frontend:${SEMVER_VERSION}|g' docker-compose.yml
                    """
                    
                    // Deploy using docker-compose
                    sh 'docker-compose down || true'  // Stop any running containers
                    sh 'docker-compose up -d'
                    
                    // Verify deployment
                    sh 'docker ps'
                    echo "✅ Successfully deployed to ${params.DEPLOY_ENVIRONMENT}"
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished. Cleaning up workspace..."
            // Clean up Docker resources
            sh '''
                docker system prune -f || true
                docker volume prune -f || true
                docker network prune -f || true
            '''
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
