pipeline {
    agent any
    stages {
        stage('Build with Docker Compose') {
            steps {
                // Change directory to the root of the project
                dir('./') { 
                    sh 'docker compose build'
                }
            }
        }
    }
}
