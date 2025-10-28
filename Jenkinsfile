pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    args: ['\$(JENKINS_SECRET)', '\$(JENKINS_AGENT_NAME)']
    tty: true
  - name: backend
    image: israelatia/luxe-jewelry-store-backend:latest
    command:
    - cat
    tty: true
  - name: jenkins-agent
    image: israelatia/luxe-jewelry-store-backend:latest
    command:
    - cat
    tty: true
"""
            defaultContainer 'backend'
            idleMinutes 60
        }
    }

    environment {
        DOCKER_HUB_REGISTRY = 'docker.io/israelatia'
        NEXUS_REGISTRY = 'localhost:8082'
        APP_NAME = 'luxe-jewelry-store'
        SEMVER_VERSION = "1.0.${env.BUILD_NUMBER}"
        DOCKER_REGISTRY = "${params.TARGET_REGISTRY == 'docker.io' ? DOCKER_HUB_REGISTRY : NEXUS_REGISTRY}"
        DOCKER_BUILDKIT = 1
        COMPOSE_DOCKER_CLI_BUILD = 1
        SNYK_TOKEN = credentials('snyk')
        KUBECONFIG = "${env.WORKSPACE}/.kube/config"
        K8S_NAMESPACE = 'demo-app'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '30'))
        disableConcurrentBuilds()
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
    }

    parameters {
        choice(name: 'TARGET_REGISTRY', choices: ['docker.io', 'localhost:8082'], description: 'Target Docker registry')
        choice(name: 'DEPLOY_ENVIRONMENT', choices: ['development', 'staging', 'production', 'none'], description: 'Target environment for deployment')
        booleanParam(name: 'PUSH_TO_NEXUS', defaultValue: true, description: 'Push images to Nexus registry')
        booleanParam(name: 'PUSH_TO_DOCKERHUB', defaultValue: true, description: 'Push images to Docker Hub')
    }

    stages {
        stage('Clean Workspace') {
            steps { deleteDir() }
        }

        stage('Checkout') {
            steps {
                script {
                    sh """
                        git config --global --add safe.directory '*'
                        git config --global --add safe.directory ${WORKSPACE}
                        git config --global user.email "jenkins@localhost"
                        git config --global user.name "Jenkins"
                    """
                    checkout scm
                    env.GIT_COMMIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.IMAGE_TAG_COMMIT = "commit-${env.GIT_COMMIT_SHORT}"
                }
            }
        }

        // ... rest of your stages ...
    }

    post {
        always { echo "Pipeline completed." }
    }
}
