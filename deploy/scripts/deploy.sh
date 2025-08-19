#!/bin/bash

# Deployment script for LLM Platform
# Usage: ./deploy.sh [environment] [version]

set -e

# Configuration
ENVIRONMENT=${1:-staging}
VERSION=${2:-latest}
APP_NAME="llm-platform"
DOCKER_REGISTRY="ghcr.io/your-org"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if required tools are installed
check_requirements() {
    log "Checking deployment requirements..."
    
    command -v docker >/dev/null 2>&1 || error "Docker is required but not installed"
    command -v docker-compose >/dev/null 2>&1 || error "Docker Compose is required but not installed"
    command -v kubectl >/dev/null 2>&1 || error "kubectl is required but not installed"
    
    log "Requirements check passed"
}

# Validate environment
validate_environment() {
    log "Validating environment: $ENVIRONMENT"
    
    case $ENVIRONMENT in
        development|dev)
            ENVIRONMENT="development"
            DEPLOY_PATH="/opt/llm-platform-dev"
            ;;
        staging|stage)
            ENVIRONMENT="staging"
            DEPLOY_PATH="/opt/llm-platform-staging"
            ;;
        production|prod)
            ENVIRONMENT="production"
            DEPLOY_PATH="/opt/llm-platform-prod"
            ;;
        *)
            error "Invalid environment: $ENVIRONMENT. Use: development, staging, or production"
            ;;
    esac
    
    log "Environment validated: $ENVIRONMENT"
}

# Backup current deployment
backup_deployment() {
    log "Creating backup of current deployment..."
    
    if [ -d "$DEPLOY_PATH" ]; then
        BACKUP_DIR="$DEPLOY_PATH/backups/$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        
        if [ -f "$DEPLOY_PATH/docker-compose.yml" ]; then
            cp "$DEPLOY_PATH/docker-compose.yml" "$BACKUP_DIR/"
        fi
        
        if [ -f "$DEPLOY_PATH/.env" ]; then
            cp "$DEPLOY_PATH/.env" "$BACKUP_DIR/"
        fi
        
        log "Backup created at: $BACKUP_DIR"
    fi
}

# Pull latest image
pull_image() {
    log "Pulling latest Docker image: $DOCKER_REGISTRY/$APP_NAME:$VERSION"
    
    docker pull "$DOCKER_REGISTRY/$APP_NAME:$VERSION" || error "Failed to pull Docker image"
    
    log "Image pulled successfully"
}

# Update docker-compose file
update_compose() {
    log "Updating docker-compose configuration..."
    
    mkdir -p "$DEPLOY_PATH"
    
    # Create docker-compose.yml
    cat > "$DEPLOY_PATH/docker-compose.yml" << EOF
version: '3.8'

services:
  app:
    image: $DOCKER_REGISTRY/$APP_NAME:$VERSION
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=$ENVIRONMENT
      - DATABASE_URL=\${DATABASE_URL}
      - REDIS_URL=\${REDIS_URL}
      - JWT_SECRET=\${JWT_SECRET}
      - OPENAI_API_KEY=\${OPENAI_API_KEY}
      - ANTHROPIC_API_KEY=\${ANTHROPIC_API_KEY}
      - GOOGLE_API_KEY=\${GOOGLE_API_KEY}
    depends_on:
      - postgres
      - redis
    networks:
      - llm-platform
    restart: unless-stopped

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=\${POSTGRES_DB}
      - POSTGRES_USER=\${POSTGRES_USER}
      - POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - llm-platform
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    networks:
      - llm-platform
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:

networks:
  llm-platform:
    driver: bridge
EOF

    log "Docker-compose configuration updated"
}

# Deploy with Docker Compose
deploy_docker_compose() {
    log "Deploying with Docker Compose..."
    
    cd "$DEPLOY_PATH"
    
    # Stop existing services
    log "Stopping existing services..."
    docker-compose down --remove-orphans || warn "Some services may not have been running"
    
    # Start new services
    log "Starting new services..."
    docker-compose up -d
    
    log "Docker Compose deployment completed"
}

# Deploy with Kubernetes
deploy_kubernetes() {
    log "Deploying with Kubernetes..."
    
    # Update deployment image
    kubectl set image deployment/llm-platform llm-platform="$DOCKER_REGISTRY/$APP_NAME:$VERSION" -n production
    
    # Wait for rollout
    log "Waiting for deployment rollout..."
    kubectl rollout status deployment/llm-platform -n production --timeout=300s
    
    log "Kubernetes deployment completed"
}

# Health check
health_check() {
    log "Performing health check..."
    
    local max_attempts=30
    local attempt=1
    local health_endpoint=""
    
    case $ENVIRONMENT in
        development)
            health_endpoint="http://localhost:3000/health"
            ;;
        staging)
            health_endpoint="http://staging.your-domain.com/health"
            ;;
        production)
            health_endpoint="https://your-domain.com/health"
            ;;
    esac
    
    if [ "$ENVIRONMENT" = "production" ]; then
        # Kubernetes health check
        kubectl get pods -n production -l app=llm-platform -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' | grep -q "True" || error "Kubernetes deployment health check failed"
        log "Kubernetes health check passed"
    else
        # Docker Compose health check
        while [ $attempt -le $max_attempts ]; do
            if curl -f "$health_endpoint" >/dev/null 2>&1; then
                log "Health check passed after $attempt attempts"
                return 0
            fi
            
            log "Health check attempt $attempt/$max_attempts failed, retrying in 10 seconds..."
            sleep 10
            attempt=$((attempt + 1))
        done
        
        error "Health check failed after $max_attempts attempts"
    fi
}

# Rollback function
rollback() {
    error "Deployment failed, initiating rollback..."
    
    if [ -d "$DEPLOY_PATH/backups" ]; then
        LATEST_BACKUP=$(ls -t "$DEPLOY_PATH/backups" | head -1)
        if [ -n "$LATEST_BACKUP" ]; then
            log "Rolling back to: $LATEST_BACKUP"
            
            cd "$DEPLOY_PATH"
            docker-compose down
            
            if [ -f "backups/$LATEST_BACKUP/docker-compose.yml" ]; then
                cp "backups/$LATEST_BACKUP/docker-compose.yml" .
                docker-compose up -d
                log "Rollback completed"
            else
                error "Rollback failed: backup files not found"
            fi
        fi
    fi
}

# Cleanup old images
cleanup() {
    log "Cleaning up old Docker images..."
    
    # Remove unused images
    docker image prune -f
    
    # Remove old backups (keep last 5)
    if [ -d "$DEPLOY_PATH/backups" ]; then
        cd "$DEPLOY_PATH/backups"
        ls -t | tail -n +6 | xargs -r rm -rf
    fi
    
    log "Cleanup completed"
}

# Main deployment function
main() {
    log "Starting deployment to $ENVIRONMENT environment"
    
    # Set error handling
    trap 'rollback' ERR
    
    check_requirements
    validate_environment
    backup_deployment
    pull_image
    update_compose
    
    if [ "$ENVIRONMENT" = "production" ]; then
        deploy_kubernetes
    else
        deploy_docker_compose
    fi
    
    health_check
    cleanup
    
    log "Deployment to $ENVIRONMENT completed successfully!"
    
    # Remove error trap
    trap - ERR
}

# Run main function
main "$@"
