pipeline {
    agent {
        docker {
            image 'israelatia/jenkins-agent:latest'
            args '--user root -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        WORKSPACE_DIR = "${env.WORKSPACE}"
        DOCKER_REGISTRY = "israelatia"
        APP_NAME = "luxe-jewelry-store"
        GIT_COMMIT_SHORT = "${env.GIT_COMMIT?.take(7) ?: 'unknown'}"
        VERSION = "${env.BUILD_NUMBER}.${GIT_COMMIT_SHORT}"
        IMAGE_TAG_LATEST = "latest"
        IMAGE_TAG_VERSION = "${VERSION}"
        IMAGE_TAG_BUILD = "build-${env.BUILD_NUMBER}"
    }

    options {
        buildDiscarder(logRotator(daysToKeepStr: '30'))
        disableConcurrentBuilds()
        skipDefaultCheckout()
        timestamps()
    }

    stages {

        stage('Checkout SCM') {
            steps {
                echo "Checking out code from GitHub..."
                checkout([$class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/Israelatia/Luxe-Jewelry-Store',
                        credentialsId: '4ca4b912-d2aa-4af3-bc7b-0e12d9b88542'
                    ]]
                ])
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
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-hub',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                }
            }
        }

        stage('Build App') {
            steps {
                dir("${WORKSPACE_DIR}") {
                    echo "Building application Docker images with multiple tags..."
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh '''
                            # Login to Docker Hub
                            echo $DOCKER_PASS | docker login --username $DOCKER_USER --password-stdin
                            
                            # Build backend image
                            docker build -f backend/infra/Dockerfile.app -t ${DOCKER_REGISTRY}/backend:${IMAGE_TAG_LATEST} ./backend
                            docker tag ${DOCKER_REGISTRY}/backend:${IMAGE_TAG_LATEST} ${DOCKER_REGISTRY}/backend:${IMAGE_TAG_VERSION}
                            docker tag ${DOCKER_REGISTRY}/backend:${IMAGE_TAG_LATEST} ${DOCKER_REGISTRY}/backend:${IMAGE_TAG_BUILD}
                            
                            # Build frontend image
                            docker build -f Dockerfile.nginx -t ${DOCKER_REGISTRY}/frontend:${IMAGE_TAG_LATEST} .
                            docker tag ${DOCKER_REGISTRY}/frontend:${IMAGE_TAG_LATEST} ${DOCKER_REGISTRY}/frontend:${IMAGE_TAG_VERSION}
                            docker tag ${DOCKER_REGISTRY}/frontend:${IMAGE_TAG_LATEST} ${DOCKER_REGISTRY}/frontend:${IMAGE_TAG_BUILD}
                            
                            # Push all tags for backend
                            docker push ${DOCKER_REGISTRY}/backend:${IMAGE_TAG_LATEST}
                            docker push ${DOCKER_REGISTRY}/backend:${IMAGE_TAG_VERSION}
                            docker push ${DOCKER_REGISTRY}/backend:${IMAGE_TAG_BUILD}
                            
                            # Push all tags for frontend
                            docker push ${DOCKER_REGISTRY}/frontend:${IMAGE_TAG_LATEST}
                            docker push ${DOCKER_REGISTRY}/frontend:${IMAGE_TAG_VERSION}
                            docker push ${DOCKER_REGISTRY}/frontend:${IMAGE_TAG_BUILD}
                            
                            echo "Images pushed with tags: latest, ${IMAGE_TAG_VERSION}, ${IMAGE_TAG_BUILD}"
                        '''
                    }
                }
            }
        }

        stage('Run Docker Compose') {
            steps {
                dir("${WORKSPACE_DIR}") {
                    echo "Starting Docker containers..."
                    sh 'docker-compose -f docker-compose.yml up -d'
                    sh 'docker ps'
                }
            }
        }

        stage('Validate Deployment') {
            steps {
                echo "Running containers:"
                sh 'docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
            }
        }
    }

    post {
        always {
            echo "Cleaning up build artifacts and Docker images..."
            sh '''
                # Clean up built images from Jenkins server
                docker rmi ${DOCKER_REGISTRY}/backend:${IMAGE_TAG_LATEST} || true
                docker rmi ${DOCKER_REGISTRY}/backend:${IMAGE_TAG_VERSION} || true
                docker rmi ${DOCKER_REGISTRY}/backend:${IMAGE_TAG_BUILD} || true
                docker rmi ${DOCKER_REGISTRY}/frontend:${IMAGE_TAG_LATEST} || true
                docker rmi ${DOCKER_REGISTRY}/frontend:${IMAGE_TAG_VERSION} || true
                docker rmi ${DOCKER_REGISTRY}/frontend:${IMAGE_TAG_BUILD} || true
                
                # Clean up docker-compose images
                docker rmi luxe-jewelry-store_backend:latest || true
                docker rmi luxe-jewelry-store_front:latest || true
                
                # Clean up unused containers, networks, and dangling images
                docker system prune -f || true
                
                echo "Cleanup completed - removed build artifacts from Jenkins server"
            '''
        }
        success {
            echo "Pipeline completed successfully! Images tagged with: latest, ${VERSION}, build-${BUILD_NUMBER}"
        }
        failure {
            echo "Pipeline failed. Check logs above."
        }
    }
}

