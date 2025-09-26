# Nexus Repository Setup Guide

This guide walks you through setting up Nexus Repository as a Docker registry for your CI/CD pipeline.

## 🚀 Quick Start

### 1. Deploy Nexus

```bash
cd infra
docker-compose -f docker-compose.nexus.yml up -d nexus
```

### 2. Run Setup Script

```bash
./nexus-setup.sh
```

### 3. Configure Jenkins Credentials

Add the following credentials in Jenkins:
- **nexus-docker** (Username/Password): Nexus admin credentials

## 📋 Manual Setup Instructions

### Step 1: Start Nexus Container

```bash
# Start Nexus
docker-compose -f docker-compose.nexus.yml up -d nexus

# Check logs
docker logs -f nexus-repository

# Wait for startup (can take 2-3 minutes)
```

### Step 2: Access Nexus UI

1. Open browser: http://localhost:8081
2. Login with admin credentials
3. Get initial password: `docker exec nexus-repository cat /nexus-data/admin.password`
4. Complete setup wizard

### Step 3: Create Docker Repositories

#### Hosted Repository (for your images)
```json
{
  "name": "docker-hosted",
  "format": "docker",
  "type": "hosted",
  "docker": {
    "v1Enabled": false,
    "forceBasicAuth": true,
    "httpPort": 8082
  }
}
```

#### Proxy Repository (Docker Hub cache)
```json
{
  "name": "docker-proxy", 
  "format": "docker",
  "type": "proxy",
  "proxy": {
    "remoteUrl": "https://registry-1.docker.io"
  },
  "docker": {
    "v1Enabled": false,
    "forceBasicAuth": true
  }
}
```

#### Group Repository (combined access)
```json
{
  "name": "docker-group",
  "format": "docker", 
  "type": "group",
  "group": {
    "memberNames": ["docker-hosted", "docker-proxy"]
  },
  "docker": {
    "v1Enabled": false,
    "forceBasicAuth": true,
    "httpPort": 8083
  }
}
```

### Step 4: Configure Docker Client

Add to `/etc/docker/daemon.json`:
```json
{
  "insecure-registries": [
    "localhost:8082",
    "localhost:8083"
  ]
}
```

Restart Docker: `sudo systemctl restart docker`

## 🔐 Authentication

### Login to Nexus Registry

```bash
# Login to push images
docker login localhost:8082 -u admin -p <password>

# Login to pull images (group registry)
docker login localhost:8083 -u admin -p <password>
```

### Jenkins Credentials

Create these credentials in Jenkins:

1. **nexus-docker** (Username/Password)
   - Username: `admin`
   - Password: `<nexus-admin-password>`
   - Description: "Nexus Docker Registry"

## 📦 Usage Examples

### Push Images to Nexus

```bash
# Tag image for Nexus
docker tag myapp:latest localhost:8082/myapp:latest

# Push to Nexus
docker push localhost:8082/myapp:latest
```

### Pull Images from Nexus

```bash
# Pull from group registry (includes proxy cache)
docker pull localhost:8083/myapp:latest

# Pull from hosted registry only
docker pull localhost:8082/myapp:latest
```

## 🔧 Jenkins Pipeline Integration

The updated Jenkinsfile includes:

### Parameters
- `PUSH_TO_NEXUS`: Enable/disable Nexus pushing
- `PUSH_TO_DOCKERHUB`: Enable/disable Docker Hub pushing
- `DEPLOY_ENVIRONMENT`: Target environment (dev/staging/prod)

### Environment Variables
```groovy
environment {
    NEXUS_REGISTRY = "localhost:8082"
    DOCKER_HUB_REGISTRY = "israelatia"
    DEPLOY_ENV = "${params.DEPLOY_ENVIRONMENT ?: 'development'}"
}
```

### Registry Authentication
```groovy
stage('Registry Authentication') {
    steps {
        script {
            if (params.PUSH_TO_NEXUS) {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-docker',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {
                    sh 'echo $NEXUS_PASS | docker login localhost:8082 -u $NEXUS_USER --password-stdin'
                }
            }
        }
    }
}
```

## 🌍 Environment-Based Deployment

### Development Environment
- Uses Nexus registry for faster builds
- Images tagged with `development`
- Local deployment with docker-compose

### Staging Environment  
- Can use either Nexus or Docker Hub
- Images tagged with `staging`
- Staging-specific configuration

### Production Environment
- Typically uses Docker Hub for reliability
- Images tagged with `production`
- Production-grade deployment

## 🐳 Docker Compose Integration

### Environment Variables
```bash
export DEPLOY_REGISTRY=localhost:8082
export DEPLOY_TAG=development
export APP_NAME=luxe-jewelry-store
export DEPLOY_ENV=development
```

### Deploy with Nexus Images
```bash
DEPLOY_REGISTRY=localhost:8082 DEPLOY_TAG=development docker-compose -f docker-compose.nexus-deploy.yml up -d
```

## 🔍 Troubleshooting

### Common Issues

1. **Connection Refused**
   - Check if Nexus is running: `docker ps | grep nexus`
   - Verify port 8082 is accessible: `curl localhost:8082/v2/`

2. **Authentication Failed**
   - Verify credentials: `docker login localhost:8082`
   - Check Jenkins credentials configuration

3. **Push Denied**
   - Ensure repository exists and is writable
   - Check user permissions in Nexus

4. **Insecure Registry**
   - Add to Docker daemon configuration
   - Restart Docker service

### Health Checks

```bash
# Check Nexus status
curl http://localhost:8081/service/rest/v1/status

# Check Docker registry
curl http://localhost:8082/v2/

# List repositories
curl -u admin:password http://localhost:8081/service/rest/v1/repositories
```

## 📊 Benefits

### Development Benefits
- **Faster Builds**: Local registry reduces pull times
- **Offline Development**: Cached images available locally
- **Cost Reduction**: Reduced external registry usage

### CI/CD Benefits
- **Multi-Registry Support**: Push to multiple registries
- **Environment Isolation**: Different registries per environment
- **Backup Strategy**: Multiple image storage locations

### Enterprise Benefits
- **Security**: Internal image storage
- **Compliance**: Control over image distribution
- **Performance**: Reduced network latency

## 🔄 Backup and Maintenance

### Backup Nexus Data
```bash
# Backup volume
docker run --rm -v nexus-data:/data -v $(pwd):/backup alpine tar czf /backup/nexus-backup.tar.gz /data

# Restore volume
docker run --rm -v nexus-data:/data -v $(pwd):/backup alpine tar xzf /backup/nexus-backup.tar.gz -C /
```

### Cleanup Old Images
```bash
# Remove old images from Nexus
curl -u admin:password -X DELETE http://localhost:8081/service/rest/v1/repositories/docker-hosted/components/<component-id>
```

This setup provides a robust, enterprise-grade Docker registry solution integrated with your CI/CD pipeline.
