// Jenkins Shared Library
@Library('luxe-shared-library') _

luxePipeline {
    // Project configuration
    projectName = 'luxe-jewelry-store'
    
    // Docker registry configuration
    registry = 'docker.io/israelatia'  // Default to Docker Hub
    
    // Build configuration
    buildCommand = 'docker-compose build --no-cache --pull'
    
    // Test configuration
    testCommand = 'cd backend && python -m pytest tests/ -v --junitxml=test-results.xml'
    
    // Deployment configuration
    deployCommand = '''
        export DOCKER_IMAGE_TAG=${env.BUILD_NUMBER}
        docker-compose -f docker-compose.yml -f docker-compose.${params.ENVIRONMENT}.yml up -d
    '''
    
    // Slack notification settings
    slackChannel = '#builds'
    
    // Pipeline parameters
    parameters = [
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Target deployment environment'
        ),
        booleanParam(
            name: 'PUSH_TO_REGISTRY',
            defaultValue: true,
            description: 'Push Docker images to the registry'
        )
    ]
    
    // Environment variables
    environmentVariables = [
        'DOCKER_BUILDKIT=1',
        'COMPOSE_DOCKER_CLI_BUILD=1'
    ]
    
    // Credentials
    credentials = [
        'docker-hub',
        'snyk-auth-token',
        'github-ssh'
    ]
    
    // Post-build actions
    postBuildActions = {
        // Clean up Docker resources
        sh '''
            docker system prune -f || true
            docker volume prune -f || true
            docker network prune -f || true
        '''
    }
    
    post {
        always {
            script {
                echo "🧹 Cleaning up Docker resources..."
                sh '''
                    docker system prune -af || true
                    docker volume prune -f || true
                '''
                cleanWs()
            }
        }
        
        success {
            echo "✅ Pipeline succeeded!"
            notifySlack(
                status: 'success',
                channel: '#ci-cd',
                message: "Pipeline #${env.BUILD_NUMBER} completed successfully!"
            )
        }
        
        failure {
            echo "❌ Pipeline failed!"
            notifySlack(
                status: 'failure',
                channel: '#ci-cd',
                message: "Pipeline #${env.BUILD_NUMBER} failed! Check the logs for details."
            )
        }
        
        unstable {
            echo "⚠️ Pipeline completed with warnings"
            notifySlack(
                status: 'unstable',
                channel: '#ci-cd',
                message: "Pipeline #${env.BUILD_NUMBER} completed with warnings."
            )
        }
    }
}
