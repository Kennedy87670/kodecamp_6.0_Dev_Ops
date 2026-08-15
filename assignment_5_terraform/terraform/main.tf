terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # The bucket and region are supplied at init time by GitHub Actions:
  # terraform init -backend-config="bucket=..." -backend-config="region=..."
  backend "s3" {
    key          = "assignment-5/terraform.tfstate"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Assignment = "assignment-5"
      ManagedBy  = "Terraform"
      Project    = "dream-vacation"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_vpc" "dream" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dream-vpc"
  }
}

resource "aws_subnet" "dream" {
  vpc_id                  = aws_vpc.dream.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "dream-subnet"
  }
}

resource "aws_internet_gateway" "dream" {
  vpc_id = aws_vpc.dream.id

  tags = {
    Name = "dream-igw"
  }
}

resource "aws_route_table" "dream" {
  vpc_id = aws_vpc.dream.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dream.id
  }

  tags = {
    Name = "dream-rt"
  }
}

resource "aws_route_table_association" "dream" {
  subnet_id      = aws_subnet.dream.id
  route_table_id = aws_route_table.dream.id
}

resource "aws_security_group" "dream_server" {
  name        = "dream-server-sg"
  description = "Allow SSH and HTTP to the Dream Vacation server"
  vpc_id      = aws_vpc.dream.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dream-server-sg"
  }
}

resource "aws_key_pair" "dream_deploy" {
  key_name   = "dream-assignment-5-key"
  public_key = var.ec2_public_key
}

resource "aws_instance" "dream_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.dream.id
  vpc_security_group_ids      = [aws_security_group.dream_server.id]
  key_name                    = aws_key_pair.dream_deploy.key_name
  associate_public_ip_address = true
  monitoring                  = true
  user_data                   = file("${path.module}/user_data.sh")
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
  }

  tags = {
    Name = "dream-vacation-server"
  }
}

resource "aws_sns_topic" "high_cpu" {
  name = "dream-server-high-cpu-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.high_cpu.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "dream-server-high-cpu"
  alarm_description   = "Alarm when Dream Vacation EC2 CPU exceeds 70 percent."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.high_cpu.arn]

  dimensions = {
    InstanceId = aws_instance.dream_server.id
  }
}
