variable "aws_region" {
  description = "AWS region for Assignment 5 resources."
  type        = string
  default     = "us-east-1"
}

variable "ec2_public_key" {
  description = "Public SSH key used to create the EC2 key pair. Set with TF_VAR_ec2_public_key."
  type        = string
  sensitive   = true
}

variable "alarm_email" {
  description = "Email address that receives the CloudWatch CPU alarm notification. Set with TF_VAR_alarm_email."
  type        = string
}
