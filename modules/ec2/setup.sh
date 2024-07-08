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

# Check if Docker is installed, if not, install it
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ubuntu
else
    echo "Docker is already installed."
fi

# Verify Docker installation
docker --version || echo "Docker installation failed"

# Install Docker Compose if not already installed
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose not found. Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose is already installed."
fi

# Verify Docker Compose installation
docker-compose --version || echo "Docker Compose installation failed"

# PostgreSQL setup
echo "Configuring PostgreSQL..."

# Find PostgreSQL configuration directory
PG_CONF_DIR=$(sudo find /etc/postgresql -name "postgresql.conf" -exec dirname {} \; | sort -V | tail -n 1)
if [ -z "$PG_CONF_DIR" ]; then
    echo "PostgreSQL configuration directory not found."
    exit 1
fi

PG_HBA_CONF="$PG_CONF_DIR/pg_hba.conf"
PG_CONF="$PG_CONF_DIR/postgresql.conf"

# Backup original files
sudo cp "$PG_HBA_CONF" "$PG_HBA_CONF.bak"
sudo cp "$PG_CONF" "$PG_CONF.bak"

# Modify pg_hba.conf
echo "Modifying $PG_HBA_CONF"
sudo tee -a "$PG_HBA_CONF" > /dev/null <<EOF
# Allow connections from all IPv4 addresses
host    all             all             0.0.0.0/0               md5
EOF

# Modify postgresql.conf
echo "Modifying $PG_CONF"
if sudo grep -q "^#listen_addresses" "$PG_CONF"; then
    sudo sed -i "s/^#listen_addresses.*/listen_addresses = '*'/" "$PG_CONF"
elif sudo grep -q "^listen_addresses" "$PG_CONF"; then
    sudo sed -i "s/^listen_addresses.*/listen_addresses = '*'/" "$PG_CONF"
else
    echo "listen_addresses = '*'" | sudo tee -a "$PG_CONF" > /dev/null
fi

# Restart PostgreSQL
sudo systemctl restart postgresql

# Function to check if a database exists
database_exists() {
    sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='$1'" | grep -q 1
}

# Create databases and user
sudo -u postgres psql <<EOF
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_user WHERE usename = 'ubuntu') THEN
        CREATE USER ubuntu WITH PASSWORD 'twende@1357';
    END IF;
END
\$\$;

SELECT 'Creating ubuntu database' WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'ubuntu');
CREATE DATABASE ubuntu;
GRANT ALL PRIVILEGES ON DATABASE ubuntu TO ubuntu;

SELECT 'Creating fast_api database' WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'fast_api');
CREATE DATABASE fast_api;
GRANT ALL PRIVILEGES ON DATABASE fast_api TO ubuntu;
EOF

# Check if databases were created successfully
if database_exists "ubuntu" && database_exists "fast_api"; then
    echo "Databases 'ubuntu' and 'fast_api' created successfully."
else
    echo "Failed to create one or both databases."
    exit 1
fi

# Test database connection
echo "Testing database connection..."
cat << EOF > /tmp/test_connection.sql
\c fast_api
\dt
SELECT 'Connection successful' AS result;
EOF

sudo -u postgres psql -f /tmp/test_connection.sql

if [ $? -eq 0 ]; then
    echo "Successfully connected to the database."
else
    echo "Failed to connect to the database."
    exit 1
fi

# Remove temporary SQL file
rm /tmp/test_connection.sql

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

# Create a new Nginx configuration for routing
sudo tee /etc/nginx/sites-available/devops-stage-2 > /dev/null <<EOT
server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://localhost:5173;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /api/ {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /docs/ {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /redoc/ {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /adminer/ {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOT

# Enable the Nginx configuration
sudo ln -s /etc/nginx/sites-available/devops-stage-2 /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

echo 'Setup complete'