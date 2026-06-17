#!/bin/bash

# Navigate to project
cd ~/Documents/demo

# Check if in git repo
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "❌ Not in a Git repository!"
    echo "Please run: cd ~/Documents/demo"
    exit 1
fi

echo "✅ In Git repository: $(pwd)"

# Set secrets
echo "Setting secrets..."

gh secret set ADMIN_EMAIL --body "srengty@gmail.com"
gh secret set EMAIL_USERNAME --body "your-email@gmail.com"
gh secret set EMAIL_PASSWORD --body "your-app-password"
gh secret set DEPLOY_HOST --body "localhost"
gh secret set DEPLOY_PORT --body "2222"
gh secret set DEPLOY_USER --body "root"

# Set SSH key if it exists
if [ -f ~/.ssh/github_actions_deploy ]; then
    gh secret set DEPLOY_SSH_KEY --body "$(cat ~/.ssh/github_actions_deploy)"
else
    echo "⚠️ SSH key not found at ~/.ssh/github_actions_deploy"
    echo "Generate with: ssh-keygen -t rsa -b 4096 -f ~/.ssh/github_actions_deploy"
fi

gh secret set DB_PASSWORD --body "Hello@123"
gh secret set APP_PORT --body "8001"

echo ""
echo "✅ Secrets set successfully!"
echo ""
echo "List of secrets:"
gh secret list
