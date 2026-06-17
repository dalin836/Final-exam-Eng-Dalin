#!/bin/bash

echo "========================================="
echo "Testing GitHub Actions Workflow Locally"
echo "========================================="

# Step 1: Build the application
echo ""
echo "Step 1: Building application..."
mvn clean package -DskipTests=false

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi
echo "✅ Build successful!"

# Step 2: Run tests
echo ""
echo "Step 2: Running tests..."
mvn test

if [ $? -ne 0 ]; then
    echo "❌ Tests failed!"
    exit 1
fi
echo "✅ Tests passed!"

# Step 3: Check JAR file
echo ""
echo "Step 3: Checking JAR file..."
JAR_FILE=$(ls target/*.jar 2>/dev/null | head -1)
if [ -z "$JAR_FILE" ]; then
    echo "❌ No JAR file found!"
    exit 1
fi
echo "✅ Found JAR: $JAR_FILE"

# Step 4: Test deployment (optional)
if [ "$1" == "deploy" ]; then
    echo ""
    echo "Step 4: Testing deployment..."
    ansible-playbook -i inventory.ini deploy.yml --check
    if [ $? -ne 0 ]; then
        echo "❌ Deployment check failed!"
        exit 1
    fi
    echo "✅ Deployment check passed!"
fi

echo ""
echo "========================================="
echo "✅ All tests passed successfully!"
echo "========================================="
