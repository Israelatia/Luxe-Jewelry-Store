# Jenkins Configuration Guide for Luxe Jewelry Store CI/CD

This guide provides step-by-step instructions for configuring Jenkins to use the shared library and run the CI/CD pipeline.

## 📋 Prerequisites

- Jenkins 2.400+ with Blue Ocean plugin
- Docker installed on Jenkins server
- Access to Jenkins administration panel

## 🔧 Required Jenkins Plugins

Install these plugins via **Manage Jenkins** → **Manage Plugins**:

```
- Pipeline: Groovy
- Docker Pipeline
- Docker Commons
- GitHub Integration
- HTML Publisher
- Warnings Next Generation
- Slack Notification
- Blue Ocean
- Pipeline: Stage View
- JUnit
- Coverage
```

## 🔐 Credentials Configuration

Navigate to **Manage Jenkins** → **Manage Credentials** → **Global** and add:

### 1. Docker Hub Credentials
- **Kind**: Username with password
- **ID**: `docker-hub`
- **Username**: Your Docker Hub username
- **Password**: Your Docker Hub password/token

### 2. Nexus Registry Credentials
- **Kind**: Username with password
- **ID**: `nexus-docker`
- **Username**: `admin` (or your Nexus user)
- **Password**: Your Nexus admin password

### 3. Snyk API Token
- **Kind**: Secret text
- **ID**: `snyk-token`
- **Secret**: Your Snyk API token

### 4. GitHub Credentials
- **Kind**: Username with password
- **ID**: `4ca4b912-d2aa-4af3-bc7b-0e12d9b88542`
- **Username**: Your GitHub username
- **Password**: Your GitHub personal access token

### 5. Slack Webhook (Optional)
- **Kind**: Secret text
- **ID**: `slack-webhook`
- **Secret**: Your Slack webhook URL

## 📚 Shared Library Configuration

### Step 1: Configure Global Pipeline Library

1. Go to **Manage Jenkins** → **Configure System**
2. Scroll to **Global Pipeline Libraries**
3. Click **Add** and configure:

```
Name: luxe-shared-library
Default version: main
Load implicitly: ✓ (checked)
Allow default version to be overridden: ✓ (checked)
Include @Library changes in job recent changes: ✓ (checked)

Retrieval method: Modern SCM
Source Code Management: Git
Repository URL: https://github.com/your-org/jenkins-shared-library
Credentials: 4ca4b912-d2aa-4af3-bc7b-0e12d9b88542
```

### Step 2: Create Shared Library Repository

Create a new Git repository with the shared library code:

```bash
# Create repository structure
mkdir jenkins-shared-library
cd jenkins-shared-library

# Copy shared library files
cp -r /path/to/luxe-jewelry-store/jenkins-shared-library/* .

# Initialize Git repository
git init
git add .
git commit -m "Initial shared library implementation"
git remote add origin https://github.com/your-org/jenkins-shared-library.git
git push -u origin main
```

## 🚀 Pipeline Job Configuration

### Step 1: Create Multibranch Pipeline

1. Go to Jenkins dashboard
2. Click **New Item**
3. Enter name: `Luxe-Jewelry-Store`
4. Select **Multibranch Pipeline**
5. Click **OK**

### Step 2: Configure Branch Sources

**Branch Sources** section:
- **Source**: Git
- **Repository URL**: `https://github.com/Israelatia/Luxe-Jewelry-Store`
- **Credentials**: `4ca4b912-d2aa-4af3-bc7b-0e12d9b88542`

**Behaviors**:
- ✓ Discover branches
- ✓ Discover pull requests from origin
- ✓ Clean before checkout

**Property strategy**: All branches get the same properties

### Step 3: Build Configuration

**Build Configuration**:
- **Mode**: by Jenkinsfile
- **Script Path**: `Jenkinsfile`

**Scan Repository Triggers**:
- ✓ Periodically if not otherwise run
- **Interval**: 1 day

## 🔔 GitHub Webhook Configuration

### Step 1: Configure Jenkins URL

1. Go to **Manage Jenkins** → **Configure System**
2. Set **Jenkins URL**: `http://your-jenkins-server:8080/`

### Step 2: Setup GitHub Webhook

In your GitHub repository:

1. Go to **Settings** → **Webhooks**
2. Click **Add webhook**
3. Configure:
   - **Payload URL**: `http://your-jenkins-server:8080/github-webhook/`
   - **Content type**: `application/json`
   - **Events**: Send me everything (or select Push events and Pull requests)
   - **Active**: ✓ checked

## 🐳 Docker Configuration

### Step 1: Docker Socket Access

Ensure Jenkins can access Docker:

```bash
# Add jenkins user to docker group
sudo usermod -aG docker jenkins

# Restart Jenkins
sudo systemctl restart jenkins
```

### Step 2: Custom Jenkins Agent

The pipeline uses a custom Jenkins agent image. Build and push it:

```bash
# Build the custom agent
cd /path/to/luxe-jewelry-store/infra
docker build -f Dockerfile.jenkins-agent -t israelatia/luxe-jenkins-agent:latest .

# Push to registry
docker push israelatia/luxe-jenkins-agent:latest
```

## 🧪 Testing the Pipeline

### Step 1: Trigger Initial Build

1. Go to your pipeline job
2. Click **Scan Repository Now**
3. Wait for branch discovery
4. Click **Build Now** on the main branch

### Step 2: Verify Stages

Check that all stages execute successfully:
- ✅ Checkout SCM
- ✅ Verify Tools
- ✅ Install Dependencies
- ✅ Registry Authentication
- ✅ Security & Quality (parallel)
- ✅ Build & Push Images (parallel)
- ✅ Deploy Application
- ✅ Validate Deployment

### Step 3: Check Artifacts

Verify these artifacts are generated:
- Test results (JUnit XML)
- Coverage reports (HTML)
- Security scan reports (JSON)
- Code quality reports (TXT)

## 📊 Pipeline Parameters

The pipeline supports these parameters:

| Parameter | Options | Default | Description |
|-----------|---------|---------|-------------|
| `TARGET_REGISTRY` | `israelatia`, `localhost:8082` | `israelatia` | Target Docker registry |
| `DEPLOY_ENVIRONMENT` | `development`, `staging`, `production` | `development` | Deployment environment |
| `PUSH_TO_NEXUS` | `true`, `false` | `true` | Push images to Nexus |
| `PUSH_TO_DOCKERHUB` | `true`, `false` | `true` | Push images to Docker Hub |

## 🔍 Troubleshooting

### Common Issues

**1. Shared Library Not Found**
```
Error: Library 'luxe-shared-library' not found
```
**Solution**: Verify shared library configuration and repository access.

**2. Docker Permission Denied**
```
Error: permission denied while trying to connect to Docker daemon
```
**Solution**: Add jenkins user to docker group and restart Jenkins.

**3. Registry Authentication Failed**
```
Error: unauthorized: authentication required
```
**Solution**: Verify Docker Hub and Nexus credentials in Jenkins.

**4. Snyk Token Invalid**
```
Error: Unauthorized
```
**Solution**: Check Snyk API token in Jenkins credentials.

### Debug Commands

```bash
# Check Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# Check Docker access
docker ps

# Test registry connectivity
docker login localhost:8082
docker login
```

## 🚀 Advanced Configuration

### Blue Ocean Interface

1. Install Blue Ocean plugin
2. Access via: `http://jenkins-server:8080/blue`
3. Enhanced pipeline visualization and editing

### Pipeline as Code

The pipeline supports GitOps approach:
- All configuration in `Jenkinsfile`
- Version controlled pipeline changes
- Branch-specific pipeline behavior

### Slack Notifications

Configure Slack integration:
1. Create Slack app and webhook
2. Add webhook URL to Jenkins credentials
3. Notifications sent automatically on build status

## 📈 Performance Optimization

### Build Agents

- Use Docker-based agents for isolation
- Scale agents based on build load
- Consider Kubernetes for dynamic scaling

### Caching

- Docker layer caching enabled
- Dependency caching for faster builds
- Artifact caching between builds

### Parallel Execution

The pipeline uses parallel stages for:
- Security scanning
- Unit testing  
- Code quality checks
- Image building (backend/frontend)

This reduces total build time significantly.

## 🔒 Security Best Practices

1. **Credentials Management**
   - Use Jenkins credentials store
   - Rotate credentials regularly
   - Limit credential scope

2. **Pipeline Security**
   - Sandbox execution enabled
   - Script approval for new functions
   - Regular security updates

3. **Container Security**
   - Scan images for vulnerabilities
   - Use minimal base images
   - Regular image updates

## 📚 Additional Resources

- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Docker Pipeline Plugin](https://plugins.jenkins.io/docker-workflow/)
- [Shared Library Documentation](https://www.jenkins.io/doc/book/pipeline/shared-libraries/)
- [Blue Ocean Documentation](https://www.jenkins.io/doc/book/blueocean/)

---

This configuration provides a robust, scalable CI/CD pipeline with proper security, testing, and deployment capabilities.
