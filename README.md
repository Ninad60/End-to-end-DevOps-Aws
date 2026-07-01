# 8Byte DevOps Assignment — Simple Build

A todo API deployed to AWS with Terraform, a GitHub Actions CI/CD pipeline,
and both Prometheus/Grafana and CloudWatch monitoring — kept deliberately
lean: **one EC2 instance runs the whole stack via Docker Compose.**

## Architecture

```
 Developer ──push──► GitHub ──► GitHub Actions
                                   │  test  (every push / PR)
                                   │  deploy (main only, manual approval gate)
                                   ▼  SSH
                         ┌───────────────────────────────┐
                         │        EC2 t2.micro           │
                         │  docker compose up:           │
                         │   • app       :3000           │
                         │   • prometheus:9090           │
                         │   • grafana   :3001           │
                         │   • node-exporter             │
                         └───────────────────────────────┘
                                   │
                    CloudWatch dashboard + CPU alarm
                    Secret pulled from SSM (SecureString)
```

## Covers all four parts

1. **Infrastructure (Terraform):** EC2 + security group + IAM + SSM + CloudWatch, local state.
2. **CI/CD (GitHub Actions):** `test` on every push/PR, `deploy` over SSH on `main` behind a manual production approval gate.
3. **Monitoring:** Prometheus + Grafana (auto-provisioned dashboards) on the box; CloudWatch dashboard + CPU alarm in AWS.
4. **Docs + Secrets + Backup:** this README, SSM SecureString secret handling, and a backup strategy in `docs/challenges.md`.

---

## Runbook

### 0. One-time AWS setup
Create an AWS free account, an IAM user with `AdministratorAccess`, an access
key, then:
```bash
aws configure          # keys, region us-east-1, output json
aws sts get-caller-identity
```

### 1. Make an SSH key
```bash
ssh-keygen -t ed25519 -f ~/.ssh/8byte -N ""
```

### 2. Provision (≈3–4 min)
```bash
cd terraform
terraform init
terraform apply -var="app_secret=demo-secret-123" -auto-approve
terraform output
```

### 3. First deploy (once)
Push this project to a **public** GitHub repo first, then:
```bash
eval "$(terraform output -raw ssh_command)"          # SSH in
git clone https://github.com/USER/REPO.git ~/app && cd ~/app && bash deploy.sh
exit
```
Open the URLs from `terraform output` — app on `:3000`, Grafana `:3001` (admin/admin), Prometheus `:9090`.

### 4. Wire up the pipeline
In the GitHub repo:
- **Settings → Secrets and variables → Actions** → add
  `EC2_HOST` (the public IP) and `SSH_PRIVATE_KEY` (contents of `~/.ssh/8byte`).
- **Settings → Environments** → create `production` → enable **Required
  reviewers** and add yourself (this is the manual approval gate).

Then every push to `main` runs tests and, after you approve, redeploys:
```bash
git commit --allow-empty -m "trigger pipeline" && git push
```

### 5. Teardown
```bash
cd terraform
terraform destroy -var="app_secret=demo-secret-123" -auto-approve
```

## App endpoints
`/health` · `/` · `/todos` (GET/POST) · `/todos/:id` (PUT/DELETE) · `/metrics`
