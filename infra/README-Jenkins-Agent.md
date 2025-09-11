# Jenkins Docker Agent Setup

This directory contains a Dockerfile for creating a Jenkins agent with AWS CLI, Snyk, and Docker support for your Luxe Jewelry Store CI/CD pipeline.

## Features

The Jenkins agent includes:
- **AWS CLI v2** - For AWS deployments and S3 operations
- **Snyk CLI** - For security vulnerability scanning
- **Docker CLI** - For building and managing containers
- **Python 3** - For running Python-based applications and tests
- **Git** - For source code management
- **Essential build tools** - curl, wget, unzip

## Building the Agent

```bash
cd infra
docker build -f Dockerfile.jenkins-agent -t jenkins-agent-luxe .
```

## Using in Jenkins Pipeline

### Option 1: Docker Agent in Jenkinsfile

```groovy
pipeline {
    agent {
        docker {
            image 'jenkins-agent-luxe'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }
    
    stages {
        stage('Build') {
            steps {
                sh 'python --version'
                sh 'aws --version'
                sh 'snyk --version'
                sh 'docker --version'
            }
        }
        
        stage('Security Scan') {
            steps {
                sh 'snyk test'
            }
        }
        
        stage('Deploy to AWS') {
            steps {
                sh 'aws s3 sync ./build s3://your-bucket'
            }
        }
    }
}
```

### Option 2: Docker Agent per Stage

```groovy
pipeline {
    agent none
    
    stages {
        stage('Build & Test') {
            agent {
                docker {
                    image 'jenkins-agent-luxe'
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh 'pip install -r requirements.txt'
                sh 'python -m pytest'
            }
        }
        
        stage('Security Scan') {
            agent {
                docker {
                    image 'jenkins-agent-luxe'
                }
            }
            steps {
                sh 'snyk test --severity-threshold=high'
            }
        }
    }
}
```

## Benefits

1. **Isolation**: Each build runs in a clean container environment
2. **Consistency**: Same environment across all builds
3. **Resource Efficiency**: Ephemeral containers are created and destroyed as needed
4. **Multi-environment**: Can build for different environments using different agent images
5. **Security**: Isolated from Jenkins master and other builds

## Environment Variables

Set these in your Jenkins pipeline or globally:

```groovy
environment {
    AWS_ACCESS_KEY_ID = credentials('aws-access-key')
    AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
    SNYK_TOKEN = credentials('snyk-token')
}
```

## Docker Socket Access

To use Docker commands within the agent, mount the Docker socket:

```groovy
agent {
    docker {
        image 'jenkins-agent-luxe'
        args '-v /var/run/docker.sock:/var/run/docker.sock'
    }
}
```

## Troubleshooting

- **Permission Issues**: Ensure Jenkins user has access to Docker socket
- **AWS Credentials**: Configure AWS credentials in Jenkins credential store
- **Snyk Token**: Add Snyk authentication token to Jenkins credentials
- **Network Issues**: Check if Jenkins can pull the Docker image

## Security Considerations

- Use Jenkins credential store for sensitive data
- Regularly update the base images
- Scan the agent image with Snyk before deployment
- Limit container privileges where possible
