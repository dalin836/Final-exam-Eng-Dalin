#!/bin/bash

set -e

echo "========================================="
echo "Simulating GitHub Actions Workflow"
echo "========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${YELLOW}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Checkout (already done)
print_status "Step 1: Checkout (already in repository)"

# Step 2: Set up Java
print_status "Step 2: Setting up Java environment"
if ! command -v java &> /dev/null; then
    echo "Java not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y openjdk-21-jdk
fi
java -version

# Step 3: Build
print_status "Step 3: Building application"
mvn clean compile
if [ $? -eq 0 ]; then
    print_success "Build successful"
else
    print_error "Build failed"
    exit 1
fi

# Step 4: Test
print_status "Step 4: Running tests"
mvn test
if [ $? -eq 0 ]; then
    print_success "Tests passed"
else
    print_error "Tests failed"
    exit 1
fi

# Step 5: Package
print_status "Step 5: Packaging application"
mvn package -DskipTests=false
if [ $? -eq 0 ]; then
    print_success "Package created"
else
    print_error "Package failed"
    exit 1
fi

# Step 6: Check JAR
print_status "Step 6: Checking JAR file"
JAR_FILE=$(ls target/*.jar 2>/dev/null | head -1)
if [ -n "$JAR_FILE" ]; then
    print_success "JAR file found: $JAR_FILE"
else
    print_error "No JAR file found"
    exit 1
fi

# Step 7: Deploy (if requested)
if [ "$1" == "deploy" ]; then
    print_status "Step 7: Deploying application"
    
    # Check if Ansible is installed
    if ! command -v ansible-playbook &> /dev/null; then
        echo "Ansible not found. Installing..."
        sudo apt-get update
        sudo apt-get install -y ansible
    fi
    
    # Run deployment
    ansible-playbook -i inventory.ini deploy.yml \
        --extra-vars "db_password=${DB_PASSWORD:-Hello@123}"
    
    if [ $? -eq 0 ]; then
        print_success "Deployment successful"
    else
        print_error "Deployment failed"
        exit 1
    fi
fi

echo ""
echo "========================================="
echo -e "${GREEN}✅ Workflow simulation completed!${NC}"
echo "========================================="
