#!/usr/bin/env bash
# Runs ON the EC2 box. Fetches the secret from SSM (never stored in git),
# writes it to monitoring/.env, then (re)builds and starts the whole stack.
set -euo pipefail

APP_NAME="${APP_NAME:-8byte-app}"
AWS_REGION="${AWS_REGION:-us-east-1}"

echo ">> Fetching secret from SSM SecureString..."
SECRET=$(aws ssm get-parameter \
  --name "/${APP_NAME}/app_secret" \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text \
  --region "$AWS_REGION")

cat > monitoring/.env <<ENV
NODE_ENV=production
APP_SECRET=${SECRET}
ENV

echo ">> Starting stack (app + prometheus + grafana + node-exporter)..."
docker compose -f monitoring/docker-compose.yml up -d --build
docker compose -f monitoring/docker-compose.yml ps

echo ">> Done. App on :3000, Grafana on :3001, Prometheus on :9090"
