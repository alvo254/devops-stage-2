#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Update and install dependencies
sudo apt update
sudo apt install -y nginx nodejs npm git

sudo apt install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql

psql --version
sudo sh -c 'echo "host all             all             0.0.0.0/0               scram-sha-256" >> /etc/postgresql/16/main/pg_hba.conf'
sudo -u postgres psql <<EOF
CREATE DATABASE ubuntu;
CREATE USER ubuntu WITH PASSWORD 'twende@1357';
GRANT ALL PRIVILEGES ON DATABASE ubuntu TO ubuntu;
CREATE DATABASE fast_api;
GRANT ALL PRIVILEGES ON DATABASE fast_api TO ubuntu;
\q
EOF

# for my debugging 
#SELECT * FROM public.user;

# # Clone the React app (replace with your repository URL)
# git clone https://github.com/alvo254/webweaver
# cd webweaver/frontend

# # Install dependencies and build the React app
# npm install
# npm run build

# # Configure Nginx
# sudo tee /etc/nginx/sites-available/default > /dev/null <<EOT
# server {
#     listen 80;
#     server_name _;

#     location / {
#         proxy_pass http://localhost:3000;
#         proxy_http_version 1.1;
#         proxy_set_header Upgrade \$http_upgrade;
#         proxy_set_header Connection 'upgrade';
#         proxy_set_header Host \$host;
#         proxy_cache_bypass \$http_upgrade;
#     }
# }
# EOT

# # Restart Nginx
# sudo systemctl restart nginx


# //------------------------------------experimenting-----------------------------
# # Install PM2 globally
# sudo npm install -g pm2

# # Start the React app with PM2
# pm2 start npm --name "frontend" -- start

# # Save the PM2 process list and configure to start on reboot
# pm2 save
# sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ubuntu --hp /home/ubuntu

# echo "Installation completed successfully!"