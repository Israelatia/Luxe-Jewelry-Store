pipeline {
    agent {
        docker {
            image '<dockerhub-username>/jenkins-agent:latest'
            args '--user root -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    options {
        buildDiscarder(daysToKeepStr: '30')
        disableConcurrentBuilds()
        timestamps()
    }

    environment {
        DOCKER_REGISTRY = '<dockerhub-username>'
        APP_NAME = 'luxe-jewelry-store'
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Build app') {
            steps {
                script {
                    // Use BUILD_NUMBER or GIT_COMMIT for image tagging
                    def tag = "${env.BUILD_NUMBER}"
                    sh """
                        docker login --username \$DOCKER_REGISTRY --password-stdin < credentials >
                        docker build -t \$DOCKER_REGISTRY/\$APP_NAME:\$tag ./backend
                        docker tag \$DOCKER_REGISTRY/\$APP_NAME:\$tag \$DOCKER_REGISTRY/\$APP_NAME:latest
                        docker push \$DOCKER_REGISTRY/\$APP_NAME:\$tag
                        docker push \$DOCKER_REGISTRY/\$APP_NAME:latest
                    """
                }
            }
        }

        stage('Run Docker Compose') {
            steps {
                sh 'docker compose -f docker-compose.yml up -d --build'
            }
        }
    }

    post {
        always {
            // Clean up Docker images to save space
            sh 'docker compose -f docker-compose.yml down --rmi all -v'
        }
    }
}

