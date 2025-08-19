# LLM Platform Deployment Guide

This directory contains all the deployment configurations and scripts for the Personal LLM Experience Platform, enabling fast, frequent releases with multiple environments.

## 🚀 Quick Start

### 1. Prerequisites
- [Docker](https://docs.docker.com/get-docker/) (20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (2.0+)
- [AWS CLI](https://aws.amazon.com/cli/) (2.0+)
- [Terraform](https://www.terraform.io/downloads) (1.0+)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (1.28+)
- [Helm](https://helm.sh/docs/intro/install/) (3.0+) - Optional

### 2. Environment Setup
```bash
# Clone the repository
git clone <your-repo-url>
cd llm-platform

# Set up AWS credentials
aws configure

# Initialize infrastructure (choose environment)
./deploy/scripts/setup-infrastructure.sh development
./deploy/scripts/setup-infrastructure.sh staging
./deploy/scripts/setup-infrastructure.sh production
```

### 3. Deploy Application
```bash
# Deploy to specific environment
./deploy/scripts/deploy.sh development
./deploy/scripts/deploy.sh staging
./deploy/scripts/deploy.sh production

# Or use GitHub Actions for automated deployment
git push origin main  # Deploys to staging
git push origin develop  # Deploys to development
```

## 🏗️ Architecture Overview

### Multi-Environment Setup
- **Development**: Single-node EKS cluster, minimal resources
- **Staging**: Multi-node EKS cluster, medium resources
- **Production**: High-availability EKS cluster, production-grade resources

### Infrastructure Components
- **EKS Cluster**: Kubernetes orchestration
- **RDS PostgreSQL**: Managed database
- **ElastiCache Redis**: Caching layer
- **S3**: File storage
- **Application Load Balancer**: Traffic distribution
- **CloudWatch**: Monitoring and logging

### Deployment Options
1. **Docker Compose**: Local development and testing
2. **Kubernetes**: Production deployment with auto-scaling
3. **GitHub Actions**: Automated CI/CD pipeline

## 📁 Directory Structure

```
deploy/
├── docker-compose.yml          # Local development setup
├── kubernetes/                 # Kubernetes manifests
│   └── deployment.yaml        # Production deployment
├── scripts/                    # Deployment scripts
│   ├── deploy.sh              # Main deployment script
│   └── setup-infrastructure.sh # Infrastructure setup
├── terraform/                  # Infrastructure as Code
│   ├── main.tf                # Main Terraform configuration
│   ├── variables.tf           # Variable definitions
│   └── environments/          # Environment-specific configs
│       ├── development.tfvars
│       ├── staging.tfvars
│       └── production.tfvars
└── README.md                  # This file
```

## 🔧 Configuration

### Environment Variables
Create a `.env` file in your project root:

```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/llm_platform
POSTGRES_DB=llm_platform
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password

# Redis
REDIS_URL=redis://localhost:6379

# Security
JWT_SECRET=your-super-secret-jwt-key

# LLM API Keys
OPENAI_API_KEY=your-openai-api-key
ANTHROPIC_API_KEY=your-anthropic-api-key
GOOGLE_API_KEY=your-google-api-key

# Environment
NODE_ENV=development
```

### GitHub Secrets
For GitHub Actions deployment, set these secrets:

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

## 🚀 Deployment Workflows

### Automated Deployment (Recommended)
1. **Push to `develop` branch** → Automatic deployment to development
2. **Push to `main` branch** → Automatic deployment to staging
3. **Manual trigger** → Deploy to any environment via GitHub Actions

### Manual Deployment
```bash
# Deploy to specific environment
./deploy/scripts/deploy.sh [environment] [version]

# Examples
./deploy/scripts/deploy.sh development latest
./deploy/scripts/deploy.sh staging v1.2.3
./deploy/scripts/deploy.sh production v1.2.3
```

### Rollback
```bash
# Automatic rollback on deployment failure
# Manual rollback using backup
cd /opt/llm-platform-[environment]
docker-compose down
cp backups/[timestamp]/docker-compose.yml .
docker-compose up -d
```

## 📊 Monitoring & Observability

### Health Checks
- **Application**: `/health` endpoint
- **Readiness**: `/ready` endpoint
- **Liveness**: Kubernetes probes

### Metrics & Logging
- **Prometheus**: Application metrics
- **Grafana**: Dashboards and visualization
- **CloudWatch**: AWS service metrics
- **Application Logs**: Structured JSON logging

### Alerts
- **Slack**: Deployment notifications
- **Email**: Critical alerts (configure in CloudWatch)
- **PagerDuty**: Incident management (optional)

## 🔒 Security Features

### Data Protection
- **Encryption at Rest**: AES-256 for all data
- **Encryption in Transit**: TLS 1.3 for all communications
- **API Security**: Rate limiting, authentication, authorization

### Access Control
- **IAM Roles**: Least privilege access
- **Network Security**: VPC isolation, security groups
- **Secrets Management**: Kubernetes secrets, encrypted storage

### Compliance
- **GDPR**: Data privacy controls
- **CCPA**: California privacy compliance
- **SOC 2**: Security and availability controls

## 🚀 Performance & Scaling

### Auto-scaling
- **Horizontal Pod Autoscaler**: CPU and memory-based scaling
- **Cluster Autoscaler**: Node-level scaling
- **Load Balancer**: Traffic distribution

### Resource Optimization
- **Spot Instances**: Cost optimization (optional)
- **ARM Instances**: Cost optimization (optional)
- **GPU Instances**: ML workload optimization (optional)

### Caching Strategy
- **Redis**: Session and data caching
- **CDN**: Static asset delivery
- **Application Cache**: In-memory caching

## 🛠️ Troubleshooting

### Common Issues

#### Deployment Failures
```bash
# Check deployment status
kubectl get pods -n [environment]
kubectl describe pod [pod-name] -n [environment]
kubectl logs [pod-name] -n [environment]

# Check service status
kubectl get svc -n [environment]
kubectl describe svc [service-name] -n [environment]
```

#### Infrastructure Issues
```bash
# Check Terraform state
cd deploy/terraform
terraform plan -var-file="environments/[environment].tfvars"

# Check AWS resources
aws eks describe-cluster --name llm-platform-[environment]
aws rds describe-db-instances --db-instance-identifier llm-platform-[environment]
```

#### Database Issues
```bash
# Connect to database
kubectl port-forward svc/postgres 5432:5432 -n [environment]
psql -h localhost -U [username] -d [database]

# Check Redis
kubectl port-forward svc/redis 6379:6379 -n [environment]
redis-cli -h localhost -p 6379
```

### Logs & Debugging
```bash
# Application logs
kubectl logs -f deployment/llm-platform -n [environment]

# System logs
kubectl logs -f -n kube-system

# Infrastructure logs
aws logs describe-log-groups --log-group-name-prefix "/aws/eks"
```

## 📈 Best Practices

### Development Workflow
1. **Feature Branches**: Create feature branches from `develop`
2. **Pull Requests**: Require PR reviews before merging
3. **Testing**: Run tests locally before pushing
4. **Small Commits**: Make frequent, small commits

### Deployment Strategy
1. **Blue-Green**: Zero-downtime deployments
2. **Rolling Updates**: Gradual rollout with health checks
3. **Canary Deployments**: Gradual traffic shifting
4. **Feature Flags**: Control feature rollout

### Monitoring Strategy
1. **Proactive Monitoring**: Alert before issues occur
2. **SLA Monitoring**: Track performance metrics
3. **Cost Monitoring**: Track resource usage and costs
4. **Security Monitoring**: Monitor for security threats

## 🔄 Continuous Improvement

### Metrics to Track
- **Deployment Frequency**: How often you deploy
- **Lead Time**: Time from commit to production
- **Mean Time to Recovery**: Time to fix issues
- **Change Failure Rate**: Percentage of failed deployments

### Optimization Opportunities
- **Build Optimization**: Multi-stage Docker builds
- **Dependency Management**: Regular dependency updates
- **Resource Optimization**: Right-sizing instances
- **Cost Optimization**: Spot instances, ARM processors

## 📚 Additional Resources

### Documentation
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Docker Documentation](https://docs.docker.com/)

### Tools
- [k9s](https://k9scli.io/) - Kubernetes CLI tool
- [Lens](https://k8slens.dev/) - Kubernetes IDE
- [Terraform Cloud](https://www.terraform.io/cloud) - Terraform management
- [AWS Cloud9](https://aws.amazon.com/cloud9/) - Cloud IDE

### Community
- [Kubernetes Slack](https://slack.k8s.io/)
- [Terraform Community](https://discuss.hashicorp.com/)
- [AWS Community](https://aws.amazon.com/community/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests and documentation
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the troubleshooting section above

---

**Happy Deploying! 🚀**
