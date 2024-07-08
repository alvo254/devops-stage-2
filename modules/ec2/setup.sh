#!/bin/bash
set -ex
exec > >(tee /var/log/user-data.log) 2>&1
echo 'Starting setup...'

# ... (previous setup steps remain the same)

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

# Update Nginx configuration
sudo tee /etc/nginx/nginx.conf > /dev/null <<EOT
events {
    worker_connections 1024;
}

http {
    upstream frontend {
        server 127.0.0.1:5173;
    }

    upstream backend {
        server 127.0.0.1:8000;
    }

    server {
        listen 80;
        server_name localhost;

        # Frontend routing
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

        # Backend routing
        location /api/ {
            proxy_pass http://backend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOT

sudo systemctl restart nginx

echo 'Setup complete'