pipeline {
    agent {
        docker {
<<<<<<< HEAD
            image '<dockerhub-username>/jenkins-agent:latest'
=======
            image 'israelatia/jenkins-agent:latest' // your custom agent image
>>>>>>> 0f758c5 (Fix buildDiscarder syntax)
            args '--user root -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    options {
<<<<<<< HEAD
        buildDiscarder(daysToKeepStr: '30')
=======
        buildDiscarder(logRotator(daysToKeepStr: '30'))
>>>>>>> 0f758c5 (Fix buildDiscarder syntax)
        disableConcurrentBuilds()
        timestamps()
    }

    environment {
<<<<<<< HEAD
        DOCKER_REGISTRY = '<dockerhub-username>'
=======
        DOCKER_REGISTRY = 'israelatia'   // your Docker Hub username
>>>>>>> 0f758c5 (Fix buildDiscarder syntax)
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
<<<<<<< HEAD
                    // Use BUILD_NUMBER or GIT_COMMIT for image tagging
                    def tag = "${env.BUILD_NUMBER}"
                    sh """
                        docker login --username \$DOCKER_REGISTRY --password-stdin < credentials >
=======
                    def tag = "${env.BUILD_NUMBER}"
                    sh """
                        echo \$DOCKER_PASSWORD | docker login --username \$DOCKER_REGISTRY --password-stdin
>>>>>>> 0f758c5 (Fix buildDiscarder syntax)
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
<<<<<<< HEAD
            // Clean up Docker images to save space
=======
>>>>>>> 0f758c5 (Fix buildDiscarder syntax)
            sh 'docker compose -f docker-compose.yml down --rmi all -v'
        }
    }
}

