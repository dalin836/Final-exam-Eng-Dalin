#!/bin/bash

set -e

echo "========================================="
echo "Deploying Application"
echo "========================================="

# Configuration
APP_NAME="idcard-management"
DEPLOY_DIR="/opt/${APP_NAME}"
JAR_FILE="target/${APP_NAME}*.jar"

# Create deployment directory
mkdir -p ${DEPLOY_DIR}

# Find JAR file
JAR=$(ls ${JAR_FILE} 2>/dev/null | head -1)
if [ -z "$JAR" ]; then
    echo "❌ No JAR file found!"
    exit 1
fi

echo "✅ Found JAR: ${JAR}"

# Copy JAR
cp ${JAR} ${DEPLOY_DIR}/${APP_NAME}.jar

# Copy application properties
cp application.properties ${DEPLOY_DIR}/

# Stop existing process
pkill -f ${APP_NAME} || true

# Start application
cd ${DEPLOY_DIR}
nohup java -jar ${APP_NAME}.jar > app.log 2>&1 &

echo "✅ Application started"
echo "Logs: ${DEPLOY_DIR}/app.log"

# Wait for application to start
sleep 5

# Check health
curl -s http://localhost:8001/actuator/health || echo "Health check pending"

echo "========================================="
echo "✅ Deployment complete!"
echo "========================================="
