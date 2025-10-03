@Library('luxe-shared-library@main') _

pipeline {
    agent any
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Target deployment environment',
            defaultValue: 'dev'
        )
    }
    
    environment {
        DOCKER_BUILDKIT = 1
        COMPOSE_DOCKER_CLI_BUILD = 1
    }
    
    stages {
        stage('Build') {
            steps {
                script {
                    buildAndPushImage(
                        imageName: 'luxe-jewelry-store',
                        dockerfile: 'Dockerfile',
                        buildContext: '.',
                        registry: 'docker.io/israelatia',
                        tags: ["${env.BUILD_NUMBER}", 'latest'],
                        credentialsId: 'docker-hub'
                    )
                }
            }
        }
        
        stage('Test') {
            steps {
                script {
                    runTests(
                        testCommand: 'cd backend && python -m pytest tests/ -v --junitxml=test-results.xml',
                        testResultsPattern: '**/test-results/**/*.xml'
                    )
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                script {
                    runSecurityScan(
                        image: 'luxe-jewelry-store:latest',
                        failOnIssues: true
                    )
                }
            }
        }
        
        stage('Deploy') {
            when {
                expression { params.ENVIRONMENT in ['dev', 'staging', 'prod'] }
            }
            steps {
                script {
                    deployApp(
                        environment: params.ENVIRONMENT,
                        composeFile: 'docker-compose.yml',
                        envFile: "docker-compose.${params.ENVIRONMENT}.yml"
                    )
                }
            }
        }
    }
}
