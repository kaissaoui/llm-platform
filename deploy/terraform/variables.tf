variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "development"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "llm_platform_user"
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
  default     = "t3.medium"
}

variable "min_size" {
  description = "Minimum number of nodes in EKS cluster"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of nodes in EKS cluster"
  type        = number
  default     = 3
}

variable "desired_size" {
  description = "Desired number of nodes in EKS cluster"
  type        = number
  default     = 1
}

variable "enable_public_access" {
  description = "Enable public access to EKS cluster"
  type        = bool
  default     = true
}

variable "enable_private_access" {
  description = "Enable private access to EKS cluster"
  type        = bool
  default     = true
}

variable "cluster_version" {
  description = "Kubernetes cluster version"
  type        = string
  default     = "1.28"
}

variable "enable_irsa" {
  description = "Enable IAM roles for service accounts"
  type        = bool
  default     = true
}

variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "enable_metrics_server" {
  description = "Enable metrics server for HPA"
  type        = bool
  default     = true
}

variable "enable_cluster_autoscaler" {
  description = "Enable cluster autoscaler"
  type        = bool
  default     = true
}

variable "enable_efs_csi_driver" {
  description = "Enable EFS CSI driver for persistent storage"
  type        = bool
  default     = false
}

variable "enable_ebs_csi_driver" {
  description = "Enable EBS CSI driver for persistent storage"
  type        = bool
  default     = true
}

variable "enable_aws_node_termination_handler" {
  description = "Enable AWS node termination handler"
  type        = bool
  default     = true
}

variable "enable_aws_cloudwatch_agent" {
  description = "Enable AWS CloudWatch agent for monitoring"
  type        = bool
  default     = true
}

variable "enable_aws_xray_daemonset" {
  description = "Enable AWS X-Ray daemonset for tracing"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "enable_ssm" {
  description = "Enable SSM for node access"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs for EKS"
  type        = bool
  default     = true
}

variable "cloudwatch_logs_retention_in_days" {
  description = "CloudWatch logs retention in days"
  type        = number
  default     = 7
}

variable "enable_control_plane_logs" {
  description = "Enable control plane logs"
  type        = bool
  default     = true
}

variable "control_plane_log_types" {
  description = "Control plane log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "enable_fargate" {
  description = "Enable Fargate profiles"
  type        = bool
  default     = false
}

variable "fargate_profiles" {
  description = "Fargate profile configurations"
  type = map(object({
    name = string
    selectors = list(object({
      namespace = string
      labels = map(string)
    }))
    subnets = list(string)
    tags = map(string)
  }))
  default = {}
}

variable "enable_spot_instances" {
  description = "Enable spot instances for cost optimization"
  type        = bool
  default     = false
}

variable "spot_allocation_strategy" {
  description = "Spot allocation strategy"
  type        = string
  default     = "lowest-price"
  validation {
    condition     = contains(["lowest-price", "diversified", "capacity-optimized"], var.spot_allocation_strategy)
    error_message = "Spot allocation strategy must be one of: lowest-price, diversified, capacity-optimized."
  }
}

variable "enable_gpu_instances" {
  description = "Enable GPU instances for ML workloads"
  type        = bool
  default     = false
}

variable "gpu_instance_types" {
  description = "GPU instance types for ML workloads"
  type        = list(string)
  default     = ["g4dn.xlarge", "g4dn.2xlarge", "g4dn.4xlarge"]
}

variable "enable_arm_instances" {
  description = "Enable ARM instances for cost optimization"
  type        = bool
  default     = false
}

variable "arm_instance_types" {
  description = "ARM instance types"
  type        = list(string)
  default     = ["t4g.medium", "t4g.large", "t4g.xlarge"]
}
