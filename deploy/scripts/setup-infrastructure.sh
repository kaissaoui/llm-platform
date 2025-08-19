#!/bin/bash

# Infrastructure Setup Script for LLM Platform
# This script sets up the complete infrastructure using Terraform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
ENVIRONMENT=${1:-development}

# Logging functions
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

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed. Please install it first."
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        error "Terraform is not installed. Please install it first."
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        error "kubectl is not installed. Please install it first."
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install it first."
    fi
    
    log "Prerequisites check passed"
}

# Check AWS credentials
check_aws_credentials() {
    log "Checking AWS credentials..."
    
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS credentials not configured. Please run 'aws configure' first."
    fi
    
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    AWS_REGION=$(aws configure get region)
    
    log "Using AWS Account: $AWS_ACCOUNT_ID"
    log "Using AWS Region: $AWS_REGION"
}

# Create S3 bucket for Terraform state
create_terraform_state_bucket() {
    log "Creating S3 bucket for Terraform state..."
    
    BUCKET_NAME="llm-platform-terraform-state-${AWS_ACCOUNT_ID}"
    
    if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        aws s3api create-bucket \
            --bucket "$BUCKET_ID" \
            --region "$AWS_REGION" \
            --create-bucket-configuration LocationConstraint="$AWS_REGION"
        
        # Enable versioning
        aws s3api put-bucket-versioning \
            --bucket "$BUCKET_NAME" \
            --versioning-configuration Status=Enabled
        
        # Enable encryption
        aws s3api put-bucket-encryption \
            --bucket "$BUCKET_NAME" \
            --server-side-encryption-configuration '{
                "Rules": [
                    {
                        "ApplyServerSideEncryptionByDefault": {
                            "SSEAlgorithm": "AES256"
                        }
                    }
                ]
            }'
        
        # Block public access
        aws s3api put-public-access-block \
            --bucket "$BUCKET_NAME" \
            --public-access-block-configuration \
            BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
        
        log "S3 bucket created: $BUCKET_NAME"
    else
        log "S3 bucket already exists: $BUCKET_NAME"
    fi
}

# Create DynamoDB table for state locking
create_dynamodb_table() {
    log "Creating DynamoDB table for Terraform state locking..."
    
    TABLE_NAME="llm-platform-terraform-locks"
    
    if ! aws dynamodb describe-table --table-name "$TABLE_NAME" &> /dev/null; then
        aws dynamodb create-table \
            --table-name "$TABLE_NAME" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
        
        log "Waiting for DynamoDB table to be active..."
        aws dynamodb wait table-exists --table-name "$TABLE_NAME"
        log "DynamoDB table created: $TABLE_NAME"
    else
        log "DynamoDB table already exists: $TABLE_NAME"
    fi
}

# Initialize Terraform
initialize_terraform() {
    log "Initializing Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    terraform init \
        -backend-config="bucket=llm-platform-terraform-state-${AWS_ACCOUNT_ID}" \
        -backend-config="key=terraform.tfstate" \
        -backend-config="region=${AWS_REGION}" \
        -backend-config="dynamodb_table=llm-platform-terraform-locks"
    
    log "Terraform initialized successfully"
}

# Plan Terraform changes
plan_terraform() {
    log "Planning Terraform changes for environment: $ENVIRONMENT"
    
    cd "$TERRAFORM_DIR"
    
    # Validate configuration
    terraform validate
    
    # Plan changes
    terraform plan \
        -var-file="environments/${ENVIRONMENT}.tfvars" \
        -out="${ENVIRONMENT}.tfplan"
    
    log "Terraform plan completed. Review the plan above."
    
    # Ask for confirmation
    read -p "Do you want to apply these changes? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Terraform plan cancelled"
        exit 0
    fi
}

# Apply Terraform changes
apply_terraform() {
    log "Applying Terraform changes for environment: $ENVIRONMENT"
    
    cd "$TERRAFORM_DIR"
    
    # Apply the plan
    terraform apply "${ENVIRONMENT}.tfplan"
    
    log "Terraform apply completed successfully"
}

# Configure kubectl for EKS
configure_kubectl() {
    log "Configuring kubectl for EKS cluster..."
    
    cd "$TERRAFORM_DIR"
    
    # Get EKS cluster info
    CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "llm-platform-${ENVIRONMENT}")
    
    # Update kubeconfig
    aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
    
    # Verify connection
    if kubectl cluster-info &> /dev/null; then
        log "Successfully connected to EKS cluster: $CLUSTER_NAME"
    else
        error "Failed to connect to EKS cluster"
    fi
}

# Install Kubernetes add-ons
install_kubernetes_addons() {
    log "Installing Kubernetes add-ons..."
    
    # Install metrics server
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    # Install AWS Load Balancer Controller
    kubectl apply -k "https://github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
    
    # Install Cluster Autoscaler
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
    
    log "Kubernetes add-ons installed"
}

# Setup monitoring
setup_monitoring() {
    log "Setting up monitoring stack..."
    
    # Create monitoring namespace
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    # Install Prometheus using Helm
    if command -v helm &> /dev/null; then
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
        helm repo update
        
        helm install prometheus prometheus-community/kube-prometheus-stack \
            --namespace monitoring \
            --create-namespace \
            --set grafana.enabled=true \
            --set grafana.adminPassword=admin123 \
            --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false
    else
        warn "Helm not installed. Skipping Prometheus installation."
    fi
    
    log "Monitoring stack setup completed"
}

# Create environment-specific resources
create_environment_resources() {
    log "Creating environment-specific resources..."
    
    cd "$TERRAFORM_DIR"
    
    # Create namespace
    kubectl create namespace "$ENVIRONMENT" --dry-run=client -o yaml | kubectl apply -f -
    
    # Create secrets (you should replace these with actual values)
    kubectl create secret generic llm-platform-secrets \
        --namespace "$ENVIRONMENT" \
        --from-literal=database-url="postgresql://user:password@localhost:5432/llm_platform" \
        --from-literal=redis-url="redis://localhost:6379" \
        --from-literal=jwt-secret="your-jwt-secret-here" \
        --from-literal=openai-api-key="your-openai-key-here" \
        --from-literal=anthropic-api-key="your-anthropic-key-here" \
        --from-literal=google-api-key="your-google-key-here" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    log "Environment resources created"
}

# Display next steps
display_next_steps() {
    log "Infrastructure setup completed successfully!"
    echo
    echo "Next steps:"
    echo "1. Update the secrets in Kubernetes with your actual API keys:"
    echo "   kubectl edit secret llm-platform-secrets -n $ENVIRONMENT"
    echo
    echo "2. Deploy your application:"
    echo "   ./deploy/scripts/deploy.sh $ENVIRONMENT"
    echo
    echo "3. Access your application:"
    echo "   kubectl get svc -n $ENVIRONMENT"
    echo
    echo "4. Monitor your cluster:"
    echo "   kubectl get nodes"
    echo "   kubectl get pods -n $ENVIRONMENT"
    echo
    echo "5. Access monitoring:"
    echo "   kubectl port-forward -n monitoring svc/prometheus-grafana 3001:80"
    echo "   Username: admin, Password: admin123"
}

# Main function
main() {
    log "Starting infrastructure setup for LLM Platform"
    log "Environment: $ENVIRONMENT"
    
    # Validate environment
    if [[ ! "$ENVIRONMENT" =~ ^(development|staging|production)$ ]]; then
        error "Invalid environment: $ENVIRONMENT. Use: development, staging, or production"
    fi
    
    check_prerequisites
    check_aws_credentials
    create_terraform_state_bucket
    create_dynamodb_table
    initialize_terraform
    plan_terraform
    apply_terraform
    configure_kubectl
    install_kubernetes_addons
    setup_monitoring
    create_environment_resources
    display_next_steps
    
    log "Infrastructure setup completed!"
}

# Run main function
main "$@"
