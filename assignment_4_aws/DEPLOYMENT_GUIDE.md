# AWS EC2 Deployment Guide - Dream Vacation App

This guide walks you through completing the AWS deployment assignment.

---

## Step 1: Get Your EC2 Public IP Address

1. Go to **AWS Console** → **EC2** → **Instances**
2. Click on your instance **dream-vacation-server**
3. In the instance details, find **Public IPv4 address** ( `100.48.206.179`)
4. **Copy this address** - you'll need it for GitHub secrets

⚠️ **Important:** Use the **Public IPv4 address**, NOT the private IP (10.0.1.171)

---

## Step 2: Add GitHub Repository Secrets

These secrets enable GitHub Actions to deploy to your EC2 instance.

### 2.1 Go to GitHub Repository Settings

1. Open your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

### 2.2 Add These Secrets (One at a Time)

#### Secret 1: `EC2_HOST`

- **Name:** `EC2_HOST`
- **Value:** Your EC2 Public IPv4 address (e.g., `54.91.120.15`)
- Click **Add secret**

#### Secret 2: `EC2_USER`

- **Name:** `EC2_USER`
- **Value:** `ubuntu`
- Click **Add secret**

#### Secret 3: `EC2_SSH_KEY`

- **Name:** `EC2_SSH_KEY`
- **Value:** Copy the entire contents of your `dream-key.pem` file
  - Open the `.pem` file in a text editor
  - Copy everything from `-----BEGIN PRIVATE KEY-----` to `-----END PRIVATE KEY-----` (or `RSA PRIVATE KEY` if applicable)
  - Paste it into the secret
- Click **Add secret**

#### Secret 4: `DOCKER_USERNAME`

- **Name:** `DOCKER_USERNAME`
- **Value:** Your Docker Hub username (e.g., `kennedycode`)
- Click **Add secret**

#### Secret 5: `DOCKER_TOKEN`

- **Name:** `DOCKER_TOKEN`
- **Value:** Your Docker Hub personal access token (PAT)
  - If you don't have this, create it at https://hub.docker.com/settings/security
  - Click **New Access Token**
  - Give it a name like "GitHub Actions"
  - Copy the token and paste it here
- Click **Add secret**

✅ **All 5 secrets should now be in your repository.**

---

## Step 3: Configure EC2 Security Group

Your EC2 instance needs to allow incoming traffic on ports 22 (SSH), 80 (HTTP), and 3001 (API).

### 3.1 Open Security Group Settings

1. In **AWS Console** → **EC2** → **Instances**
2. Click on **dream-vacation-server**
3. Scroll to **Security** section
4. Click on the **Security group** link (e.g., `sg-xxx`)

### 3.2 Edit Inbound Rules

1. Click **Edit inbound rules**
2. Make sure you have these rules:

| Type       | Protocol | Port Range | Source    |
| ---------- | -------- | ---------- | --------- |
| SSH        | TCP      | 22         | 0.0.0.0/0 |
| HTTP       | TCP      | 80         | 0.0.0.0/0 |
| Custom TCP | TCP      | 3001       | 0.0.0.0/0 |

> ⚠️ **Note:** Using `0.0.0.0/0` (anywhere) is fine for this assignment with SSH key authentication. After grading, you can restrict to your IP.

3. Click **Save rules**

---

## Step 4: Trigger the Deployment

### 4.1 Push Changes to GitHub

The `deploy.yml` workflow runs automatically when you push to the `main` branch.

Verify your changes are committed:

```bash
git status
git log -1 --oneline
```

### 4.2 Check GitHub Actions

1. Go to your GitHub repository
2. Click **Actions**
3. You should see two workflows running:
   - **Backend CI/CD** - builds and pushes backend image
   - **Frontend CI/CD** - builds and pushes frontend image
   - **Deploy to EC2** - waits for images, then deploys

4. **Wait for all three to complete** (usually 5-10 minutes total)

### 4.3 View Deployment Logs

1. Click on the **Deploy to EC2** workflow run
2. Click on **deploy** job
3. View the logs to verify:
   - ✓ Docker images pulled
   - ✓ Files copied to EC2
   - ✓ Containers started
   - ✓ Services listening on ports 80 and 3001

---

## Step 5: Verify Deployment on EC2

SSH into your EC2 instance and check the deployment:

```bash
# SSH to your instance (replace with your public IP)
ssh -i your-key.pem ubuntu@54.91.120.15

# Once connected to EC2:
cd ~/dream-vacation

# Check container status
docker compose ps

# View recent logs
docker compose logs --tail=100

# Check listening ports
sudo ss -lntp | grep -E ':(80|3001)'

# Test locally
curl http://localhost
```

---

## Step 6: Access Your Application

### From Your Computer

Open your browser and visit:

```
http://YOUR-EC2-PUBLIC-IP
```

Example: `http://54.91.120.15`

### Test Backend API

```
http://YOUR-EC2-PUBLIC-IP:3001
```

✅ **If you see your Dream Vacation App, the deployment is successful!**

---

## Troubleshooting

### Problem: GitHub Actions deployment fails

**Check the workflow logs:**

1. Go to GitHub → **Actions** → **Deploy to EC2**
2. Click the failed run
3. Click the **deploy** job
4. Look for error messages

**Common issues:**

| Error                           | Solution                                                        |
| ------------------------------- | --------------------------------------------------------------- |
| `Permission denied (publickey)` | Verify `EC2_SSH_KEY` secret contains the full .pem file content |
| `Connection refused`            | EC2 instance is not running or security group blocks SSH        |
| `docker: not found`             | SSH key login issue - check EC2 can be reached                  |
| `Invalid image name`            | Verify `DOCKER_USERNAME` secret is correct                      |

### Problem: Application won't start on EC2

```bash
# SSH to EC2 and check logs
ssh -i dream-key.pem ubuntu@YOUR-PUBLIC-IP

cd ~/dream-vacation

# View docker-compose errors
docker compose logs

# Check if images were pulled
docker images | grep kh-2026

# Try manual pull
export DOCKER_USERNAME=your-username
docker compose pull

# Try starting again
docker compose up -d
```

### Problem: Can't access app in browser

1. **Check security group** allows HTTP (port 80)
2. **Check containers are running:** `docker compose ps`
3. **Check ports are listening:** `sudo ss -lntp | grep -E ':(80|3001)'`
4. **Wait a few seconds** - containers may still be starting

---

## Screenshots for Submission

Collect these screenshots for your assignment submission:

1. **AWS Console - VPC & Subnet**
   - Screenshot of your VPC (dream-vpc) and subnet (dream-subnet)

2. **AWS Console - EC2 Instance**
   - Show the running instance with Public IP visible

3. **Application Running**
   - Screenshot of `http://YOUR-EC2-PUBLIC-IP` in browser showing the app

4. **GitHub Actions - Deployment Success**
   - Screenshot of the **Deploy to EC2** workflow with ✓ passing

5. **EC2 Command Line - Verification**
   - Screenshot of `docker compose ps` showing containers running
   - Screenshot of `sudo ss -lntp` showing ports 80 and 3001 listening

---

## Summary

| Step                                 | Status           |
| ------------------------------------ | ---------------- |
| ✓ EC2 instance with Docker installed | Done             |
| ✓ Docker-compose.yml created         | Done             |
| ✓ GitHub Actions deploy.yml created  | Pushed           |
| → Add GitHub secrets                 | **You are here** |
| → Check EC2 security group           | **Next**         |
| → Trigger deployment                 | **Then**         |
| → Verify application running         | **Finally**      |

Once you complete the GitHub secrets setup, the workflow will automatically deploy your app!
