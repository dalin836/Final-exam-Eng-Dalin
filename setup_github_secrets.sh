#!/bin/bash

# GitHub Secrets Setup Script
# This script helps you set up the required GitHub repository secrets

set -e

echo "========================================="
echo "GitHub Secrets Setup Helper"
echo "========================================="
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "Please install it first: https://cli.github.com/"
    echo ""
    echo "On Ubuntu/Debian:"
    echo "  sudo apt install gh"
    echo ""
    echo "Then run: gh auth login"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ You are not authenticated with GitHub CLI."
    echo "Please run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is installed and authenticated"
echo ""

# Get repository information
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo "Repository: $REPO"
echo ""

# Function to set secret
set_secret() {
    local secret_name=$1
    local secret_value=$2
    
    if [ -z "$secret_value" ]; then
        echo "⚠️  Skipping $secret_name (no value provided)"
        return
    fi
    
    echo "$secret_value" | gh secret set "$secret_name"
    echo "✅ Set $secret_name"
}

# Required secrets
echo "========================================="
echo "Setting up required secrets"
echo "========================================="
echo ""

# DEPLOY_HOST
read -p "Enter your server IP address or domain (e.g., 192.168.1.100): " DEPLOY_HOST
set_secret "DEPLOY_HOST" "$DEPLOY_HOST"

# DEPLOY_PORT
read -p "Enter SSH port (default: 22): " DEPLOY_PORT
DEPLOY_PORT=${DEPLOY_PORT:-22}
set_secret "DEPLOY_PORT" "$DEPLOY_PORT"

# DEPLOY_USER
read -p "Enter SSH username (e.g., root, ubuntu): " DEPLOY_USER
set_secret "DEPLOY_USER" "$DEPLOY_USER"

# DEPLOY_SSH_KEY
echo ""
echo "========================================="
echo "SSH Key Setup"
echo "========================================="
echo ""
echo "Do you want to:"
echo "1) Use existing SSH key"
echo "2) Generate new SSH key"
read -p "Choose option (1 or 2): " SSH_OPTION

if [ "$SSH_OPTION" = "2" ]; then
    # Generate new SSH key
    KEY_PATH="$HOME/.ssh/github_actions_deploy"
    
    if [ -f "$KEY_PATH" ]; then
        echo "⚠️  Key already exists at $KEY_PATH"
        read -p "Overwrite? (y/N): " OVERWRITE
        if [ "$OVERWRITE" != "y" ]; then
            echo "Using existing key..."
        else
            ssh-keygen -t rsa -b 4096 -C "github-actions-deploy" -f "$KEY_PATH" -N ""
        fi
    else
        ssh-keygen -t rsa -b 4096 -C "github-actions-deploy" -f "$KEY_PATH" -N ""
    fi
    
    echo ""
    echo "Public key (add this to your server's ~/.ssh/authorized_keys):"
    echo "========================================="
    cat "${KEY_PATH}.pub"
    echo "========================================="
    echo ""
    
    read -p "Have you added the public key to your server? (y/N): " KEY_ADDED
    if [ "$KEY_ADDED" != "y" ]; then
        echo "⚠️  Please add the public key to your server before continuing"
        echo "Run: ssh-copy-id -i ${KEY_PATH}.pub -p $DEPLOY_PORT $DEPLOY_USER@$DEPLOY_HOST"
        exit 1
    fi
    
    DEPLOY_SSH_KEY=$(cat "$KEY_PATH")
    set_secret "DEPLOY_SSH_KEY" "$DEPLOY_SSH_KEY"
else
    echo ""
    echo "Please paste your private SSH key (press Ctrl+D when done):"
    DEPLOY_SSH_KEY=$(cat)
    set_secret "DEPLOY_SSH_KEY" "$DEPLOY_SSH_KEY"
fi

# Email configuration (optional)
echo ""
echo "========================================="
echo "Email Notification Setup (Optional)"
echo "========================================="
echo ""
read -p "Do you want to set up email notifications? (y/N): " SETUP_EMAIL

if [ "$SETUP_EMAIL" = "y" ]; then
    read -p "Enter Gmail address: " EMAIL_USERNAME
    set_secret "EMAIL_USERNAME" "$EMAIL_USERNAME"
    
    echo ""
    echo "To use Gmail, you need to create an App Password:"
    echo "1. Go to https://myaccount.google.com/security"
    echo "2. Enable 2-Step Verification if not already enabled"
    echo "3. Go to App passwords"
    echo "4. Generate a new app password for 'Mail'"
    echo ""
    read -p "Enter Gmail app password: " EMAIL_PASSWORD
    set_secret "EMAIL_PASSWORD" "$EMAIL_PASSWORD"
    
    read -p "Enter admin email to receive notifications: " ADMIN_EMAIL
    set_secret "ADMIN_EMAIL" "$ADMIN_EMAIL"
fi

# Optional secrets
echo ""
echo "========================================="
echo "Optional Configuration"
echo "========================================="
echo ""

read -p "Enter application port (default: 8001): " APP_PORT
APP_PORT=${APP_PORT:-8001}
set_secret "APP_PORT" "$APP_PORT"

echo ""
echo "========================================="
echo "✅ Setup Complete!"
echo "========================================="
echo ""
echo "Configured secrets:"
echo "  - DEPLOY_HOST: $DEPLOY_HOST"
echo "  - DEPLOY_PORT: $DEPLOY_PORT"
echo "  - DEPLOY_USER: $DEPLOY_USER"
echo "  - DEPLOY_SSH_KEY: [REDACTED]"
echo "  - APP_PORT: $APP_PORT"
if [ "$SETUP_EMAIL" = "y" ]; then
    echo "  - EMAIL_USERNAME: $EMAIL_USERNAME"
    echo "  - ADMIN_EMAIL: $ADMIN_EMAIL"
fi
echo ""
echo "Next steps:"
echo "1. Test SSH connection: ssh -p $DEPLOY_PORT $DEPLOY_USER@$DEPLOY_HOST"
echo "2. Push code to trigger deployment: git push origin main"
echo "3. Monitor deployment: https://github.com/$REPO/actions"
echo ""