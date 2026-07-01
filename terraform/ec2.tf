# ─────────────────────────────────────────────────────────────
# Look up the latest Amazon Linux 2023 AMI (no hardcoded AMI IDs)
# ─────────────────────────────────────────────────────────────
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ─────────────────────────────────────────────────────────────
# SSH key pair (imports the public key you generate locally)
# ─────────────────────────────────────────────────────────────
resource "aws_key_pair" "app" {
  key_name   = "${var.app_name}-key"
  public_key = file(var.public_key_path)
}

# ─────────────────────────────────────────────────────────────
# Security group — least privilege
#   3000 (app)  open to the world so reviewers can reach the demo
#   22 / 3001 / 9090  restricted to allowed_cidr (your IP)
# ─────────────────────────────────────────────────────────────
resource "aws_security_group" "app" {
  name        = "${var.app_name}-sg"
  description = "8byte demo app + monitoring"

  ingress {
    description = "App (public)"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }
  ingress {
    description = "Grafana"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }
  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.app_name}-sg" }
}

# ─────────────────────────────────────────────────────────────
# Secret management — SSM Parameter Store (SecureString, encrypted)
# The value is fetched at deploy time; it is never committed to git.
# ─────────────────────────────────────────────────────────────
resource "aws_ssm_parameter" "app_secret" {
  name  = "/${var.app_name}/app_secret"
  type  = "SecureString"
  value = var.app_secret
  tags  = { Name = "${var.app_name}-secret" }
}

# ─────────────────────────────────────────────────────────────
# IAM: let the instance read ONLY its own secret from SSM
# ─────────────────────────────────────────────────────────────
resource "aws_iam_role" "app" {
  name = "${var.app_name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "ssm_read" {
  name = "${var.app_name}-ssm-read"
  role = aws_iam_role.app.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter"]
      Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/${var.app_name}/*"
    }]
  })
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.app_name}-profile"
  role = aws_iam_role.app.name
}

# ─────────────────────────────────────────────────────────────
# The instance. user-data installs Docker + Compose + git + AWS CLI
# and adds a 2 GB swapfile so the monitoring stack fits on 1 GB RAM.
# ─────────────────────────────────────────────────────────────
resource "aws_instance" "app" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.app.key_name
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.app.name

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    # swap so the 1 GB t2.micro can run app + prometheus + grafana
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab

    dnf update -y
    dnf install -y git unzip

    # Docker + compose plugin (official convenience script, distro-agnostic)
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
    usermod -aG docker ec2-user

    # AWS CLI v2 (needed by deploy.sh to read the SSM secret)
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
    unzip -q /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install
  EOF

  tags = { Name = var.app_name }
}
