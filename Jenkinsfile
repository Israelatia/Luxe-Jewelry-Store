// Shared library temporarily disabled for testing
// Will be re-enabled once basic pipeline is working
pipeline {
    agent {
        docker {
            image 'israelatia/luxe-jenkins-agent:latest'
            args '--user root -v /var/run/docker.sock:/var/run/docker.sock'
            reuseNode true
        }
    }
    
    environment {
        // Fix Git safe directory issue
        GIT_SAFE_DIR = 'true'
    }
    
    options {
        skipDefaultCheckout true
    }
    
    parameters {
        choice(
            name: 'TARGET_REGISTRY',
            choices: ['israelatia', 'localhost:8082'],
            description: 'Target Docker registry for image deployment'
        )
        choice(
            name: 'DEPLOY_ENVIRONMENT',
            choices: ['development', 'staging', 'production'],
            description: 'Target environment for deployment'
        )
        booleanParam(
            name: 'PUSH_TO_NEXUS',
            defaultValue: true,
            description: 'Push images to Nexus registry'
        )
        booleanParam(
            name: 'PUSH_TO_DOCKERHUB',
            defaultValue: true,
            description: 'Push images to Docker Hub'
        )
    }

    environment {
        DOCKER_HUB_REGISTRY = 'israelatia'
        NEXUS_REGISTRY = 'localhost:8082'
        DOCKER_REGISTRY = "${params.TARGET_REGISTRY ?: DOCKER_HUB_REGISTRY}"
        APP_NAME = 'luxe-jewelry-store'
        GIT_COMMIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        IMAGE_TAG_LATEST = 'latest'
        IMAGE_TAG_BUILD = "build-${env.BUILD_NUMBER}"
        IMAGE_TAG_COMMIT = "commit-${GIT_COMMIT_SHORT}"
        SEMVER_VERSION = "1.0.${env.BUILD_NUMBER}"
        DEPLOY_ENV = "${params.DEPLOY_ENVIRONMENT ?: 'development'}"
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    // Fix Git safe directory issue
                    sh 'git config --global --add safe.directory ${WORKSPACE}'
                    
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/main']],
                        userRemoteConfigs: [[
                            url: 'https://github.com/Israelatia/Luxe-Jewelry-Store',
                            credentialsId: '4ca4b912-d2aa-4af3-bc7b-0e12d9b88542'
                        ]],
                        extensions: [[
                            $class: 'CleanBeforeCheckout'
                        ]]
                    ])
                }
            }
        }
    }
    
    post {
        always {
            script {
                // Clean up workspace only if in a node context
                if (env.NODE_NAME) {
                    cleanWs()
                }
            }
        }
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed. Check the logs for details.'
        }
        unstable {
            echo '⚠️ Pipeline completed with warnings.'
        }
    }
}
