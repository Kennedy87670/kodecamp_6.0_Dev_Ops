# Assignment 5: Terraform AWS Deployment, CI/CD, and CloudWatch

## Overview

This assignment provisions a Dream Vacation App environment in `us-east-1` with Terraform and deploys the existing Docker images to EC2 through GitHub Actions. Assignment 4 remains unchanged; this folder contains the complete Assignment 5 configuration.

## Architecture

```text
Internet
  │
  ├── dream-igw → dream-rt (0.0.0.0/0)
  │
  └── dream-vpc (10.0.0.0/16)
       └── dream-subnet (10.0.1.0/24)
            └── EC2: dream-vacation-server (Ubuntu 24.04, t3.micro)
                 └── Nginx :80 → frontend :80 and /api → backend :3001 → PostgreSQL :5432
```

## Terraform resources

The Terraform files in [`terraform/`](./terraform/) create:

- `dream-vpc`, `dream-subnet`, `dream-igw`, `dream-rt`, the default internet route, and the subnet association.
- A public Ubuntu 24.04 LTS `t3.micro` EC2 instance with Docker and Docker Compose installed by user data.
- A security group that permits only SSH (22) and HTTP (80).
- A CloudWatch `CPUUtilization` alarm above 70% for two one-minute periods and an SNS email notification.

The Ubuntu AMI is dynamic rather than hard-coded:

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}
```

Terraform outputs the instance public IP, application URL, instance ID, and CloudWatch alarm name. GitHub Actions uses the IP output directly, so there is no `EC2_HOST` secret to maintain.

## State backend setup

Before the first deployment, create a globally unique S3 bucket in `us-east-1` for Terraform state. Enable **Bucket Versioning**. Save its name as the `TF_STATE_BUCKET` GitHub secret.

The backend keeps state at `assignment-5/terraform.tfstate` and uses S3 native state locking (`use_lockfile = true`). The AWS IAM identity requires `s3:ListBucket`, `s3:GetObject`, and `s3:PutObject` on the state object; it also needs `s3:GetObject`, `s3:PutObject`, and `s3:DeleteObject` on the corresponding `.tflock` object.

## GitHub secrets

Configure these repository Actions secrets before running the workflow:

| Secret                                                     | Purpose                                                      |
| ---------------------------------------------------------- | ------------------------------------------------------------ |
| `DOCKER_USERNAME`, `DOCKER_TOKEN`                          | Docker Hub image publishing and EC2 image pulls              |
| `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION` | Dedicated IAM credentials and `us-east-1` region             |
| `TF_STATE_BUCKET`                                          | Pre-created, versioned S3 Terraform-state bucket             |
| `TF_VAR_ec2_public_key`                                    | Public half of a new Assignment 5 SSH key pair               |
| `EC2_SSH_KEY`                                              | Private half of the same SSH key pair                        |
| `POSTGRES_PASSWORD`                                        | URL-safe PostgreSQL password (letters, numbers, `_`, or `-`) |
| `TF_VAR_alarm_email`                                       | Email address receiving CloudWatch notifications             |

Generate the dedicated SSH key pair locally:

```bash
ssh-keygen -t ed25519 -f dream-assignment-5 -C "dream-assignment-5"
```

Store `dream-assignment-5.pub` in `TF_VAR_ec2_public_key` and the full private-key content in `EC2_SSH_KEY`. Do not commit either file. After Terraform creates the SNS subscription, open the AWS confirmation email and select **Confirm subscription**.

## CI/CD deployment

The [terraform-deploy workflow](../.github/workflows/terraform-deploy.yml) performs the following on a push to `main`:

1. Tests and pushes backend and frontend images tagged `latest` and with the commit SHA.
2. Runs `terraform fmt -check`, `init`, `validate`, `plan`, and `apply`.
3. Reads `ec2_public_ip` from Terraform output and waits for SSH.
4. Copies this folder's Compose, Nginx, and database initialization files to EC2.
5. Deploys the exact commit-SHA images with `docker compose up -d`.
6. Verifies the public HTTP endpoint.

The frontend is built with `REACT_APP_API_URL=.`. Browser requests therefore use `./api/...`, which Nginx forwards to the private backend container. PostgreSQL and backend ports are not exposed publicly.

## Local Terraform checks

With AWS credentials configured locally and the two Terraform variables exported:

```bash
cd assignment_5_terraform/terraform
terraform init -backend-config="bucket=YOUR_BUCKET" -backend-config="region=us-east-1"
terraform fmt -check -recursive
terraform validate
terraform plan
```

To remove Assignment 5 resources after grading:

```bash
terraform destroy
```

## Evidence to submit

Add the following screenshots to [`images/`](./images/) after deployment:

| Evidence                                     | Suggested filename   |
| -------------------------------------------- | -------------------- |
| Terraform-created VPC and subnet             | `vpc-subnet.png`     |
| Running `t3.micro` EC2 instance              | `ec2-instance.png`   |
| Working browser application                  | `application.png`    |
| CloudWatch CPU graph and high-CPU alarm      | `cloudwatch.png`     |
| Successful Terraform and deployment workflow | `github-actions.png` |

Before taking the app screenshot, add, list, and delete a destination in the browser to verify the frontend, API proxy, backend, and database work together.
