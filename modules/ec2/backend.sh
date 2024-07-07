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
sudo sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/[version]/main/postgresql.conf

git clone https://github.com/alvo254/devops-stage-2.git
cd backend
docker compose up --build

# for my debugging 
#SELECT * FROM public.user;




