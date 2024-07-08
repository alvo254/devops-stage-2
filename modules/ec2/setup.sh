#!/bin/bash
set -ex
exec > >(tee /var/log/user-data.log) 2>&1
echo 'Starting setup...'

# Wait for APT lock to be released
echo 'Waiting for APT lock to be released...'
sudo timeout 600 bash -c 'while fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do echo "Waiting for APT lock release..."; sleep 5; done'

# Update and install dependencies
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common build-essential python3-dev postgresql postgresql-contrib

# Install Docker using the convenience script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify Docker installation
if ! command -v docker &> /dev/null; then
    echo "Docker installation failed. Attempting to fix..."
    sudo apt-get update
    sudo apt-get install -y docker.io
fi

# Verify Docker Compose installation
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose installation failed. Attempting to fix..."
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Verify Docker is running
if ! sudo systemctl is-active --quiet docker; then
    echo "Docker is not running. Attempting to start..."
    sudo systemctl start docker
fi

# Verify installations
docker --version
docker-compose --version

# Reload the user's group assignments without logging out
exec sudo su -l ubuntu

# Clone or update repository
if [ -d "devops-stage-2" ]; then
    echo "Updating existing repository..."
    cd devops-stage-2
    git pull
    cd ..
else
    echo "Cloning repository..."
    git clone https://github.com/alvo254/devops-stage-2.git
fi

cd devops-stage-2

# Set up backend
cd backend
sudo docker network create app_network || true
sudo docker-compose up -d
cd ..

# Set up frontend
cd frontend
sudo docker-compose up -d
cd ..

# Create a new Nginx configuration for the main routing
sudo tee /home/ubuntu/nginx.conf > /dev/null <<EOT
events {
    worker_connections 1024;
}

http {
    upstream frontend {
        server frontend_nginx_1:80;
    }

    upstream backend {
        server backend_nginx_1:80;
    }

    server {
        listen 80;
        server_name localhost;

        location / {
            proxy_pass http://frontend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;

            # WebSocket support
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
        }

        location /api/ {
            proxy_pass http://backend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        location /docs/ {
            proxy_pass http://backend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        location /redoc/ {
            proxy_pass http://backend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        location /adminer/ {
            proxy_pass http://backend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOT

# Run a separate Nginx container for main routing
sudo docker run -d --name main_routing_nginx \
    -p 80:80 \
    -v /home/ubuntu/nginx.conf:/etc/nginx/nginx.conf:ro \
    --network app_network \
    nginx:latest

echo 'Setup complete'