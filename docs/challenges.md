# Challenges & Design Decisions

## Simplifications (and their production equivalents)

This is a deliberately lean build. Every shortcut below was a conscious
cost/complexity trade-off, and I can articulate the production version of each.

| Area | This build | Production equivalent |
|------|-----------|----------------------|
| Compute | 1× EC2 t2.micro running Docker Compose | ECS Fargate or EKS behind an ALB, auto-scaled |
| State | Local Terraform state | S3 backend + DynamoDB state locking |
| Database | None (app is in-memory) | RDS PostgreSQL, Multi-AZ, automated backups |
| Registry | Build on the instance | Amazon ECR with immutable, SHA-tagged images |
| TLS | Plain HTTP on :3000 | ALB + ACM cert (HTTPS), WAF in front |
| Secrets | SSM Parameter Store (SecureString) | Secrets Manager with automatic rotation |

## Challenges faced

1. **Fitting the monitoring stack on 1 GB RAM.** Prometheus + Grafana +
   node-exporter + the app is tight on a t2.micro. Fixed by adding a 2 GB
   swapfile in user-data and keeping Prometheus retention at 7 days.

2. **Distro-agnostic Docker install.** Package names for the compose plugin
   differ across AMIs, so user-data uses the official `get.docker.com` script,
   which installs the engine + compose plugin consistently.

3. **Keeping secrets out of the repo.** The secret lives only in SSM as a
   SecureString. `deploy.sh` fetches it at deploy time into a gitignored
   `.env`; it is never committed and never printed in logs.

4. **Chicken-and-egg on first deploy.** The instance needs the repo, and the
   repo's deploy job needs the instance. Resolved by making the first deploy a
   single manual SSH step, after which the pipeline handles every deploy.

## Backup strategy

- **Application:** Stateless. Recreate instantly from the AMI + `deploy.sh`.
- **Instance disk:** Take EBS snapshots (`aws ec2 create-image`) or automate
  with a Data Lifecycle Manager policy for daily snapshots + retention.
- **State:** Terraform state is the source of truth for infrastructure; in
  production it would live in versioned S3 so it is itself recoverable.
- **If a database were added:** RDS automated backups (7-day retention) plus
  manual snapshots before schema migrations.
