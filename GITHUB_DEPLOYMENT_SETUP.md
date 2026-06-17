# GitHub Actions Deployment Setup

This guide explains how to set up automated deployment using GitHub Actions.

## Prerequisites

1. **Remote Server**: You need a remote server (VPS/cloud instance) to deploy the application
2. **SSH Access**: The server must be accessible via SSH
3. **Docker on Server**: The remote server should have Docker and Docker Compose installed

## Required GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions, and add the following secrets:

### Required Secrets:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `DEPLOY_HOST` | IP address or domain of your remote server | `192.168.1.100` or `myserver.com` |
| `DEPLOY_PORT` | SSH port on the remote server | `22` |
| `DEPLOY_USER` | SSH username for the remote server | `root` or `ubuntu` |
| `DEPLOY_SSH_KEY` | Private SSH key for authentication | (See below for generation) |
| `EMAIL_USERNAME` | Gmail address for notifications | `your-email@gmail.com` |
| `EMAIL_PASSWORD` | Gmail app password for notifications | `your-app-password` |
| `ADMIN_EMAIL` | Email address to receive notifications | `admin@example.com` |

### Optional Secrets (for enhanced deployment):

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `APP_PORT` | Port the application runs on | `8001` |
| `MYSQL_HOST` | MySQL database host | `localhost` or `mysql-db` |
| `MYSQL_PORT` | MySQL port | `3306` |

## SSH Key Generation

Generate an SSH key pair for GitHub Actions deployment:

```bash
# Generate new SSH key (don't overwrite existing keys!)
ssh-keygen -t rsa -b 4096 -C "github-actions-deploy" -f ~/.ssh/github_actions_deploy

# This creates:
# - ~/.ssh/github_actions_deploy (private key)
# - ~/.ssh/github_actions_deploy.pub (public key)

# Copy the public key to your remote server
ssh-copy-id -i ~/.ssh/github_actions_deploy.pub -p 22 user@your-server-ip

# Add the PRIVATE key content to GitHub Secrets as DEPLOY_SSH_KEY
cat ~/.ssh/github_actions_deploy
```

## Server Setup

On your remote server, install required dependencies:

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

# Add your user to docker group (optional, avoids sudo)
sudo usermod -aG docker $USER

# Install Ansible (optional, for manual deployments)
sudo apt install -y ansible sshpass
```

## Deployment Architecture

### Option 1: Docker Compose Deployment (Recommended)

Create a `docker-compose.prod.yml` on your server:

```yaml
version: '3.8'

services:
  mysql:
    image: mysql:8
    container_name: mysql-db
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: B-Eng_Dalin-db
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    restart: always

  phpmyadmin:
    image: phpmyadmin/phpmyadmin:latest
    container_name: phpmyadmin
    environment:
      PMA_HOST: mysql-db
      PMA_PORT: 3306
    ports:
      - "8080:80"
    depends_on:
      - mysql
    restart: always

  app:
    image: openjdk:21-jdk-slim
    container_name: idcard-management
    volumes:
      - ./app.jar:/app/app.jar
    ports:
      - "8001:8001"
    command: java -jar /app/app.jar
    depends_on:
      - mysql
    restart: always

volumes:
  mysql_data:
```

### Option 2: Direct Java Deployment

Deploy the JAR file directly on the server without Docker.

## GitHub Actions Workflow

The workflow is already configured in `.github/workflows/ci-cd.yml`. It will:

1. **Build and Test** (on every push/PR):
   - Checkout code
   - Set up JDK 21
   - Build with Maven
   - Run tests
   - Upload JAR artifact

2. **Deploy** (only on main/master branch):
   - Download JAR artifact
   - Connect to server via SSH
   - Run Ansible deployment playbook
   - Verify application health
   - Send email notifications

## How It Works

### CI/CD Pipeline Flow:

```
Push to GitHub
    ↓
GitHub Actions Triggered
    ↓
Build & Test Job
    ↓ (if successful)
Deploy Job
    ↓
SSH to Remote Server
    ↓
Run Ansible Playbook
    ↓
Deploy Application
    ↓
Health Check
    ↓
Send Notification Email
```

## Testing the Setup

### 1. Test Locally First

```bash
# Build the application
mvn clean package

# Test with Docker Compose
sudo docker compose up -d

# Check if phpMyAdmin is accessible
curl http://localhost:8080

# Check if application is running
curl http://localhost:8001/actuator/health
```

### 2. Test GitHub Actions

1. Commit and push your changes:
```bash
git add .
git commit -m "Setup GitHub Actions deployment"
git push origin main
```

2. Go to GitHub repository → Actions tab
3. You should see the workflow running
4. Click on the workflow to see detailed logs

### 3. Test SSH Connection

```bash
# Test SSH connection to your server
ssh -p 22 user@your-server-ip

# Test Ansible connection
ansible -i inventory.ini web -m ping
```

## Troubleshooting

### Issue: "Permission denied (publickey)"
**Solution**: Check that:
- DEPLOY_SSH_KEY secret contains the correct private key
- Public key is added to `~/.ssh/authorized_keys` on the server
- SSH port is correct in DEPLOY_PORT secret

### Issue: "Connection refused"
**Solution**: 
- Verify server IP/hostname is correct
- Check if SSH port is open: `telnet your-server-ip 22`
- Check firewall rules on the server

### Issue: "Application health check failed"
**Solution**:
- Check application logs on the server
- Verify Java is installed: `java -version`
- Verify port 8001 is not in use
- Check database connection

### Issue: "MySQL connection refused"
**Solution**:
- Ensure MySQL container is running: `sudo docker compose ps`
- Check MySQL credentials in application.properties
- Verify MySQL port mapping in docker-compose.yml

## Manual Deployment (Alternative)

If you prefer manual deployment without GitHub Actions:

```bash
# On your local machine
mvn clean package

# Copy JAR to server
scp target/*.jar user@server:/opt/idcard-management/

# SSH to server and deploy
ssh user@server
cd /opt/idcard-management
java -jar idcard-management.jar
```

## Security Considerations

1. **Never commit secrets** to the repository
2. **Use strong passwords** for MySQL and server access
3. **Enable firewall** on the server (UFW/iptables)
4. **Use SSH keys** instead of passwords
5. **Regular backups** of MySQL database
6. **Keep dependencies updated** (Java, Docker, etc.)

## Monitoring

### Check Application Status:
```bash
# On the server
sudo docker compose ps
sudo docker logs idcard-management
sudo docker logs mysql-db
```

### Check phpMyAdmin:
```
http://your-server-ip:8080
Username: root
Password: Hello@123
```

### Monitor Logs:
```bash
# Application logs
tail -f /var/log/idcard-management/app.log

# Docker logs
sudo docker logs -f idcard-management
sudo docker logs -f mysql-db
```

## Next Steps

1. ✅ Set up remote server with Docker
2. ✅ Generate and configure SSH keys
3. ✅ Add all required secrets to GitHub
4. ✅ Push code to trigger first deployment
5. ✅ Verify application is running
6. ✅ Set up monitoring and alerts
7. ✅ Configure automated backups

## Support

If you encounter issues:
1. Check GitHub Actions logs
2. Check server logs
3. Verify all secrets are configured
4. Test SSH connection manually
5. Review Ansible playbook output