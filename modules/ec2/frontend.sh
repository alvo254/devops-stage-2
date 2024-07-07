#!/bin/bash

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting setup..."

# Update and install dependencies
sudo apt update -y
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's official GPG key and repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y 

# Install Docker
sudo apt update -y
sudo apt install -y docker-ce

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group
sudo usermod -aG docker $USER

# Apply the new group membership without logging out and back in
newgrp docker

# Install Docker Compose (latest version)
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
sudo curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Nginx
sudo apt install -y nginx

# Clone the repository
git clone https://github.com/alvo254/devops-stage-2
cd devops-stage-2/frontend

# Create docker network
sudo docker network create app_network || true

# Start the application using Docker Compose
docker-compose up -d

sleep 2

# Copy the Nginx configuration
sudo docker cp /home/ubuntu/nginx.conf frontend_nginx_1:/etc/nginx/nginx.conf

# Restart the Nginx container to apply changes
sudo docker restart frontend_nginx_1

touch /home/ubuntu/setup_complete