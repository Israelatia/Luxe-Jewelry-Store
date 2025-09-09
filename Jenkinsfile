pipeline {
    agent {
        docker {
            image 'israelatia/jenkins-agent:latest'  // replace with your Docker Hub image
            args '--user root -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    options {
        buildDiscarder(logRotator(daysToKeepStr: '30'))
        disableConcurrentBuilds()
        timestamps()
    }

    environment {
        DOCKER_REGISTRY = 'israelatia'        // your Docker Hub username
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
                    def tag = "${env.BUILD_NUMBER}"  // can also use env.GIT_COMMIT
                    sh """
                        echo \$DOCKER_PASSWORD | docker login --username \$DOCKER_REGISTRY --password-stdin
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
            // Cleanup to free space
            sh 'docker compose -f docker-compose.yml down --rmi all -v'
        }
    }
}

