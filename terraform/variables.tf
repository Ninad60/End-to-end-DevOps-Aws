variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Name used to prefix all resources"
  type        = string
  default     = "8byte-app"
}

variable "instance_type" {
  description = "EC2 size. t2.micro is free-tier eligible on newer accounts (1 vCPU / 1 GB)."
  type        = string
  default     = "t3.micro"
}

variable "public_key_path" {
  description = "Path to your SSH public key (created with ssh-keygen)."
  type        = string
  default     = "~/.ssh/8byte.pub"
}

variable "allowed_cidr" {
  description = "CIDR allowed to reach SSH/Grafana/Prometheus. Set to YOUR_IP/32 for safety; 0.0.0.0/0 opens to the world."
  type        = string
  default     = "0.0.0.0/0"
}

variable "app_secret" {
  description = "Demo application secret. Stored ENCRYPTED in SSM SecureString, never in the repo. Pass via -var."
  type        = string
  sensitive   = true
}
