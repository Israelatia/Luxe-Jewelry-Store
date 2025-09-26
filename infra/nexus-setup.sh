#!/bin/bash

# Nexus Repository Setup Script
# This script helps set up Nexus with Docker registry configuration

set -e

echo "🚀 Starting Nexus Repository Setup..."

# Configuration variables
NEXUS_URL="http://localhost:8081"
NEXUS_USER="admin"
DOCKER_REGISTRY_PORT="8082"
DOCKER_GROUP_PORT="8083"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to wait for Nexus to be ready
wait_for_nexus() {
    print_status "Waiting for Nexus to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$NEXUS_URL/service/rest/v1/status" > /dev/null 2>&1; then
            print_status "Nexus is ready!"
            return 0
        fi
        
        echo "Attempt $attempt/$max_attempts - Nexus not ready yet, waiting 10 seconds..."
        sleep 10
        ((attempt++))
    done
    
    print_error "Nexus failed to start within expected time"
    return 1
}

# Function to get admin password
get_admin_password() {
    if docker exec nexus-repository test -f /nexus-data/admin.password 2>/dev/null; then
        NEXUS_PASSWORD=$(docker exec nexus-repository cat /nexus-data/admin.password 2>/dev/null)
        print_status "Retrieved admin password from container"
    else
        print_warning "Admin password file not found. Using default password 'admin123'"
        NEXUS_PASSWORD="admin123"
    fi
}

# Function to create Docker repositories
create_docker_repositories() {
    print_status "Creating Docker repositories..."
    
    # Create Docker hosted repository
    curl -u "$NEXUS_USER:$NEXUS_PASSWORD" \
        -H "Content-Type: application/json" \
        -d '{
            "name": "docker-hosted",
            "online": true,
            "storage": {
                "blobStoreName": "default",
                "strictContentTypeValidation": true,
                "writePolicy": "ALLOW"
            },
            "docker": {
                "v1Enabled": false,
                "forceBasicAuth": true,
                "httpPort": 8082
            }
        }' \
        "$NEXUS_URL/service/rest/v1/repositories/docker/hosted" || print_warning "Docker hosted repository might already exist"
    
    # Create Docker proxy repository (Docker Hub)
    curl -u "$NEXUS_USER:$NEXUS_PASSWORD" \
        -H "Content-Type: application/json" \
        -d '{
            "name": "docker-proxy",
            "online": true,
            "storage": {
                "blobStoreName": "default",
                "strictContentTypeValidation": true
            },
            "proxy": {
                "remoteUrl": "https://registry-1.docker.io",
                "contentMaxAge": 1440,
                "metadataMaxAge": 1440
            },
            "negativeCache": {
                "enabled": true,
                "timeToLive": 1440
            },
            "httpClient": {
                "blocked": false,
                "autoBlock": true
            },
            "docker": {
                "v1Enabled": false,
                "forceBasicAuth": true
            },
            "dockerProxy": {
                "indexType": "HUB"
            }
        }' \
        "$NEXUS_URL/service/rest/v1/repositories/docker/proxy" || print_warning "Docker proxy repository might already exist"
    
    # Create Docker group repository
    curl -u "$NEXUS_USER:$NEXUS_PASSWORD" \
        -H "Content-Type: application/json" \
        -d '{
            "name": "docker-group",
            "online": true,
            "storage": {
                "blobStoreName": "default",
                "strictContentTypeValidation": true
            },
            "group": {
                "memberNames": ["docker-hosted", "docker-proxy"]
            },
            "docker": {
                "v1Enabled": false,
                "forceBasicAuth": true,
                "httpPort": 8083
            }
        }' \
        "$NEXUS_URL/service/rest/v1/repositories/docker/group" || print_warning "Docker group repository might already exist"
    
    print_status "Docker repositories created successfully!"
}

# Function to configure Docker client
configure_docker_client() {
    print_status "Configuring Docker client for Nexus..."
    
    # Add insecure registry to Docker daemon (for development)
    echo "To configure Docker client, add the following to your Docker daemon configuration:"
    echo "File: /etc/docker/daemon.json"
    echo "{"
    echo "  \"insecure-registries\": ["
    echo "    \"localhost:8082\","
    echo "    \"localhost:8083\""
    echo "  ]"
    echo "}"
    echo ""
    echo "Then restart Docker daemon: sudo systemctl restart docker"
}

# Main execution
main() {
    print_status "Starting Nexus setup process..."
    
    # Start Nexus if not running
    if ! docker ps | grep -q nexus-repository; then
        print_status "Starting Nexus container..."
        docker-compose -f docker-compose.nexus.yml up -d nexus
    else
        print_status "Nexus container is already running"
    fi
    
    # Wait for Nexus to be ready
    wait_for_nexus
    
    # Get admin password
    get_admin_password
    
    # Create Docker repositories
    create_docker_repositories
    
    # Configure Docker client
    configure_docker_client
    
    print_status "✅ Nexus setup completed!"
    echo ""
    echo "📋 Access Information:"
    echo "   Nexus UI: $NEXUS_URL"
    echo "   Username: $NEXUS_USER"
    echo "   Password: $NEXUS_PASSWORD"
    echo "   Docker Registry (Push): localhost:8082"
    echo "   Docker Registry (Pull): localhost:8083"
    echo ""
    echo "🔐 Login to Docker registry:"
    echo "   docker login localhost:8082 -u $NEXUS_USER -p $NEXUS_PASSWORD"
    echo ""
    echo "📦 Example usage:"
    echo "   docker tag myapp:latest localhost:8082/myapp:latest"
    echo "   docker push localhost:8082/myapp:latest"
}

# Run main function
main "$@"
