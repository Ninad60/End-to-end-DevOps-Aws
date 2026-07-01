output "public_ip" {
  description = "Public IP of the instance"
  value       = aws_instance.app.public_ip
}

output "app_url" {
  description = "Open this in your browser (the demo app)"
  value       = "http://${aws_instance.app.public_ip}:3000"
}

output "grafana_url" {
  description = "Grafana (admin / admin)"
  value       = "http://${aws_instance.app.public_ip}:3001"
}

output "prometheus_url" {
  description = "Prometheus"
  value       = "http://${aws_instance.app.public_ip}:9090"
}

output "ssh_command" {
  description = "SSH into the box"
  value       = "ssh -i ~/.ssh/8byte ec2-user@${aws_instance.app.public_ip}"
}

output "cloudwatch_dashboard" {
  description = "CloudWatch dashboard link"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}
