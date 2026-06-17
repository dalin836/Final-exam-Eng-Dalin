# Quick Start: GitHub Actions Deployment

## Current Status
❌ **Deployment Failed** - GitHub Secrets not configured

## What You Need to Do

### Step 1: Get a Remote Server
You need a VPS/cloud server (e.g., AWS EC2, DigitalOcean, Vultr, Linode)
- Minimum specs: 1 CPU, 1GB RAM, 20GB storage
- OS: Ubuntu 22.04 or 24.04 LTS
- Note down the server IP address

### Step 2: Configure Server
SSH into your server and run:
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install -y docker-compose

# Install Java 21
sudo apt install -y openjdk-21-jdk

# Install Ansible
sudo apt install -y ansible sshpass
```

### Step 3: Generate SSH Key
On your LOCAL machine (not the server):
```bash
# Generate SSH key
ssh-keygen -t rsa -b 4096 -C "github-actions-deploy" -f ~/.ssh/github_actions_deploy

# Copy public key to server
ssh-copy-id -i ~/.ssh/github_actions_deploy.pub -p 22 root@YOUR_SERVER_IP

# Test connection
ssh -i ~/.ssh/github_actions_deploy -p 22 root@YOUR_SERVER_IP
```

### Step 4: Add GitHub Secrets
Go to: https://github.com/dalin836/Final-exam-Eng-Dalin/settings/secrets/actions

Click "New repository secret" and add these:

| Secret Name | Value | Example |
|-------------|-------|---------|
| `DEPLOY_HOST` | Your server IP | `123.456.789.012` |
| `DEPLOY_PORT` | SSH port | `22` |
| `DEPLOY_USER` | SSH username | `root` |
| `DEPLOY_SSH_KEY` | Content of private key | (see below) |
| `EMAIL_USERNAME` | Your Gmail | `you@gmail.com` |
| `EMAIL_PASSWORD` | Gmail app password | `xxxx-xxxx-xxxx` |
| `ADMIN_EMAIL` | Your email | `you@gmail.com` |

**To get DEPLOY_SSH_KEY value:**
```bash
cat ~/.ssh/github_actions_deploy
# Copy the ENTIRE output (including -----BEGIN and -----END lines)
```

**To get Gmail app password:**
1. Go to https://myaccount.google.com/security
2. Enable 2-Step Verification
3. Go to App passwords
4. Generate password for "Mail"
5. Use that 16-character password

### Step 5: Trigger Deployment
```bash
# On your local machine
git push origin main
```

### Step 6: Monitor
- GitHub Actions: https://github.com/dalin836/Final-exam-Eng-Dalin/actions
- You'll receive email notifications

## Alternative: Use Automated Setup Script
```bash
./setup_github_secrets.sh
```

This will guide you through the process interactively.

## Troubleshooting

### "Test SSH connection" fails
- Verify DEPLOY_HOST, DEPLOY_PORT, DEPLOY_USER are correct
- Verify DEPLOY_SSH_KEY contains the full private key
- Test manually: `ssh -p 22 root@YOUR_SERVER_IP`

### "Permission denied (publickey)"
- Public key not added to server's ~/.ssh/authorized_keys
- Run: `ssh-copy-id -i ~/.ssh/github_actions_deploy.pub root@YOUR_SERVER_IP`

### Build fails
- Check Java version: needs JDK 21
- Check Maven build locally: `mvn clean package`

## What Happens After Success

Once deployed, your application will be available at:
- **Application**: http://YOUR_SERVER_IP:8001
- **phpMyAdmin**: http://YOUR_SERVER_IP:8080
- **MySQL**: YOUR_SERVER_IP:3306

Credentials:
- MySQL Username: root
- MySQL Password: Hello@123
- Database: B-Eng_Dalin-db

## Need Help?
- Full documentation: GITHUB_DEPLOYMENT_SETUP.md
- GitHub Actions logs: Check the Actions tab in your repository