pipeline {
  agent any
  stages {
    stage('build') {
      parallel {
        stage('build') {
          steps {
            sh '''docker compose build

'''
          }
        }

        stage('test') {
          steps {
            sh '''docker ps
'''
          }
        }

        stage('deploy ') {
          steps {
            sh '''docker compose up -d
'''
          }
        }

      }
    }

  }
}