@Library('luxe-shared-library@main') _

// Main pipeline
pipeline {
    agent {
        docker {
            image 'israelatia/luxe-jenkins-agent:latest'
            args '--user root -v /var/run/docker.sock:/var/run/docker.sock'
            reuseNode true
        }
    }
    
    parameters {
        choice(
            name: 'TARGET_REGISTRY',
            choices: ['israelatia', 'localhost:8082'],
            description: 'Target Docker registry for image deployment'
        )
        choice(
            name: 'DEPLOY_ENVIRONMENT',
            choices: ['development', 'staging', 'production'],
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

    environment {
        // Registry Configuration
        DOCKER_HUB_REGISTRY = 'israelatia'
        NEXUS_REGISTRY = 'localhost:8082'
        DOCKER_REGISTRY = "${params.TARGET_REGISTRY ?: DOCKER_HUB_REGISTRY}"
        
        // Application Configuration
        APP_NAME = 'luxe-jewelry-store'
        GIT_COMMIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        
        // Image Tags
        IMAGE_TAG_LATEST = 'latest'
        IMAGE_TAG_BUILD = "build-${env.BUILD_NUMBER}"
        IMAGE_TAG_COMMIT = "commit-${GIT_COMMIT_SHORT}"
        SEMVER_VERSION = "1.0.${env.BUILD_NUMBER}"
        
        // Build Configuration
        DOCKER_BUILDKIT = '1'
        COMPOSE_DOCKER_CLI_BUILD = '1'
        
        // Environment-based deployment
        DEPLOY_ENV = "${params.DEPLOY_ENVIRONMENT ?: 'development'}"
    }

    triggers {
        githubPush()
        pollSCM('H/5 * * * *')  // Poll every 5 minutes
    }

    options {
        buildDiscarder(logRotator(daysToKeepStr: '30'))
        disableConcurrentBuilds()
        timestamps()
        skipDefaultCheckout()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/Israelatia/Luxe-Jewelry-Store',
                        credentialsId: '4ca4b912-d2aa-4af3-bc7b-0e12d9b88542'
                    ]],
                    extensions: [[
                        $class: 'CleanBeforeCheckout'
                    ]]
                ])
            }
        }
        
        stage('Security & Quality') {
            parallel {
                stage('Security Scan') {
                    steps {
                        script {
                            runSecurityScan(
                                projectPath: '.',
                                failOnIssues: true,
                                severityThreshold: 'high',
                                credentialsId: 'snyk-token'
                            )
                        }
                    }
                }
                
                stage('Run Tests') {
                    steps {
                        script {
                            runTests(
                                testCommand: 'pytest',
                                coverageReport: true,
                                junitReport: true,
                                htmlReport: true
                            )
                        }
                    }
                }
                
                stage('Code Quality') {
                    steps {
                        script {
                            runCodeQuality(
                                sourceDir: '.',
                                failOnError: true,
                                pylintEnabled: true,
                                flake8Enabled: true
                            )
                        }
                    }
                }
            }
        }
        
        stage('Build Images') {
            parallel {
                stage('Backend Image') {
                    steps {
                        script {
                            buildDockerImage(
                                imageName: "${APP_NAME}-backend",
                                dockerFile: 'Dockerfile',
                                buildContext: '.',
                                tags: [
                                    IMAGE_TAG_LATEST,
                                    IMAGE_TAG_BUILD,
                                    IMAGE_TAG_COMMIT,
                                    SEMVER_VERSION
                                ]
                            )
                        }
                    }
                }
                
                stage('Frontend Image') {
                    when { expression { fileExists('frontend/Dockerfile') } }
                    steps {
                        script {
                            buildDockerImage(
                                imageName: "${APP_NAME}-frontend",
                                dockerFile: 'frontend/Dockerfile',
                                buildContext: 'frontend',
                                tags: [
                                    IMAGE_TAG_LATEST,
                                    IMAGE_TAG_BUILD,
                                    IMAGE_TAG_COMMIT,
                                    SEMVER_VERSION
                                ]
                            )
                        }
                    }
                }
            }
        }
        
        stage('Push Images') {
            when { 
                anyOf {
                    expression { return params.PUSH_TO_NEXUS }
                    expression { return params.PUSH_TO_DOCKERHUB }
                }
            }
            steps {
                script {
                    def registries = []
                    if (params.PUSH_TO_NEXUS) registries << NEXUS_REGISTRY
                    if (params.PUSH_TO_DOCKERHUB) registries << DOCKER_HUB_REGISTRY
                    
                    def images = ["${APP_NAME}-backend"]
                    if (fileExists('frontend/Dockerfile')) {
                        images << "${APP_NAME}-frontend"
                    }
                    
                    images.each { image ->
                        registries.each { registry ->
                            pushToRegistry(
                                imageName: image,
                                registry: registry,
                                tags: [
                                    IMAGE_TAG_LATEST,
                                    IMAGE_TAG_BUILD,
                                    IMAGE_TAG_COMMIT,
                                    SEMVER_VERSION
                                ]
                            )
                        }
                    }
                }
            }
        }
        
        stage('Deploy') {
            when { 
                branch 'main'
                anyOf {
                    expression { return params.DEPLOY_ENVIRONMENT == 'production' }
                    expression { return params.DEPLOY_ENVIRONMENT == 'staging' }
                }
            }
            steps {
                script {
                    deployApplication(
                        environment: params.DEPLOY_ENVIRONMENT,
                        imageName: "${APP_NAME}-backend",
                        imageTag: IMAGE_TAG_LATEST,
                        registry: DOCKER_REGISTRY,
                        composeFile: 'docker-compose.${params.DEPLOY_ENVIRONMENT}.yml',
                        healthCheckUrl: '/health',
                        healthCheckTimeout: 300
                    )
                }
            }
        }

        stage('Verify Tools') {
            steps {
                echo "Verifying installed tools..."
                sh 'aws --version || true'
                sh 'snyk --version || true'
                sh 'docker --version || true'
                sh 'docker-compose --version || true'
                sh 'python3 --version || true'
                sh 'pip3 --version || true'
            }
        }

        stage('Install Dependencies') {
            steps {
                dir("${WORKSPACE_DIR}/backend") {
                    echo "Installing Python dependencies..."
                    sh '''
                        pip3 install --user -r requirements.txt
                        echo "Dependencies installed successfully"
                    '''
                }
            }
        }

        stage('Registry Authentication') {
            steps {
                script {  
                    echo "Authenticating with registries..."
                    
                    // Docker Hub authentication
                    if (params.PUSH_TO_DOCKERHUB) {
                        withCredentials([usernamePassword(
                            credentialsId: 'docker-hub',
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_PASS'
                        )]) {
                            sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                            echo "✅ Authenticated with Docker Hub"
                        }
                    }
                    
                    // Nexus authentication
                    if (params.PUSH_TO_NEXUS) {
                        withCredentials([usernamePassword(
                            credentialsId: 'nexus-docker',
                            usernameVariable: 'NEXUS_USER',
                            passwordVariable: 'NEXUS_PASS'
                        )]) {
                            sh 'echo $NEXUS_PASS | docker login localhost:8082 -u $NEXUS_USER --password-stdin'
                            echo "✅ Authenticated with Nexus Registry"
                        }
                    }
                }
            }
        }

        stage('Security & Quality') {
            parallel {
                stage('Security Scan') {
                    steps {
                        script {
                            runSecurityScan([
                                scanType: 'both',
                                images: ['amazonlinux:2', 'jenkins/agent'],
                                projectPath: 'backend',
                                severityThreshold: 'high',
                                credentialsId: 'snyk-token',
                                failOnIssues: false
                            ])
                        }
                    }
                }
                
                stage('Unit Tests') {
                    steps {
                        script {
                            runTests([
                                testType: 'unit',
                                testPath: 'tests/',
                                coverageThreshold: 80,
                                framework: 'pytest',
                                requirements: 'backend/requirements.txt',
                                publishResults: true
                            ])
                        }
                    }
                }
                
                stage('Code Quality') {
                    steps {
                        script {
                            runCodeQuality([
                                language: 'python',
                                sourcePath: 'backend/',
                                configFile: '.pylintrc',
                                failOnIssues: false,
                                tools: ['pylint', 'flake8']
                            ])
                        }
                    }
                }
            }
        }

        stage('Build & Push Images') {
            parallel {
                stage('Backend Image') {
                    steps {
                        script {
                            def backendResult = buildDockerImage([
                                imageName: "${APP_NAME}-backend",
                                dockerFile: 'backend/infra/Dockerfile.app',
                                buildContext: './backend',
                                registry: env.DOCKER_REGISTRY
                            ])
                            
                            // Push to Docker Hub
                            if (params.PUSH_TO_DOCKERHUB) {
                                pushToRegistry([
                                    imageName: "${DOCKER_HUB_REGISTRY}/${APP_NAME}-backend",
                                    tags: backendResult.tags + [env.DEPLOY_ENV],
                                    credentialsId: 'docker-hub'
                                ])
                            }
                            
                            // Push to Nexus
                            if (params.PUSH_TO_NEXUS) {
                                pushToRegistry([
                                    imageName: "${NEXUS_REGISTRY}/${APP_NAME}-backend",
                                    tags: backendResult.tags + [env.DEPLOY_ENV],
                                    credentialsId: 'nexus-docker'
                                ])
                            }
                        }
                    }
                }
                
                stage('Frontend Image') {
                    steps {
                        script {
                            def frontendResult = buildDockerImage([
                                imageName: "${APP_NAME}-frontend",
                                dockerFile: 'Dockerfile.nginx',
                                buildContext: '.',
                                registry: env.DOCKER_REGISTRY
                            ])
                            
                            // Push to Docker Hub
                            if (params.PUSH_TO_DOCKERHUB) {
                                pushToRegistry([
                                    imageName: "${DOCKER_HUB_REGISTRY}/${APP_NAME}-frontend",
                                    tags: frontendResult.tags + [env.DEPLOY_ENV],
                                    credentialsId: 'docker-hub'
                                ])
                            }
                            
                            // Push to Nexus
                            if (params.PUSH_TO_NEXUS) {
                                pushToRegistry([
                                    imageName: "${NEXUS_REGISTRY}/${APP_NAME}-frontend",
                                    tags: frontendResult.tags + [env.DEPLOY_ENV],
                                    credentialsId: 'nexus-docker'
                                ])
                            }
                        }
                    }
                }
            }
        }

        stage('Deploy Application') {
            steps {
                script {
                    // Determine which registry to use for deployment
                    def deployRegistry = env.DOCKER_HUB_REGISTRY
                    if (env.DEPLOY_ENV == 'development' && params.PUSH_TO_NEXUS) {
                        deployRegistry = env.NEXUS_REGISTRY
                    }
                    
                    deployApplication([
                        environment: env.DEPLOY_ENV,
                        registry: deployRegistry,
                        appName: env.APP_NAME,
                        composeFile: 'docker-compose.yml',
                        healthCheck: true,
                        timeout: 300
                    ])
                }
            }
        }

        stage('Validate Deployment') {
            steps {
                echo "Validating deployment..."
                sh '''
                    echo "Running containers:"
                    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
                    
                    echo "\nContainer health status:"
                    docker ps --filter "status=running" --format "table {{.Names}}\t{{.Status}}"
                    
                    echo "\nDocker system info:"
                    docker system df
                '''
            }
        }
    }

    post {
        always {
            // Archive test results and coverage reports
            junit '**/test-results/**/*.xml'
            publishHTML([
                allowMissing: true,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'coverage',
                reportFiles: 'index.html',
                reportName: 'Coverage Report',
                reportTitles: 'Code Coverage'
            ])
            
            // Clean up Docker resources
            script {
                try {
                    echo "🧹 Cleaning up build artifacts..."
                    sh '''
                        # Clean up application images
                        docker rmi ${APP_NAME}-backend:latest || true
                        docker rmi ${APP_NAME}-frontend:latest || true
                        
                        # Clean up containers
                        docker ps -aq | xargs -r docker rm -f || true
                        
                        # Clean up images
                        docker images -q | xargs -r docker rmi -f || true
                        
                        # Clean up volumes
                        docker volume prune -f || true
                        
                        # Clean up network
                        docker network prune -f || true
                        
                        # Clean up system
                        docker system prune -a --volumes -f || true
                        docker builder prune -f || true
                    '''
                } catch (Exception e) {
                    echo "⚠️ Cleanup failed: ${e.getMessage()}"
                }
            }
            
            // Clean up workspace
            cleanWs()
        }
        
        success {
            script {
                notifySlack(
                    message: "✅ Pipeline Succeeded: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    channel: '#builds',
                    color: 'good',
                    includeBuildInfo: true
                )
                echo "🎉 Pipeline completed successfully!"
                echo "📊 Deployment Summary:"
                echo "  🌍 Environment: ${params.DEPLOY_ENVIRONMENT}"
                echo "  📦 Registry: ${params.PUSH_TO_DOCKERHUB ? 'Docker Hub' : ''} ${params.PUSH_TO_NEXUS ? 'Nexus' : ''}"
                echo "  ✅ All stages passed"
            }
        }
        
        failure {
            script {
                notifySlack(
                    message: "❌ Pipeline Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    channel: '#builds',
                    color: 'danger',
                    includeBuildInfo: true
                )
                echo "❌ Pipeline failed. Check logs for details."
            }
        }
        
        unstable {
            echo "⚠️ Pipeline completed with warnings."
        }
    }
}

