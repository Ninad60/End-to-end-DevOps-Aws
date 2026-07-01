#!/usr/bin/env bash
# Runs ON the EC2 box. Fetches the secret from SSM (never stored in git),
# writes it to monitoring/.env, then builds + starts the whole stack.
set -euo pipefail

APP_NAME="${APP_NAME:-8byte-app}"
AWS_REGION="${AWS_REGION:-us-east-1}"
COMPOSE="docker compose -f monitoring/docker-compose.yml"

echo ">> Fetching secret from SSM SecureString..."
SECRET=$(aws ssm get-parameter \
  --name "/${APP_NAME}/app_secret" \
  --with-decryption --query 'Parameter.Value' --output text \
  --region "$AWS_REGION")

cat > monitoring/.env <<ENV
NODE_ENV=production
APP_SECRET=${SECRET}
ENV

echo ">> Building app image (classic builder — no buildx dependency)..."
DOCKER_BUILDKIT=0 $COMPOSE build app

echo ">> Starting stack (app + prometheus + grafana + node-exporter)..."
$COMPOSE up -d
$COMPOSE ps
echo ">> Done. App :3000  Grafana :3001  Prometheus :9090"
