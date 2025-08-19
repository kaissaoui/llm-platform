# 🚀 LLM Platform - Personal AI Experience Platform

A comprehensive platform for organizing AI interactions into topic-based experiences with custom AI personalities, system prompts, and intelligent agents that optimize your workspace over time.

## ✨ Features

- **🤖 Multi-LLM Integration**: Seamlessly integrate ChatGPT, Claude, and Gemini
- **🎭 Custom AI Personalities**: Create and customize AI personalities for different contexts
- **🧠 Intelligent Agents**: AI-powered agents that monitor and optimize your workspace
- **📚 Experience Management**: Organize interactions into topic-based experiences
- **🔒 Security & Privacy**: Enterprise-grade security with GDPR/CCPA compliance
- **📊 Analytics & Insights**: Comprehensive learning and growth analytics
- **🚀 Automated CI/CD**: Deploy multiple times per day with zero downtime

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   Database      │
│   (Next.js)     │◄──►│   (Node.js)     │◄──►│   (PostgreSQL)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Monitoring    │    │   Cache Layer   │    │   File Storage  │
│ (Grafana/Prom)  │    │     (Redis)     │    │      (S3)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Node.js 18+
- Docker & Docker Compose
- Git

### Local Development

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd llm-platform
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment**
   ```bash
   cp env.example .env
   # Edit .env with your API keys
   ```

4. **Start local environment**
   ```bash
   # Start all services (PostgreSQL, Redis, Prometheus, Grafana)
   docker-compose up -d
   
   # Start the application
   npm run dev
   ```

5. **Access your application**
   - Main App: http://localhost:3000
   - Grafana: http://localhost:3001 (admin/admin123)
   - Prometheus: http://localhost:9090

## 🔄 Automated CI/CD Setup

### 1. GitHub Repository Configuration

1. **Push your code to GitHub**
   ```bash
   git add .
   git commit -m "Initial commit with CI/CD setup"
   git push origin main
   ```

2. **Set up GitHub Secrets**
   - Go to repository → Settings → Secrets and variables → Actions
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

### 2. Set Up Deployment Servers

For each environment (dev, staging, prod), run the setup script:

```bash
# On your deployment server
curl -fsSL https://raw.githubusercontent.com/your-username/llm-platform/main/scripts/setup-deployment-server.sh | bash -s development

# Or for staging/production
curl -fsSL https://raw.githubusercontent.com/your-username/llm-platform/main/scripts/setup-deployment-server.sh | bash -s staging
curl -fsSL https://raw.githubusercontent.com/your-username/llm-platform/main/scripts/setup-deployment-server.sh | bash -s production
```

### 3. Deployment Workflows

The CI/CD pipeline automatically deploys based on branch pushes:

- **`develop` branch** → Automatic deployment to development
- **`main` branch** → Automatic deployment to staging
- **Manual trigger** → Deploy to any environment with approval

## 📊 Monitoring & Health Checks

### Health Endpoints

- **Health Check**: `/api/health` - Overall system health
- **Readiness**: `/api/ready` - Service readiness for traffic

### Monitoring Stack

- **Prometheus**: Metrics collection
- **Grafana**: Dashboards and visualization
- **Health Checks**: Automatic health monitoring
- **Logs**: Centralized logging with rotation

## 🧪 Testing

```bash
# Run all tests
npm test

# Run specific test types
npm run test:unit
npm run test:integration

# Run with coverage
npm run test:coverage

# Run tests in watch mode
npm run test:watch
```

## 🏗️ Build & Deploy

```bash
# Build for production
npm run build

# Start production server
npm start

# Docker build
docker build -t llm-platform .

# Docker run
docker run -p 3000:3000 llm-platform
```

## 🔒 Security Features

- **Data Encryption**: At rest and in transit
- **API Security**: Rate limiting and authentication
- **Network Security**: VPC isolation and security groups
- **Secrets Management**: Secure environment variable handling
- **Compliance**: GDPR, CCPA, SOC 2 ready

## 📈 Performance Features

- **Auto-scaling**: Horizontal Pod Autoscaler (Kubernetes)
- **Load Balancing**: Application Load Balancer
- **Caching**: Redis for session and data caching
- **CDN**: Global content delivery
- **Database Optimization**: Connection pooling and indexing

## 🛠️ Development

### Available Scripts

```bash
npm run dev          # Start development server
npm run build        # Build for production
npm run start        # Start production server
npm run lint         # Run ESLint
npm run type-check   # Run TypeScript type checking
npm run test         # Run tests
npm run test:watch   # Run tests in watch mode
```

### Project Structure

```
llm-platform/
├── src/                    # Application source code
│   ├── pages/             # Next.js pages and API routes
│   ├── components/        # React components
│   ├── styles/            # Global styles and Tailwind CSS
│   └── utils/             # Utility functions
├── deploy/                 # Deployment configurations
├── .github/workflows/      # GitHub Actions CI/CD
├── scripts/                # Setup and deployment scripts
├── docker-compose.yml      # Local development
├── docker-compose.prod.yml # Production deployment
├── Dockerfile             # Production container
└── package.json           # Dependencies and scripts
```

## 🔧 Configuration

### Environment Variables

Key environment variables you need to configure:

```bash
# LLM API Keys
OPENAI_API_KEY=your-openai-api-key
ANTHROPIC_API_KEY=your-anthropic-api-key
GOOGLE_API_KEY=your-google-api-key

# Database
DATABASE_URL=postgresql://user:password@host:port/database
REDIS_URL=redis://host:port

# Security
JWT_SECRET=your-jwt-secret
NEXTAUTH_SECRET=your-nextauth-secret

# URLs
NEXTAUTH_URL=http://localhost:3000
NEXT_PUBLIC_API_URL=http://localhost:3000/api
```

## 📚 API Documentation

### Health Endpoints

#### GET `/api/health`
Returns the overall health status of the system.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "uptime": 123.45,
  "environment": "development",
  "version": "1.0.0",
  "checks": {
    "database": "connected",
    "redis": "connected",
    "memory": {
      "used": 69,
      "total": 1024
    }
  }
}
```

#### GET `/api/ready`
Returns the readiness status for traffic routing.

**Response:**
```json
{
  "status": "ready",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "checks": {
    "database": "ready",
    "redis": "ready",
    "external_apis": "ready",
    "file_system": "ready"
  }
}
```

## 🚀 Deployment Options

### 1. Local Development (Docker Compose)
Fastest way to get started for development and testing.

### 2. Cloud Deployment (AWS)
Production-ready with auto-scaling and managed services.

### 3. Automated CI/CD (GitHub Actions)
Continuous deployment with multiple releases per day.

## 📊 Monitoring & Observability

### Metrics Collected

- **Application Metrics**: Response times, error rates, throughput
- **Infrastructure Metrics**: CPU, memory, disk, network
- **Business Metrics**: User engagement, feature usage
- **Custom Metrics**: LLM API calls, response quality

### Alerting

- **Slack**: Deployment notifications and alerts
- **Email**: Critical system alerts
- **PagerDuty**: Incident management (optional)

## 🔄 Continuous Improvement

### Metrics to Track

- **Deployment Frequency**: How often you deploy
- **Lead Time**: Time from commit to production
- **Mean Time to Recovery**: Time to fix issues
- **Change Failure Rate**: Percentage of failed deployments

### Optimization Opportunities

- **Build Time**: Optimize Docker layers and caching
- **Test Time**: Parallel test execution
- **Deployment Time**: Optimize health checks and rollbacks

## 🆘 Troubleshooting

### Common Issues

1. **Health Check Failures**
   ```bash
   # Check application logs
   docker-compose logs app
   
   # Test health endpoint
   curl -f http://localhost:3000/api/health
   ```

2. **Build Failures**
   ```bash
   # Test locally first
   npm run lint
   npm run type-check
   npm run test
   npm run build
   ```

3. **Deployment Issues**
   ```bash
   # Check GitHub Actions logs
   # Go to Actions tab → Failed workflow → View logs
   
   # Check server status
   ssh user@server
   cd /opt/llm-platform-{environment}
   docker-compose ps
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

## 📚 Additional Resources

### Documentation

- [Deployment Guide](DEPLOYMENT.md) - Comprehensive deployment instructions
- [Product Backlog](Personal_LLM_Experience_Platform_Product_Backlog.md) - Product roadmap and features
- [Next.js Documentation](https://nextjs.org/docs)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

### Community

- [GitHub Issues](https://github.com/your-username/llm-platform/issues)
- [Next.js Discord](https://discord.gg/nextjs)
- [Docker Community](https://forums.docker.com/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Next.js team for the amazing framework
- Docker team for containerization
- GitHub team for Actions and CI/CD
- The open-source community for inspiration and tools

---

## 🎯 Next Steps

1. **Set up your GitHub repository** with the code
2. **Configure environment variables** and secrets
3. **Set up deployment servers** for each environment
4. **Test the pipeline** with a small change
5. **Monitor and optimize** based on usage patterns

**Happy Deploying! 🚀**

Your LLM Platform is now set up for automated, frequent deployments with professional-grade infrastructure and monitoring.
