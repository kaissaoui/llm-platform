#!/bin/bash

# LLM Platform - Deployment Server Setup Script
# This script sets up a deployment server with Docker, Docker Compose, and the necessary structure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-development}
DEPLOYMENT_DIR="/opt/llm-platform-${ENVIRONMENT}"
USER=$(whoami)

echo -e "${BLUE}🚀 Setting up LLM Platform deployment server for ${ENVIRONMENT} environment${NC}"
echo -e "${BLUE}=====================================================${NC}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Update system packages
print_status "Updating system packages..."
sudo apt-get update -qq

# Install required packages
print_status "Installing required packages..."
sudo apt-get install -y -qq \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install Docker
if ! command -v docker &> /dev/null; then
    print_status "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    print_warning "Docker installed. You may need to log out and back in for group changes to take effect."
else
    print_status "Docker is already installed"
fi

# Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    print_status "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    print_status "Docker Compose is already installed"
fi

# Create deployment directory
print_status "Creating deployment directory: ${DEPLOYMENT_DIR}"
sudo mkdir -p ${DEPLOYMENT_DIR}
sudo chown $USER:$USER ${DEPLOYMENT_DIR}

# Create necessary subdirectories
print_status "Creating subdirectories..."
mkdir -p ${DEPLOYMENT_DIR}/{scripts,nginx,monitoring,logs,ssl}

# Create environment-specific .env file
print_status "Creating environment configuration file..."
cat > ${DEPLOYMENT_DIR}/.env << EOF
# LLM Platform - ${ENVIRONMENT} Environment Configuration

# Environment
NODE_ENV=production
GITHUB_REPOSITORY=your-username/llm-platform

# Database Configuration
DATABASE_URL=postgresql://postgres:your-secure-password@localhost:5432/llm_platform_${ENVIRONMENT}
POSTGRES_DB=llm_platform_${ENVIRONMENT}
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your-secure-password

# Redis Configuration
REDIS_URL=redis://:your-redis-password@localhost:6379
REDIS_PASSWORD=your-redis-password

# Security
JWT_SECRET=your-super-secret-jwt-key-change-in-production
NEXTAUTH_SECRET=your-nextauth-secret-key
NEXTAUTH_URL=http://localhost:3000

# LLM API Keys
OPENAI_API_KEY=your-openai-api-key-here
ANTHROPIC_API_KEY=your-anthropic-api-key-here
GOOGLE_API_KEY=your-google-api-key-here

# Monitoring
GRAFANA_PASSWORD=admin123

# Network Configuration
NETWORK_SUBNET=172.20.0.0/16
EOF

# Create production docker-compose file
print_status "Creating production Docker Compose configuration..."
cp docker-compose.prod.yml ${DEPLOYMENT_DIR}/docker-compose.yml

# Create basic nginx configuration
print_status "Creating Nginx configuration..."
cat > ${DEPLOYMENT_DIR}/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
    
    # Upstream for the application
    upstream app {
        server app:3000;
    }
    
    # Health check endpoint
    server {
        listen 80;
        server_name localhost;
        
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
    
    # Main application
    server {
        listen 80;
        server_name _;
        
        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;
        add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
        
        # API rate limiting
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://app;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
        }
        
        # Main application
        location / {
            proxy_pass http://app;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
        }
    }
}
EOF

# Create monitoring configuration
print_status "Creating monitoring configuration..."
cat > ${DEPLOYMENT_DIR}/monitoring/prometheus.yml << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'llm-platform'
    static_configs:
      - targets: ['app:3000']
    metrics_path: '/api/metrics'
    scrape_interval: 30s

  - job_name: 'nginx'
    static_configs:
      - targets: ['nginx:80']
    metrics_path: '/nginx_status'
    scrape_interval: 30s

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres:5432']
    scrape_interval: 30s

  - job_name: 'redis'
    static_configs:
      - targets: ['redis:6379']
    scrape_interval: 30s
EOF

# Create Grafana datasource configuration
mkdir -p ${DEPLOYMENT_DIR}/monitoring/grafana/datasources
cat > ${DEPLOYMENT_DIR}/monitoring/grafana/datasources/prometheus.yml << EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF

# Create basic dashboard
mkdir -p ${DEPLOYMENT_DIR}/monitoring/grafana/dashboards
cat > ${DEPLOYMENT_DIR}/monitoring/grafana/dashboards/llm-platform.json << EOF
{
  "dashboard": {
    "id": null,
    "title": "LLM Platform Dashboard",
    "tags": ["llm-platform"],
    "style": "dark",
    "timezone": "browser",
    "panels": [],
    "time": {
      "from": "now-6h",
      "to": "now"
    },
    "refresh": "5s"
  }
}
EOF

# Create deployment script
print_status "Creating deployment script..."
cat > ${DEPLOYMENT_DIR}/deploy.sh << 'EOF'
#!/bin/bash

# LLM Platform Deployment Script
set -e

ENVIRONMENT=${1:-development}
DEPLOYMENT_DIR="/opt/llm-platform-${ENVIRONMENT}"

echo "🚀 Deploying LLM Platform to ${ENVIRONMENT} environment..."

cd ${DEPLOYMENT_DIR}

# Pull latest images
echo "📥 Pulling latest Docker images..."
docker-compose pull

# Stop existing services
echo "🛑 Stopping existing services..."
docker-compose down

# Start services
echo "🚀 Starting services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 30

# Health check
echo "🏥 Performing health check..."
if curl -f http://localhost:3000/api/health; then
    echo "✅ Deployment successful! Health check passed."
else
    echo "❌ Health check failed!"
    docker-compose logs app
    exit 1
fi

echo "🎉 Deployment completed successfully!"
EOF

chmod +x ${DEPLOYMENT_DIR}/deploy.sh

# Create rollback script
print_status "Creating rollback script..."
cat > ${DEPLOYMENT_DIR}/rollback.sh << 'EOF'
#!/bin/bash

# LLM Platform Rollback Script
set -e

ENVIRONMENT=${1:-development}
DEPLOYMENT_DIR="/opt/llm-platform-${ENVIRONMENT}"

echo "🔄 Rolling back LLM Platform in ${ENVIRONMENT} environment..."

cd ${DEPLOYMENT_DIR}

# Stop services
echo "🛑 Stopping services..."
docker-compose down

# Remove latest image to force using previous version
echo "🗑️  Removing latest image..."
docker rmi $(docker images -q ghcr.io/*/llm-platform:latest) 2>/dev/null || true

# Start services with previous image
echo "🚀 Starting services with previous image..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 30

# Health check
echo "🏥 Performing health check..."
if curl -f http://localhost:3000/api/health; then
    echo "✅ Rollback successful! Health check passed."
else
    echo "❌ Rollback failed!"
    docker-compose logs app
    exit 1
fi

echo "🎉 Rollback completed successfully!"
EOF

chmod +x ${DEPLOYMENT_DIR}/rollback.sh

# Create systemd service file
print_status "Creating systemd service..."
sudo tee /etc/systemd/system/llm-platform-${ENVIRONMENT}.service > /dev/null << EOF
[Unit]
Description=LLM Platform ${ENVIRONMENT}
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${DEPLOYMENT_DIR}
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable llm-platform-${ENVIRONMENT}.service

# Create log rotation configuration
print_status "Setting up log rotation..."
sudo tee /etc/logrotate.d/llm-platform-${ENVIRONMENT} > /dev/null << EOF
${DEPLOYMENT_DIR}/logs/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
    postrotate
        systemctl reload llm-platform-${ENVIRONMENT}.service
    endscript
}
EOF

# Set up firewall rules
print_status "Configuring firewall..."
if command -v ufw &> /dev/null; then
    sudo ufw allow 22/tcp comment 'SSH'
    sudo ufw allow 80/tcp comment 'HTTP'
    sudo ufw allow 443/tcp comment 'HTTPS'
    sudo ufw --force enable
    print_status "Firewall configured with UFW"
elif command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-service=ssh
    sudo firewall-cmd --permanent --add-service=http
    sudo firewall-cmd --permanent --add-service=https
    sudo firewall-cmd --reload
    print_status "Firewall configured with firewalld"
else
    print_warning "No firewall detected. Please configure manually."
fi

# Create monitoring script
print_status "Creating monitoring script..."
cat > ${DEPLOYMENT_DIR}/monitor.sh << 'EOF'
#!/bin/bash

# LLM Platform Monitoring Script
set -e

ENVIRONMENT=${1:-development}
DEPLOYMENT_DIR="/opt/llm-platform-${ENVIRONMENT}"

echo "📊 LLM Platform ${ENVIRONMENT} Status Report"
echo "=========================================="

cd ${DEPLOYMENT_DIR}

# Docker containers status
echo -e "\n🐳 Container Status:"
docker-compose ps

# Resource usage
echo -e "\n💾 Resource Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"

# Health check
echo -e "\n🏥 Health Check:"
if curl -s -f http://localhost:3000/api/health > /dev/null; then
    echo "✅ Application is healthy"
else
    echo "❌ Application health check failed"
fi

# Log summary
echo -e "\n📝 Recent Logs (last 10 lines):"
docker-compose logs --tail=10 app

echo -e "\n📊 Monitoring URLs:"
echo "Application: http://localhost:3000"
echo "Grafana: http://localhost:3001 (admin/admin123)"
echo "Prometheus: http://localhost:9090"
EOF

chmod +x ${DEPLOYMENT_DIR}/monitor.sh

# Final setup
print_status "Finalizing setup..."

# Set proper permissions
sudo chown -R $USER:$USER ${DEPLOYMENT_DIR}

# Create a simple status check script
cat > ${DEPLOYMENT_DIR}/status.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
docker-compose ps
EOF

chmod +x ${DEPLOYMENT_DIR}/status.sh

print_status "Deployment server setup completed successfully!"
echo -e "${BLUE}=====================================================${NC}"
echo -e "${GREEN}🎯 Next steps:${NC}"
echo -e "1. Edit ${DEPLOYMENT_DIR}/.env with your actual configuration"
echo -e "2. Run: cd ${DEPLOYMENT_DIR} && ./deploy.sh"
echo -e "3. Check status: ./status.sh"
echo -e "4. Monitor: ./monitor.sh"
echo -e ""
echo -e "${GREEN}📁 Deployment directory: ${DEPLOYMENT_DIR}${NC}"
echo -e "${GREEN}🔧 Service name: llm-platform-${ENVIRONMENT}${NC}"
echo -e "${GREEN}📊 Monitoring: http://localhost:3001 (admin/admin123)${NC}"
echo -e ""
echo -e "${YELLOW}⚠️  Remember to:${NC}"
echo -e "- Change default passwords in .env file"
echo -e "- Configure SSL certificates for production"
echo -e "- Set up backup strategies"
echo -e "- Configure monitoring alerts"
echo -e ""
echo -e "${BLUE}Happy deploying! 🚀${NC}"
