#!/bin/bash

# Update the system package list
echo "Updating package list..."
sudo apt-get update -y
echo "Done!"

# Upgrade all installed packages to their latest versions
echo "Upgrading installed packages..."
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
echo "Done!"

# Installing relevant certificates & adding Docker's official GPG key:
echo Docker pre-installation setup...
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
echo Done!

# Install Docker and Docker Compose
echo "Installing Docker and Docker Compose..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
echo "Done!"

# Creating a directory for the Docker Compose project
echo "Creating a directory for the project and navigating into it..."
mkdir prov-app-db-docker-compose
cd prov-app-db-docker-compose
echo "Done!"

# Download library.sql file from GitHub
echo Downloading database seeding file...
curl -u <pat_token>:x-oauth-basic -O https://raw.githubusercontent.com/AdonisAlgos/java-springboot-app/main/library.sql
echo "Done!"

# Create Docker Compose file
echo "Creating Docker Compose file..."
cat <<EOL > ./docker-compose.yml
services:
  mysql:
    image: mysql:latest
    container_name: mysql_container
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: root_pass
      MYSQL_DATABASE: library
      MYSQL_USER: db_setup
      MYSQL_PASSWORD: db_setup
    volumes:
      - mysql_data:/var/lib/mysql
      - ./library.sql:/docker-entrypoint-initdb.d/library.sql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "127.0.0.1"]
      interval: 10s
      timeout: 5s
      retries: 3

  app:
    image: adonisdev/java-bootstrap-app:v1
    container_name: app_container
    ports:
      - "5000:5000"
    environment:
      DB_HOST: "jdbc:mysql://mysql:3306/library"
      DB_USER: db_setup
      DB_PASS: db_setup
    depends_on:
      mysql:
        condition: service_healthy

volumes:
  mysql_data:
EOL
echo "Done!"

# Start Docker Compose services
echo "Starting Docker Compose services..."
sudo docker compose up -d
echo "Done!"

# Verify running containers
echo "Verifying running containers..."
docker ps
echo "Provisioning complete!"
