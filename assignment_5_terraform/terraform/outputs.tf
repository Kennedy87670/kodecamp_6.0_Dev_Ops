output "ec2_public_ip" {
  description = "Public IPv4 address used by the deployment workflow."
  value       = aws_instance.dream_server.public_ip
}

output "application_url" {
  description = "Public URL for the Dream Vacation App."
  value       = "http://${aws_instance.dream_server.public_ip}"
}

output "instance_id" {
  description = "ID of the Dream Vacation EC2 instance."
  value       = aws_instance.dream_server.id
}

output "cloudwatch_alarm_name" {
  description = "Name of the EC2 CPU CloudWatch alarm."
  value       = aws_cloudwatch_metric_alarm.high_cpu.alarm_name
}
