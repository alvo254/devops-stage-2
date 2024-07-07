#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Update and install dependencies
sudo apt update
sudo apt install -y nginx nodejs npm git

# Install Docker and Docker Compose
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update -y
sudo apt install -y docker-ce
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose (latest version)
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
sudo curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Configure PostgreSQL
sudo sh -c 'echo "host all all 0.0.0.0/0 scram-sha-256" >> /etc/postgresql/16/main/pg_hba.conf'
sudo -u postgres psql <<EOF
CREATE DATABASE ubuntu;
CREATE USER ubuntu WITH PASSWORD 'twende@1357';
GRANT ALL PRIVILEGES ON DATABASE ubuntu TO ubuntu;
CREATE DATABASE fast_api;
GRANT ALL PRIVILEGES ON DATABASE fast_api TO ubuntu;
EOF

sudo sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/16/main/postgresql.conf

# Restart PostgreSQL to apply changes
sudo systemctl restart postgresql

# Clone the repository and build the Docker images
git clone https://github.com/alvo254/devops-stage-2
cd devops-stage-2/backend
docker-compose up --build

# Debugging query (commented out)
# SELECT * FROM public.user;
