# 🚀 LLM Platform - Automated CI/CD Deployment Guide

This guide will walk you through setting up automated CI/CD deployment for your LLM Platform, enabling multiple releases per day with zero downtime.

## 📋 Prerequisites

Before starting, ensure you have:

- [GitHub account](https://github.com)
- [Docker](https://docs.docker.com/get-docker/) installed locally
- [Node.js 18+](https://nodejs.org/) installed
- [AWS account](https://aws.amazon.com/) (for production deployment)

## 🏗️ Project Structure

```
llm-platform/
├── src/                    # Application source code
├── deploy/                 # Deployment configurations
├── .github/workflows/      # GitHub Actions CI/CD
├── docker-compose.yml      # Local development
├── Dockerfile             # Production container
└── package.json           # Dependencies and scripts
```

## 🚀 Quick Start - Local Development

### 1. Clone and Setup

```bash
# Clone the repository
git clone <your-repo-url>
cd llm-platform

# Install dependencies
npm install

# Copy environment file
cp env.example .env

# Edit .env with your API keys
nano .env
```

### 2. Start Local Environment

```bash
# Start all services (PostgreSQL, Redis, Prometheus, Grafana)
docker-compose up -d

# Start the application
npm run dev
```

**Access your application:**
- Main App: http://localhost:3000
- Grafana: http://localhost:3001 (admin/admin123)
- Prometheus: http://localhost:9090

## 🔄 Setting Up Automated CI/CD

### Step 1: Configure GitHub Repository

1. **Push your code to GitHub:**
```bash
git add .
git commit -m "Initial commit with CI/CD setup"
git push origin main
```

2. **Set up GitHub Secrets:**
   - Go to your repository → Settings → Secrets and variables → Actions
   - Add the following secrets:

```bash
# Development Environment
DEV_HOST=your-dev-server-ip
DEV_USERNAME=your-dev-username
DEV_SSH_KEY=your-dev-ssh-private-key
DEV_URL=http://dev.your-domain.com

# Staging Environment
STAGING_HOST=your-staging-server-ip
STAGING_USERNAME=your-staging-username
STAGING_SSH_KEY=your-staging-ssh-private-key
STAGING_URL=http://staging.your-domain.com

# Production Environment
PROD_HOST=your-prod-server-ip
PROD_USERNAME=your-prod-username
PROD_SSH_KEY=your-prod-ssh-private-key
PROD_URL=https://your-domain.com

# Notifications
SLACK_WEBHOOK=your-slack-webhook-url
```

### Step 2: Set Up Deployment Servers

For each environment (dev, staging, prod), you need a server with:

```bash
# Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create deployment directory
sudo mkdir -p /opt/llm-platform-{environment}
sudo chown $USER:$USER /opt/llm-platform-{environment}
```

### Step 3: Configure Branch Protection

1. Go to repository → Settings → Branches
2. Add rule for `main` branch:
   - Require pull request reviews
   - Require status checks to pass
   - Require branches to be up to date

## 🔄 Deployment Workflows

### Automated Deployment

The CI/CD pipeline automatically deploys based on branch pushes:

```bash
# Deploy to Development
git push origin develop
# → Triggers automatic deployment to development environment

# Deploy to Staging
git push origin main
# → Triggers automatic deployment to staging environment

# Deploy to Production
# → Manual approval required via GitHub Actions
```

### Manual Deployment

You can also trigger deployments manually:

1. Go to Actions tab in your repository
2. Select "CI/CD Pipeline" workflow
3. Click "Run workflow"
4. Choose environment and branch
5. Click "Run workflow"

### Deployment Process

Each deployment follows this flow:

1. **Quality Checks** ✅
   - Linting
   - Type checking
   - Security audit

2. **Testing** 🧪
   - Unit tests
   - Integration tests
   - Coverage reports

3. **Build** 🏗️
   - Docker image build
   - Push to container registry

4. **Deploy** 🚀
   - SSH to target server
   - Pull latest image
   - Restart services
   - Health checks

5. **Verify** ✅
   - Health endpoint check
   - Slack notification

## 📊 Monitoring and Health Checks

### Health Endpoints

Your application automatically provides health check endpoints:

- **Health Check**: `/api/health` - Overall system health
- **Readiness**: `/api/ready` - Service readiness for traffic

### Monitoring Stack

- **Prometheus**: Metrics collection
- **Grafana**: Dashboards and visualization
- **CloudWatch**: AWS service monitoring (production)

### Alerts

- **Slack**: Deployment notifications
- **Email**: Critical alerts (configurable)
- **PagerDuty**: Incident management (optional)

## 🛠️ Troubleshooting

### Common Issues

#### 1. Deployment Failures

```bash
# Check GitHub Actions logs
# Go to Actions tab → Failed workflow → View logs

# Check server status
ssh user@server
cd /opt/llm-platform-{environment}
docker-compose ps
docker-compose logs app
```

#### 2. Health Check Failures

```bash
# Test health endpoint
curl -f http://your-domain.com/api/health

# Check application logs
docker-compose logs -f app
```

#### 3. Build Failures

```bash
# Test locally first
npm run lint
npm run type-check
npm run test
npm run build
```

### Debug Commands

```bash
# Check Docker containers
docker ps -a
docker logs <container-id>

# Check Docker Compose
docker-compose config
docker-compose ps

# Check application
curl -v http://localhost:3000/api/health
```

## 🔒 Security Best Practices

### Environment Variables

- Never commit `.env` files
- Use GitHub Secrets for sensitive data
- Rotate API keys regularly

### Access Control

- Use SSH keys, not passwords
- Limit server access to necessary users
- Regular security updates

### Monitoring

- Monitor for unusual activity
- Set up alerts for security events
- Regular security audits

## 📈 Performance Optimization

### Build Optimization

- Multi-stage Docker builds
- Layer caching
- Dependency optimization

### Deployment Optimization

- Blue-green deployments
- Rolling updates
- Health check optimization

### Resource Management

- Auto-scaling configuration
- Resource limits
- Cost monitoring

## 🔄 Continuous Improvement

### Metrics to Track

- **Deployment Frequency**: How often you deploy
- **Lead Time**: Time from commit to production
- **Mean Time to Recovery**: Time to fix issues
- **Change Failure Rate**: Percentage of failed deployments

### Optimization Opportunities

- **Build Time**: Optimize Docker layers
- **Test Time**: Parallel test execution
- **Deployment Time**: Optimize health checks
- **Rollback Time**: Faster rollback procedures

## 📚 Additional Resources

### Documentation

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Documentation](https://docs.docker.com/)
- [Next.js Documentation](https://nextjs.org/docs)

### Tools

- [GitHub CLI](https://cli.github.com/) - GitHub from command line
- [Docker Desktop](https://www.docker.com/products/docker-desktop) - Docker GUI
- [Portainer](https://www.portainer.io/) - Docker management

### Community

- [GitHub Community](https://github.com/orgs/community/discussions)
- [Docker Community](https://forums.docker.com/)
- [Next.js Discord](https://discord.gg/nextjs)

## 🆘 Getting Help

### Support Channels

1. **GitHub Issues**: Create an issue in your repository
2. **Documentation**: Check this guide and linked resources
3. **Community**: Use the community resources above

### Emergency Procedures

1. **Immediate Rollback**: Use GitHub Actions manual rollback
2. **Server Access**: SSH to server and restart services
3. **Database Issues**: Check logs and restart database service

---

## 🎯 Next Steps

1. **Set up your GitHub repository** with the code
2. **Configure environment variables** and secrets
3. **Set up deployment servers** for each environment
4. **Test the pipeline** with a small change
5. **Monitor and optimize** based on usage patterns

**Happy Deploying! 🚀**

Your LLM Platform is now set up for automated, frequent deployments with professional-grade infrastructure and monitoring.
