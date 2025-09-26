#!/bin/bash

# Production Deployment Script for Luxe Jewelry Store
# This script handles production deployment with zero-downtime rolling updates

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEPLOY_ENV="${DEPLOY_ENV:-production}"
REGISTRY="${REGISTRY:-israelatia}"
APP_NAME="${APP_NAME:-luxe-jewelry-store}"
VERSION="${VERSION:-latest}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Docker is installed and running
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi
    
    # Check if docker-compose is installed
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    
    # Check if required environment files exist
    if [[ ! -f "$PROJECT_ROOT/.env.production" ]]; then
        log_warning "Production environment file not found, creating default..."
        create_production_env
    fi
    
    log_success "Prerequisites check passed"
}

# Create production environment file
create_production_env() {
    cat > "$PROJECT_ROOT/.env.production" << EOF
# Production Environment Configuration
DEPLOY_ENV=production
REGISTRY=${REGISTRY}
APP_NAME=${APP_NAME}
VERSION=${VERSION}

# Database Configuration
DATABASE_URL=postgresql://luxe_user:secure_password@db:5432/luxe_jewelry_store
REDIS_URL=redis://redis:6379/0

# Security Configuration
JWT_SECRET_KEY=your-super-secure-jwt-secret-key-change-this
ENCRYPTION_KEY=your-32-character-encryption-key

# External Services
STRIPE_SECRET_KEY=sk_live_your_stripe_secret_key
STRIPE_PUBLISHABLE_KEY=pk_live_your_stripe_publishable_key
SENDGRID_API_KEY=your_sendgrid_api_key

# Monitoring
SENTRY_DSN=your_sentry_dsn_for_error_tracking
NEW_RELIC_LICENSE_KEY=your_new_relic_license_key

# Performance
WORKERS=4
MAX_CONNECTIONS=1000
CACHE_TTL=3600

# Security Headers
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
EOF
    
    log_info "Created default production environment file at .env.production"
    log_warning "Please update the environment variables with your actual production values"
}

# Backup current deployment
backup_current_deployment() {
    log_info "Creating backup of current deployment..."
    
    local backup_dir="$PROJECT_ROOT/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup database if running
    if docker ps --format "table {{.Names}}" | grep -q "luxe.*db"; then
        log_info "Backing up database..."
        docker exec luxe-jewelry-store_db_1 pg_dump -U luxe_user luxe_jewelry_store > "$backup_dir/database_backup.sql" || true
    fi
    
    # Backup current docker-compose state
    docker-compose -f "$PROJECT_ROOT/docker-compose.production.yml" config > "$backup_dir/docker-compose.backup.yml" || true
    
    # Backup environment files
    cp "$PROJECT_ROOT/.env.production" "$backup_dir/.env.production.backup" || true
    
    log_success "Backup created at $backup_dir"
    echo "$backup_dir" > "$PROJECT_ROOT/.last_backup"
}

# Pull latest images
pull_images() {
    log_info "Pulling latest images from registry..."
    
    local images=(
        "${REGISTRY}/${APP_NAME}-backend:${VERSION}"
        "${REGISTRY}/${APP_NAME}-frontend:${VERSION}"
    )
    
    for image in "${images[@]}"; do
        log_info "Pulling $image..."
        if ! docker pull "$image"; then
            log_error "Failed to pull $image"
            exit 1
        fi
    done
    
    log_success "All images pulled successfully"
}

# Health check function
health_check() {
    local service_url="$1"
    local max_attempts=30
    local attempt=1
    
    log_info "Performing health check on $service_url..."
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -f -s "$service_url" > /dev/null; then
            log_success "Health check passed for $service_url"
            return 0
        fi
        
        log_info "Health check attempt $attempt/$max_attempts failed, retrying in 10 seconds..."
        sleep 10
        ((attempt++))
    done
    
    log_error "Health check failed for $service_url after $max_attempts attempts"
    return 1
}

# Rolling deployment
rolling_deployment() {
    log_info "Starting rolling deployment..."
    
    # Set environment variables
    export DEPLOY_ENV="$DEPLOY_ENV"
    export REGISTRY="$REGISTRY"
    export APP_NAME="$APP_NAME"
    export VERSION="$VERSION"
    
    # Load production environment
    if [[ -f "$PROJECT_ROOT/.env.production" ]]; then
        set -a
        source "$PROJECT_ROOT/.env.production"
        set +a
    fi
    
    # Deploy with zero downtime
    log_info "Deploying backend service..."
    docker-compose -f "$PROJECT_ROOT/docker-compose.production.yml" up -d --no-deps backend
    
    # Wait for backend to be healthy
    sleep 30
    if ! health_check "http://localhost:8000/health"; then
        log_error "Backend health check failed, rolling back..."
        rollback_deployment
        exit 1
    fi
    
    log_info "Deploying frontend service..."
    docker-compose -f "$PROJECT_ROOT/docker-compose.production.yml" up -d --no-deps frontend
    
    # Wait for frontend to be healthy
    sleep 15
    if ! health_check "http://localhost:80/"; then
        log_error "Frontend health check failed, rolling back..."
        rollback_deployment
        exit 1
    fi
    
    # Clean up old images
    log_info "Cleaning up old images..."
    docker image prune -f || true
    
    log_success "Rolling deployment completed successfully"
}

# Rollback function
rollback_deployment() {
    log_warning "Initiating rollback..."
    
    if [[ -f "$PROJECT_ROOT/.last_backup" ]]; then
        local backup_dir
        backup_dir=$(cat "$PROJECT_ROOT/.last_backup")
        
        if [[ -f "$backup_dir/docker-compose.backup.yml" ]]; then
            log_info "Rolling back to previous deployment..."
            docker-compose -f "$backup_dir/docker-compose.backup.yml" up -d
            log_success "Rollback completed"
        else
            log_error "Backup configuration not found"
        fi
    else
        log_error "No backup information found"
    fi
}

# Post-deployment verification
post_deployment_verification() {
    log_info "Running post-deployment verification..."
    
    # Check all services are running
    local services=("backend" "frontend")
    for service in "${services[@]}"; do
        if ! docker-compose -f "$PROJECT_ROOT/docker-compose.production.yml" ps "$service" | grep -q "Up"; then
            log_error "Service $service is not running"
            return 1
        fi
    done
    
    # Run smoke tests
    log_info "Running smoke tests..."
    
    # Test backend API
    if ! curl -f -s "http://localhost:8000/products" > /dev/null; then
        log_error "Backend API smoke test failed"
        return 1
    fi
    
    # Test frontend
    if ! curl -f -s "http://localhost:80/" > /dev/null; then
        log_error "Frontend smoke test failed"
        return 1
    fi
    
    log_success "Post-deployment verification passed"
}

# Cleanup function
cleanup() {
    log_info "Performing cleanup..."
    
    # Remove old containers
    docker container prune -f || true
    
    # Remove old images (keep last 3 versions)
    docker images "${REGISTRY}/${APP_NAME}-backend" --format "table {{.Tag}}\t{{.ID}}" | tail -n +4 | awk '{print $2}' | xargs -r docker rmi || true
    docker images "${REGISTRY}/${APP_NAME}-frontend" --format "table {{.Tag}}\t{{.ID}}" | tail -n +4 | awk '{print $2}' | xargs -r docker rmi || true
    
    log_success "Cleanup completed"
}

# Main deployment function
main() {
    log_info "Starting production deployment for $APP_NAME version $VERSION"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --version)
                VERSION="$2"
                shift 2
                ;;
            --registry)
                REGISTRY="$2"
                shift 2
                ;;
            --rollback)
                rollback_deployment
                exit 0
                ;;
            --health-check)
                health_check "http://localhost:8000/health"
                health_check "http://localhost:80/"
                exit 0
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --version VERSION    Specify version to deploy (default: latest)"
                echo "  --registry REGISTRY  Specify registry (default: israelatia)"
                echo "  --rollback          Rollback to previous deployment"
                echo "  --health-check      Run health checks only"
                echo "  --help              Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Execute deployment steps
    check_prerequisites
    backup_current_deployment
    pull_images
    rolling_deployment
    post_deployment_verification
    cleanup
    
    log_success "Production deployment completed successfully!"
    log_info "Application is now running at:"
    log_info "  Frontend: http://localhost:80/"
    log_info "  Backend API: http://localhost:8000/"
    log_info "  API Documentation: http://localhost:8000/docs"
}

# Trap to handle script interruption
trap 'log_error "Deployment interrupted"; exit 1' INT TERM

# Run main function
main "$@"
