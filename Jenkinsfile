@Library('luxe-shared-library') _

pipeline {
    agent {
        docker {
            image 'israelatia/luxe-jenkins-agent:latest'
            args '--user root -v /var/run/docker.sock:/var/run/docker.sock -e GIT_DISCOVERY_ACROSS_FILESYSTEM=1'
        }
    }
    
    options {
        buildDiscarder(logRotator(daysToKeepStr: '30'))
        disableConcurrentBuilds()
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
    }

    parameters {
        string(name: 'TARGET_REGISTRY', 
               defaultValue: 'docker.io', 
               description: 'Target registry (docker.io or localhost:8082)')
        booleanParam(name: 'PUSH_TO_DOCKERHUB', 
                   defaultValue: true, 
                   description: 'Push images to Docker Hub')
        booleanParam(name: 'PUSH_TO_NEXUS', 
                   defaultValue: false, 
                   description: 'Push images to Nexus')
        choice(name: 'DEPLOY_ENVIRONMENT',
               choices: ['none', 'dev', 'stage', 'prod'],
               description: 'Deployment environment')
        booleanParam(name: 'RUN_TESTS', 
                   defaultValue: true, 
                   description: 'Run unit tests')
        booleanParam(name: 'RUN_LINTING', 
                   defaultValue: true, 
                   description: 'Run code linting')
        booleanParam(name: 'RUN_SECURITY_SCAN', 
                   defaultValue: true, 
                   description: 'Run security scanning')
        booleanParam(name: 'SKIP_TESTS', 
                   defaultValue: false, 
                   description: 'Skip all tests (for debugging)')
    }
    
    environment {
        // Registry settings
        DOCKER_HUB_REGISTRY = 'docker.io/israelatia'
        NEXUS_REGISTRY = 'localhost:8082'
        DOCKER_REGISTRY = "${params.TARGET_REGISTRY == 'docker.io' ? '' : NEXUS_REGISTRY}"
        
        // Application settings
        APP_NAME = 'luxe-jewelry-store'
        BACKEND_IMAGE = "${DOCKER_REGISTRY ? DOCKER_REGISTRY + '/' : ''}${APP_NAME}-backend"
        FRONTEND_IMAGE = "${DOCKER_REGISTRY ? DOCKER_REGISTRY + '/' : ''}${APP_NAME}-frontend"
        
        // Versioning
        GIT_COMMIT_SHORT = "${env.GIT_COMMIT.take(7)}"
        IMAGE_TAG = "${env.BUILD_NUMBER}-${GIT_COMMIT_SHORT}"
        
        // Ports
        BACKEND_PORT = '5000'
        FRONTEND_PORT = '8080'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: scm.branches,
                    extensions: scm.extensions + [[$class: 'CleanBeforeCheckout']],
                    userRemoteConfigs: [[
                        credentialsId: '4ca4b912-d2aa-4af3-bc7b-0e12d9b88542',
                        url: scm.userRemoteConfigs[0].url
                    ]]
                ])
                sh 'git config --global --add safe.directory $WORKSPACE'
            }
        }
        
        stage('Build Docker Images') {
            steps {
                script {
                    // Build backend image
                    sh """
                    echo "Building backend image ${BACKEND_IMAGE}:${IMAGE_TAG}"
                    docker build -t ${BACKEND_IMAGE}:${IMAGE_TAG} \
                               -t ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT} \
                               -t ${BACKEND_IMAGE}:latest \
                               ./backend
                    
                    # Build frontend image
                    echo "Building frontend image ${FRONTEND_IMAGE}:${IMAGE_TAG}"
                    docker build -t ${FRONTEND_IMAGE}:${IMAGE_TAG} \
                               -t ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT} \
                               -t ${FRONTEND_IMAGE}:latest \
                               ./frontend
                    
                    # List all images for debugging
                    docker images | grep -E '${BACKEND_IMAGE}|${FRONTEND_IMAGE}'
                    """
                }
            }
        }

        stage('Setup Environment') {
            steps {
                script {
                    // Set deployment environment
                    if (params.DEPLOY_ENVIRONMENT != 'none') {
                        env.DEPLOY_ENV = params.DEPLOY_ENVIRONMENT
                    }
                }
            }
        }

        stage('Build & Test') {
            when {
                expression { params.RUN_TESTS == true }
            }
            parallel {
                stage('Build Backend') {
                    steps {
                        dir('backend') {
                            sh '''
                            # Install Python dependencies
                            python -m pip install --upgrade pip
                            pip install -r requirements.txt
                            
                            # Run unit tests
                            python -m pytest tests/ -v --junitxml=test-results.xml
                            '''
                            
                            // Archive test results
                            junit 'backend/test-results.xml'
                        }
                    }
                }
                
                stage('Lint Backend') {
                    when {
                        expression { params.RUN_LINTING == true }
                    }
                    steps {
                        dir('backend') {
                            sh '''
                            # Install pylint if not installed
                            pip install pylint
                            
                            # Run pylint
                            pylint --output-format=parseable --reports=y \
                                   --rcfile=.pylintrc *.py > pylint-report.txt || true
                            '''
                            
                            // Archive linting results
                            recordIssues tool: pyLint(pattern: 'backend/pylint-report.txt')
                        }
                    }
                }
                
                stage('Build Frontend') {
                    steps {
                        dir('frontend') {
                            sh '''
                            # Install Node.js dependencies
                            npm ci
                            
                            # Build the frontend
                            npm run build
                            
                            # Run tests if they exist
                            if [ -f "package.json" ] && grep -q "test" package.json; then
                                npm test -- --coverage
                            fi
                            '''
                            
                            // Archive test results if they exist
                            junit 'frontend/junit.xml'
                        }
                    }
                }
            }
        }

        stage('Security Scan') {
            when {
                expression { params.RUN_SECURITY_SCAN == true }
            }
            steps {
                script {
                    withCredentials([string(credentialsId: 'synk', variable: 'SNYK_TOKEN')]) {
                        sh '''
                        # Authenticate with Snyk
                        snyk auth ${SNYK_TOKEN}
                        
                        # Scan backend
                        snyk container test ${BACKEND_IMAGE}:${IMAGE_TAG} \
                            --file=backend/Dockerfile \
                            --severity-threshold=high \
                            --json-file-output=snyk-backend-report.json || \
                            echo "Snyk scan found vulnerabilities"
                        
                        # Scan frontend
                        snyk container test ${FRONTEND_IMAGE}:${IMAGE_TAG} \
                            --file=frontend/Dockerfile \
                            --severity-threshold=high \
                            --json-file-output=snyk-frontend-report.json || \
                            echo "Snyk scan found vulnerabilities"
                        
                        # Archive Snyk reports
                        cat snyk-*-report.json || true
                        '''
                        
                        // Archive Snyk reports
                        archiveArtifacts artifacts: 'snyk-*-report.json', allowEmptyArchive: true
                    }
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    sh """
                    # Build backend image with multiple tags
                    docker build -t ${BACKEND_IMAGE}:${IMAGE_TAG} \
                               -t ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT} \
                               -t ${BACKEND_IMAGE}:latest \
                               ./backend
                    
                    # Build frontend image with multiple tags
                    docker build -t ${FRONTEND_IMAGE}:${IMAGE_TAG} \
                               -t ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT} \
                               -t ${FRONTEND_IMAGE}:latest \
                               ./frontend
                    """
                }
            }
        }

        stage('Push Images') {
            when {
                anyOf {
                    expression { params.PUSH_TO_DOCKERHUB == true }
                    expression { params.PUSH_TO_NEXUS == true }
                }
            }
            parallel {
                stage('Push to Docker Hub') {
                    when { 
                        expression { params.PUSH_TO_DOCKERHUB == true }
                    }
                    steps {
                        script {
                            withCredentials([usernamePassword(
                                credentialsId: 'docker-hub',
                                usernameVariable: 'DOCKER_USERNAME',
                                passwordVariable: 'DOCKER_PASSWORD'
                            )]) {
                                sh """
                                # Login to Docker Hub
                                echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
                                
                                # Push backend image to Docker Hub
                                docker push ${BACKEND_IMAGE}:${IMAGE_TAG}
                                docker push ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT}
                                docker push ${BACKEND_IMAGE}:latest
                                
                                # Push frontend image to Docker Hub
                                docker push ${FRONTEND_IMAGE}:${IMAGE_TAG}
                                docker push ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT}
                                docker push ${FRONTEND_IMAGE}:latest
                                
                                # Logout from Docker Hub
                                docker logout
                                """
                            }
                        }
                    }
                }
                
                stage('Push to Nexus') {
                    when { 
                        expression { params.PUSH_TO_NEXUS == true }
                    }
                    steps {
                        script {
                            withCredentials([usernamePassword(
                                credentialsId: 'nexus-cred',
                                usernameVariable: 'NEXUS_USER',
                                passwordVariable: 'NEXUS_PASSWORD'
                            )]) {
                                sh """
                                # Login to Nexus
                                echo "${NEXUS_PASSWORD}" | docker login -u "${NEXUS_USER}" --password-stdin ${NEXUS_REGISTRY}
                                
                                # Tag images for Nexus
                                docker tag ${BACKEND_IMAGE}:${IMAGE_TAG} ${NEXUS_REGISTRY}/${BACKEND_IMAGE}:${IMAGE_TAG}
                                docker tag ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT} ${NEXUS_REGISTRY}/${BACKEND_IMAGE}:${GIT_COMMIT_SHORT}
                                
                                docker tag ${FRONTEND_IMAGE}:${IMAGE_TAG} ${NEXUS_REGISTRY}/${FRONTEND_IMAGE}:${IMAGE_TAG}
                                docker tag ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT} ${NEXUS_REGISTRY}/${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT}
                                
                                # Push images to Nexus
                                docker push ${NEXUS_REGISTRY}/${BACKEND_IMAGE}:${IMAGE_TAG}
                                docker push ${NEXUS_REGISTRY}/${BACKEND_IMAGE}:${GIT_COMMIT_SHORT}
                                
                                docker push ${NEXUS_REGISTRY}/${FRONTEND_IMAGE}:${IMAGE_TAG}
                                docker push ${NEXUS_REGISTRY}/${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT}
                                
                                # Logout from Nexus
                                docker logout ${NEXUS_REGISTRY}
                                """
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
                    // Create deployment directory
                    sh 'mkdir -p deployment'
                    
                    // Generate docker-compose file for the environment
                    def composeFile = "deployment/docker-compose-${params.DEPLOY_ENVIRONMENT}.yml"
                    
                    // Use environment-specific compose file if it exists, otherwise use default
                    if (fileExists("docker-compose.${params.DEPLOY_ENVIRONMENT}.yml")) {
                        sh "cp docker-compose.${params.DEPLOY_ENVIRONMENT}.yml ${composeFile}"
                    } else {
                        sh "cp docker-compose.yml ${composeFile}"
                    }
                    
                    // Update image tags in the compose file
                    sh """
                    sed -i 's|${BACKEND_IMAGE}:latest|${BACKEND_IMAGE}:${IMAGE_TAG}|g' ${composeFile}
                    sed -i 's|${FRONTEND_IMAGE}:latest|${FRONTEND_IMAGE}:${IMAGE_TAG}|g' ${composeFile}
                    """
                    
                    // Deploy using docker-compose
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'docker-hub',
                            usernameVariable: 'DOCKER_USERNAME',
                            passwordVariable: 'DOCKER_PASSWORD'
                        )
                    ]) {
                        sh """
                        # Login to Docker Hub if pushing to Docker Hub
                        if [ "${params.PUSH_TO_DOCKERHUB}" = true ]; then
                            echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
                        fi
                        
                        # Login to Nexus if pushing to Nexus
                        if [ "${params.PUSH_TO_NEXUS}" = true ]; then
                            withCredentials([usernamePassword(
                                credentialsId: 'nexus-cred',
                                usernameVariable: 'NEXUS_USER',
                                passwordVariable: 'NEXUS_PASSWORD'
                            )]) {
                                echo "${NEXUS_PASSWORD}" | docker login -u "${NEXUS_USER}" --password-stdin ${NEXUS_REGISTRY}
                            }
                        fi
                        
                        # Pull the latest images
                        docker-compose -f ${composeFile} pull --ignore-pull-failures
                        
                        # Deploy the stack
                        docker-compose -f ${composeFile} up -d --remove-orphans
                        
                        # Verify deployment
                        sleep 10  # Give containers time to start
                        docker ps
                        
                        # Run health checks
                        docker-compose -f ${composeFile} ps
                        
                        # Logout from registries
                        docker logout
                        if [ "${params.PUSH_TO_NEXUS}" = true ]; then
                            docker logout ${NEXUS_REGISTRY}
                        fi
                        """
                    }
                    
                    // Update deployment status
                    currentBuild.description = "Deployed to ${params.DEPLOY_ENVIRONMENT.toUpperCase()}"
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up Docker images and temporary files from Jenkins agent...'
            sh '''
            # Remove all stopped containers
            docker rm -f $(docker ps -aq) 2>/dev/null || true
            
            # Remove unused images
            docker system prune -f
            
            # Clean up workspace
            rm -rf node_modules/ __pycache__/ .pytest_cache/ || true
            '''
            
            // Clean workspace
            cleanWs()
        }
        
        success {
            script {
                // Send success notification
                emailext (
                    subject: "✅ SUCCESS: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                    body: """
                    <p>Build ${currentBuild.currentResult}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'</p>
                    <p>Check console output at <a href='${env.BUILD_URL}'>${env.JOB_NAME} [${env.BUILD_NUMBER}]</a></p>
                    <p>Deployed to: ${params.DEPLOY_ENVIRONMENT ?: 'Not deployed'}</p>
                    <p>Changes: ${currentBuild.changeSets.collect().flatten().collect { "${it.authorName}: ${it.msg}" }.join('<br>')}</p>
                    """,
                    to: 'dev-team@example.com',
                    recipientProviders: [[$class: 'DevelopersRecipientProvider']]
                )
            }
        }
        
        failure {
            script {
                // Send failure notification
                emailext (
                    subject: "❌ FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                    body: """
                    <p>Build ${currentBuild.currentResult}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'</p>
                    <p>Check console output at <a href='${env.BUILD_URL}'>${env.JOB_NAME} [${env.BUILD_NUMBER}]</a></p>
                    <p>Stage: ${env.STAGE_NAME}</p>
                    <p>Error: ${currentBuild.rawBuild.getLog(100).join('\n').take(1000)}</p>
                    """,
                    to: 'dev-team@example.com',
                    recipientProviders: [[$class: 'DevelopersRecipientProvider']]
                )
            }
        }
        
        unstable {
            script {
                // Send unstable build notification
                emailext (
                    subject: "⚠️ UNSTABLE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                    body: """
                    <p>Build ${currentBuild.currentResult}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'</p>
                    <p>Check console output at <a href='${env.BUILD_URL}'>${env.JOB_NAME} [${env.BUILD_NUMBER}]</a></p>
                    <p>Stage: ${env.STAGE_NAME}</p>
                    """,
                    to: 'dev-team@example.com',
                    recipientProviders: [[$class: 'DevelopersRecipientProvider']]
                )
            }
        }
    }
}
