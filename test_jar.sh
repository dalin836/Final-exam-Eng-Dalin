#!/bin/bash

echo "========================================="
echo "Testing JAR file"
echo "========================================="

# Build
mvn clean package -DskipTests=true

# Find JAR
JAR=$(ls target/*.jar | head -1)
if [ -z "$JAR" ]; then
    echo "❌ No JAR found"
    exit 1
fi

echo "✅ Found: $JAR"

# Test run
echo "Starting JAR..."
java -jar $JAR --server.port=8001 &
PID=$!

echo "PID: $PID"
sleep 15

# Check if running
if ps -p $PID > /dev/null 2>&1; then
    echo "✅ Process running"
    curl -v http://localhost:8001/actuator/health
else
    echo "❌ Process died"
fi

# Cleanup
kill $PID 2>/dev/null || true

echo "========================================="
