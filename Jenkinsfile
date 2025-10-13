@Library('luxe-shared-library') _
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
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "512Mi"
        cpu: "250m"
      limits:
        memory: "1Gi"
        cpu: "500m"
"""
        }
    }

    environment {
        DOCKER_HUB_REGISTRY = 'docker.io/israelatia'
        NEXUS_REGISTRY = 'localhost:8082'
        DOCKER_REGISTRY = "${params.TARGET_REGISTRY == 'docker.io' ? DOCKER_HUB_REGISTRY : NEXUS_REGISTRY}"
        APP_NAME = 'luxe-jewelry-store'
        SEMVER_VERSION = "1.0.${env.BUILD_NUMBER}"
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

    triggers {
        // GitHub webhook triggers
        githubPush()
        // Optional: GitHub pull request trigger if using multibranch pipeline
        // githubPullRequest()
    }

    parameters {
        choice(name: 'TARGET_REGISTRY', choices: ['docker.io', 'localhost:8082'], description: 'Target Docker registry')
        choice(name: 'DEPLOY_ENVIRONMENT', choices: ['development', 'staging', 'production', 'none'], description: 'Target environment for deployment')
        booleanParam(name: 'PUSH_TO_NEXUS', defaultValue: true, description: 'Push images to Nexus registry')
        booleanParam(name: 'PUSH_TO_DOCKERHUB', defaultValue: true, description: 'Push images to Docker Hub')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/Israelatia/Luxe-Jewelry-Store.git',
                        credentialsId: '4ca4b912-d2aa-4af3-bc7b-0e12d9b88542'
                    ]]
                ])
            }
        }

        stage('Build & Push Docker Images') {
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-hub') {
                        sh "docker build -t ${DOCKER_REGISTRY}/${APP_NAME}-backend:${SEMVER_VERSION} backend/"
                        sh "docker push ${DOCKER_REGISTRY}/${APP_NAME}-backend:${SEMVER_VERSION}"

                        sh "docker build -t ${DOCKER_REGISTRY}/${APP_NAME}-frontend:${SEMVER_VERSION} frontend/"
                        sh "docker push ${DOCKER_REGISTRY}/${APP_NAME}-frontend:${SEMVER_VERSION}"
                    }
                }
            }
        }

        stage('Security Scan') {
            steps {
                withEnv(["SNYK_TOKEN=${SNYK_TOKEN}"]) {
                    sh "snyk container test ${DOCKER_REGISTRY}/${APP_NAME}-backend:${SEMVER_VERSION} --file=backend/Dockerfile --severity-threshold=high"
                    sh "snyk container test ${DOCKER_REGISTRY}/${APP_NAME}-frontend:${SEMVER_VERSION} --file=frontend/Dockerfile --severity-threshold=high"
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    sh "kubectl apply -f k8s/ -n ${K8S_NAMESPACE}"
                }
            }
        }
    }

    post {
        always {
            echo "Cleaning up Docker images and temporary files..."
            sh 'docker system prune -af || true'
        }
    }
}
