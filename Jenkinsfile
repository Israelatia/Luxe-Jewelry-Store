pipeline {
    agent any

    options {
        skipDefaultCheckout(false)
        timestamps()
    }

    stages {
        stage('Checkout') {
            steps {
                echo "Checking out code..."
                checkout scm
            }
        }

        stage('Verify Workspace') {
            steps {
                dir("${WORKSPACE}") {
                    sh 'pwd'
                    sh 'ls -la'
                }
            }
        }

        stage('Docker Compose Version') {
            steps {
                sh 'docker compose version || docker-compose version'
            }
        }

        stage('Build with Docker Compose') {
            steps {
                dir("${WORKSPACE}") {
                    echo "Building Docker images..."
                    sh '''
                        if docker compose version > /dev/null 2>&1; then
                          docker compose -f ${WORKSPACE}/docker-compose.yml build --no-cache
                        else
                          docker-compose -f ${WORKSPACE}/docker-compose.yml build --no-cache
                        fi
                    '''
                }
            }
        }

        stage('Run Containers') {
            steps {
                dir("${WORKSPACE}") {
                    echo "Starting containers..."
                    sh '''
                        if docker compose version > /dev/null 2>&1; then
                          docker compose -f ${WORKSPACE}/docker-compose.yml up -d
                        else
                          docker-compose -f ${WORKSPACE}/docker-compose.yml up -d
                        fi
                    '''
                }
            }
        }

        stage('Validate Docker Compose') {
            steps {
                dir("${WORKSPACE}") {
                    echo "Validating docker-compose configuration..."
                    sh '''
                        if docker compose version > /dev/null 2>&1; then
                          docker compose -f ${WORKSPACE}/docker-compose.yml config
                        else
                          docker-compose -f ${WORKSPACE}/docker-compose.yml config
                        fi
                    '''
                }
            }
        }
    }

    post {
        always {
            echo "Cleaning up containers..."
            sh '''
                if docker compose version > /dev/null 2>&1; then
                  docker compose -f ${WORKSPACE}/docker-compose.yml down -v || true
                else
                  docker-compose -f ${WORKSPACE}/docker-compose.yml down -v || true
                fi
            '''
        }
    }
}

