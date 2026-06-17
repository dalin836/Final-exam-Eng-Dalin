#!/bin/bash

cd ~/Documents/demo

echo "========================================="
echo "Quick Fix - Deploy with H2 Database"
echo "========================================="

# 1. Update application.properties for H2
echo "1. Updating application.properties for H2..."
cat > src/main/resources/application.properties << 'PROP'
spring.application.name=demo
server.port=8001

spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.driver-class-name=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=

spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true

spring.thymeleaf.cache=false
spring.servlet.multipart.max-file-size=5MB
spring.servlet.multipart.max-request-size=5MB

management.endpoints.web.exposure.include=health,info
management.endpoint.health.show-details=always
PROP

# 2. Update pom.xml with H2
echo "2. Adding H2 dependency..."
if ! grep -q "h2" pom.xml; then
    sed -i '/<dependencies>/a\
        <dependency>\
            <groupId>com.h2database</groupId>\
            <artifactId>h2</artifactId>\
            <scope>runtime</scope>\
        </dependency>' pom.xml
fi

# 3. Build locally
echo "3. Building locally..."
mvn clean package -DskipTests=true

# 4. Test locally
echo "4. Testing locally..."
java -jar target/*.jar --server.port=8001 &
sleep 10
curl http://localhost:8001/actuator/health

# 5. Kill the process
pkill -f "java -jar target" || true

echo ""
echo "========================================="
echo "✅ Fix complete! Push to GitHub:"
echo "git add ."
echo "git commit -m 'Use H2 database for deployment'"
echo "git push origin main"
echo "========================================="
