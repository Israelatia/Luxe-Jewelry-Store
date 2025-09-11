pipeline {
    agent {
        docker {
            image 'israelatia/jenkins-agent:latest'
            args '-u root:root -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        WORKSPACE_DIR = "${env.WORKSPACE}"
    }

    options {
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

        stage('Build Docker Images') {
            steps {
                dir("${WORKSPACE_DIR}") {
                    echo "Building Docker images..."
                    sh 'docker-compose -f docker-compose.yml build'
                }
            }
        }

        stage('Push Docker Images') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-hub',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        docker tag luxe-jewelry-store_backend:latest $DOCKER_USER/backend:latest
                        docker push $DOCKER_USER/backend:latest

                        docker tag luxe-jewelry-store_front:latest $DOCKER_USER/front:latest
                        docker push $DOCKER_USER/front:latest
                    '''
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
            echo "Cleaning up unused containers and images..."
            sh 'docker system prune -f || true'
        }
        success {
            echo "Pipeline completed successfully!"
        }
        failure {
            echo "Pipeline failed. Check logs above."
        }
    }
}

