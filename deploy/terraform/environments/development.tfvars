# Development Environment Configuration
environment = "development"
aws_region = "us-west-2"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-west-2a", "us-west-2b"]
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]

# EKS Configuration
instance_type = "t3.small"
min_size = 1
max_size = 3
desired_size = 1
cluster_version = "1.28"

# Features
enable_public_access = true
enable_private_access = true
enable_irsa = true
enable_aws_load_balancer_controller = true
enable_metrics_server = true
enable_cluster_autoscaler = true
enable_ebs_csi_driver = true
enable_aws_node_termination_handler = true
enable_aws_cloudwatch_agent = true
enable_cloudwatch_logs = true
enable_control_plane_logs = true
enable_ssm = true

# Cost Optimization
enable_spot_instances = false
enable_arm_instances = false
enable_gpu_instances = false

# Monitoring
cloudwatch_logs_retention_in_days = 7

# Tags
tags = {
  Environment = "development"
  Project     = "llm-platform"
  Owner       = "dev-team"
  CostCenter  = "dev-ops"
}
