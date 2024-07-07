resource "aws_instance" "frontend_ec2" {
  ami                         = "ami-04b70fa74e45c3917"
  instance_type               = "t3.medium"
  subnet_id                   = var.frontend_subnet
  vpc_security_group_ids      = [var.security_group]
  key_name                    = aws_key_pair.weaver.key_name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/frontend.sh", {
    backend_ip = aws_instance.backend_ec2.public_ip
  })

  tags = {
    Name = "frontend_ec2"
  }
  # provisioner "remote-exec" {
  #   inline = [
  #     "tail -f /var/log/cloud-init-output.log &"
  #   ]

  #   connection {
  #     type        = "ssh"
  #     user        = "ubuntu"
  #     private_key = tls_private_key.RSA.private_key_pem
  #     host        = self.public_ip
  #   }
  # }
}

resource "aws_instance" "backend_ec2" {
  ami                         = "ami-04b70fa74e45c3917"
  instance_type               = "t3.medium"
  subnet_id                   = var.backend_subnet
  vpc_security_group_ids      = [var.security_group]
  key_name                    = aws_key_pair.weaver.key_name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/backend.sh", {})

  tags = {
    Name = "backend_ec2"
  }
}

resource "null_resource" "frontend_nginx_config" {
  depends_on = [null_resource.frontend_setup]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.RSA.private_key_pem
    host        = aws_instance.frontend_ec2.public_ip
  }

  provisioner "file" {
    content = templatefile("${path.module}/nginx.conf.tpl", {
      backend_ip = aws_instance.backend_ec2.private_ip
    })
    destination = "/home/ubuntu/nginx.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "set -ex",
      "echo 'Updating Nginx configuration'",
      "cd ~/devops-stage-2/frontend",
      
      # Check Docker status
      "echo 'Docker status:'",
      "sudo systemctl status docker",
      
      # List all containers
      "echo 'All containers:'",
      "sudo docker ps -a",
      
      # Check Docker Compose status
      "echo 'Docker Compose status:'",
      "sudo docker-compose ps",
      
      # Check Docker Compose logs
      "echo 'Docker Compose logs:'",
      "sudo docker-compose logs",
      
      # Try to start the containers if they're not running
      "echo 'Attempting to start containers:'",
      "sudo docker-compose up -d",
      
      # Check status again
      "echo 'Updated Docker Compose status:'",
      "sudo docker-compose ps",
      
      # Wait for Nginx container with a timeout
      "timeout 300 bash -c 'until sudo docker ps --format \"{{.Names}}\" | grep -q \"frontend_nginx_1\"; do echo \"Waiting for Nginx container...\"; sleep 10; done' || (echo 'Nginx container not found' && exit 1)",
      
      # If we get here, the Nginx container is running
      "sudo docker cp /home/ubuntu/nginx.conf frontend_nginx_1:/etc/nginx/nginx.conf",
      "sudo docker restart frontend_nginx_1",
      "echo 'Nginx configuration updated'"
    ]
  }
}
# resource "null_resource" "frontend_nginx_config" {
#   depends_on = [aws_instance.frontend_ec2, aws_instance.backend_ec2, null_resource.backend_setup]

#   connection {
#     type        = "ssh"
#     user        = "ubuntu"
#     private_key = tls_private_key.RSA.private_key_pem
#     host        = aws_instance.frontend_ec2.public_ip
#   }

#   provisioner "file" {
#     content = templatefile("${path.module}/nginx.conf.tpl", {
#       backend_ip = aws_instance.backend_ec2.public_ip
#     })
#     destination = "/home/ubuntu/nginx.conf"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "while [ ! -f /home/ubuntu/nginx.conf ]; do sleep 2; done",
#       "while ! sudo docker ps --format '{{.Names}}' | grep -q '^nginx$'; do sleep 2; done",
#       "sudo docker cp /home/ubuntu/nginx.conf nginx:/etc/nginx/nginx.conf",
#       "sudo docker restart nginx",
#       "echo 'Nginx configuration updated'"
#     ]
#   }
# }
# resource "null_resource" "frontend_nginx_config" {
#   depends_on = [aws_instance.frontend_ec2, aws_instance.backend_ec2]

#   connection {
#     type        = "ssh"
#     user        = "ubuntu"
#     private_key = tls_private_key.RSA.private_key_pem
#     host        = aws_instance.frontend_ec2.public_ip
#   }
#   provisioner "file" {
#     content = templatefile("${path.module}/nginx.conf.tpl", {
#       backend_ip = aws_instance.backend_ec2.public_ip
#     })
#     destination = "/home/ubuntu/nginx.conf"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "while [ ! -f /home/ubuntu/setup_complete ]; do sleep 2; done",
#       "sudo docker cp /home/ubuntu/nginx.conf frontend_nginx_1:/etc/nginx/nginx.conf",
#       "sudo docker restart frontend_nginx_1"
#     ]
#   }


# }


# resource "null_resource" "backend_setup" {
#   depends_on = [aws_instance.backend_ec2]

#   connection {
#     type        = "ssh"
#     user        = "ubuntu"
#     private_key = tls_private_key.RSA.private_key_pem
#     host        = aws_instance.backend_ec2.public_ip
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "while [ ! -f /home/ubuntu/setup_complete ]; do sleep 10; done",
#       "echo 'Backend setup complete'"
#     ]
#   }
# }

resource "null_resource" "frontend_setup" {
  depends_on = [aws_instance.frontend_ec2, aws_instance.backend_ec2, null_resource.backend_setup]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.RSA.private_key_pem
    host        = aws_instance.frontend_ec2.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "set -ex",
      "exec > >(tee /var/log/user-data.log) 2>&1",
      "echo 'Starting frontend setup...'",
      
      # Wait for APT lock to be released
      "echo 'Waiting for APT lock to be released...'",
      "sudo timeout 600 bash -c 'while fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do echo \"Waiting for APT lock release...\"; sleep 5; done'",
      
      # Update and install dependencies
      "sudo apt-get update",
      "sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common nginx build-essential python3-dev",

      # Install Docker using the convenience script
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",

      # Start Docker
      "sudo systemctl start docker",
      "sudo systemctl enable docker",

      # Add ubuntu user to docker group
      "sudo usermod -aG docker ubuntu",

      # Install Docker Compose
      "sudo curl -L \"https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",

          # Kill any hanging APT processes
      "sudo killall apt apt-get || true",
      
      # Clean and update APT
      "sudo rm /var/lib/apt/lists/lock || true",
      "sudo rm /var/cache/apt/archives/lock || true",
      "sudo rm /var/lib/dpkg/lock* || true",
      "sudo dpkg --configure -a",
      "sudo apt-get clean",
      "sudo apt-get update",
      "sudo chmod +x /usr/local/bin/docker-compose",

      # Verify Docker and Docker Compose installations
      "sudo docker --version",
      "sudo docker-compose --version",

      # Clone or update repository
      "if [ -d \"devops-stage-2\" ]; then",
      "  cd devops-stage-2",
      "  git pull",
      "else",
      "  git clone https://github.com/alvo254/devops-stage-2.git",
      "  cd devops-stage-2",
      "fi",

      # Set up frontend
      "cd frontend",
      "sudo docker network create app_network || true",
      
      # Build and run with detailed logging
      "echo 'Building Docker images...'",
      "sudo docker-compose build --no-cache 2>&1 | tee docker-compose-build.log || (echo 'Docker Compose build failed' && cat docker-compose-build.log && exit 1)",
      
      "echo 'Starting Docker containers...'",
      "sudo docker-compose up -d 2>&1 | tee docker-compose-up.log || (echo 'Docker Compose up failed' && cat docker-compose-up.log && exit 1)",
      
      # Check container status and logs
      "echo 'Checking container status...'",
      "sudo docker-compose ps",
      "echo 'Container logs:'",
      "sudo docker-compose logs",
      
      "sudo touch /home/ubuntu/setup_complete",
      "echo 'Frontend setup complete'"
    ]
  }
}
# resource "null_resource" "backend_setup" {
#   depends_on = [aws_instance.backend_ec2]

#   connection {
#     type        = "ssh"
#     user        = "ubuntu"
#     private_key = tls_private_key.RSA.private_key_pem
#     host        = aws_instance.backend_ec2.public_ip
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "set -e",
#       "exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1",
#       "echo 'Starting backend setup...'",

#       # Install Docker
#       "sudo apt-get update",
#       "sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common",
#       "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
#       "sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable' -y",
#       "sudo apt-get update",
#       "sudo apt-get install -y docker-ce docker-ce-cli containerd.io",

#       # Install Docker Compose
#       "sudo curl -L 'https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)' -o /usr/local/bin/docker-compose",
#       "sudo chmod +x /usr/local/bin/docker-compose",

#       # Start Docker
#       "sudo systemctl start docker",
#       "sudo systemctl enable docker",

#       # Add ubuntu user to docker group
#       "sudo usermod -aG docker ubuntu",
#       "newgrp docker",

#       # Wait for Docker to be ready
#       "timeout 300 bash -c 'until sudo docker info; do sleep 1; done'",

#       # Clone repository and set up
#       "git clone https://github.com/alvo254/devops-stage-2.git",
#       "cd devops-stage-2/backend",
#       "sudo docker network create app_network || true",
#       "sudo sed -i 's/- \"80:80\"/- \"8080:80\"/' docker-compose.yml",
#       "sudo docker-compose up -d",

#       "touch /home/ubuntu/setup_complete",
#       "echo 'Backend setup complete'"
#     ]
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "while [ ! -f /home/ubuntu/setup_complete ]; do sleep 2; done",
#       "echo 'Backend setup complete'"
#     ]
#   }
# }

resource "null_resource" "backend_setup" {
  depends_on = [aws_instance.backend_ec2]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.RSA.private_key_pem
    host        = aws_instance.backend_ec2.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "set -ex",
      "exec > >(tee /var/log/user-data.log) 2>&1",
      "echo 'Starting backend setup...'",

      # Wait for APT lock to be released
      "echo 'Waiting for APT lock to be released...'",
      "sudo timeout 600 bash -c 'while fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do echo \"Waiting for APT lock release...\"; sleep 5; done'",

      # Kill any hanging APT processes
      "sudo killall apt apt-get || true",

      # Clean and update APT
      "sudo rm /var/lib/apt/lists/lock || true",
      "sudo rm /var/cache/apt/archives/lock || true",
      "sudo rm /var/lib/dpkg/lock* || true",
      "sudo dpkg --configure -a",
      "sudo apt-get clean",
      "sudo apt-get update",

      # Update and install dependencies
      "sudo apt-get update",
      "sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common",

      # Install Docker using the convenience script
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",

      # Start Docker
      "sudo systemctl start docker",
      "sudo systemctl enable docker",

      # Add ubuntu user to docker group
      "sudo usermod -aG docker ubuntu",

      # Install Docker Compose
      "sudo curl -L \"https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",

      # Verify Docker and Docker Compose installations
      "sudo docker --version",
      "sudo docker-compose --version",

      # Install PostgreSQL
      "sudo apt-get install -y postgresql postgresql-contrib",
      "sudo systemctl start postgresql",
      "sudo systemctl enable postgresql",

  

      # Clone or update repository
      "if [ -d \"devops-stage-2\" ]; then",
      "  cd devops-stage-2",
      "  git pull",
      "else",
      "  git clone https://github.com/alvo254/devops-stage-2.git",
      "  cd devops-stage-2",
      "fi",

      # Set up backend
      "cd backend",
      "sudo docker network create app_network || true",

      # Build and run with detailed logging
      "echo 'Building Docker images...'",
      "sudo docker-compose build --no-cache 2>&1 | tee docker-compose-build.log || (echo 'Docker Compose build failed' && cat docker-compose-build.log && exit 1)",

      "echo 'Starting Docker containers...'",
      "sudo docker-compose up -d 2>&1 | tee docker-compose-up.log || (echo 'Docker Compose up failed' && cat docker-compose-up.log && exit 1)",

      # Check container status and logs
      "echo 'Checking container status...'",
      "sudo docker-compose ps",
      "echo 'Container logs:'",
      "sudo docker-compose logs",

      "sudo touch /home/ubuntu/setup_complete",
      "echo 'Backend setup complete'"
    ]
  }
}

resource "tls_private_key" "RSA" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "weaver" {
  key_name = "weaver"
  public_key = tls_private_key.RSA.public_key_openssh
}

resource "local_file" "weaver" {
  content = tls_private_key.RSA.private_key_openssh
  filename = "weaver.pem"
}


# resource "null_resource" "frontend_nginx_config" {
#   depends_on = [aws_instance.frontend_ec2, aws_instance.backend_ec2, null_resource.backend_setup]

#   connection {
#     type        = "ssh"
#     user        = "ubuntu"
#     private_key = tls_private_key.RSA.private_key_pem
#     host        = aws_instance.frontend_ec2.public_ip
#   }

#   provisioner "file" {
#     content = templatefile("${path.module}/nginx.conf.tpl", {
#       backend_ip = aws_instance.backend_ec2.public_ip
#     })
#     destination = "/home/ubuntu/nginx.conf"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "echo 'Updating Nginx configuration'",
#       "sudo cp /home/ubuntu/nginx.conf /etc/nginx/nginx.conf",
#       "sudo systemctl restart nginx",
#       "echo 'Nginx configuration updated and service restarted'",
#     ]
#   }
# }



# resource "aws_instance" "frontend_ec2" {
#   ami = "ami-04b70fa74e45c3917"
#   instance_type = "t2.micro"
#   subnet_id = var.frontend_subnet
#   vpc_security_group_ids = [var.security_group]
#   key_name = "${aws_key_pair.weaver.key_name}"
#   # user_data = data.template_file.user_data.rendered
#   associate_public_ip_address = true

#     user_data = templatefile("${path.module}/user_data.sh.tpl", {
#     nginx_config = templatefile("${path.module}/nginx.conf.tpl", {
#       frontend_ip = aws_instance.frontend_ec2.public_ip,
#       backend_ip  = aws_instance.backend_ec2.public_ip
#     })
#   })


#   tags = {
#     Name = "frontend_ec2"
#   }

# }

# resource "aws_instance" "backend_ec2" {
#   ami = "ami-04b70fa74e45c3917"
#   instance_type = "t2.micro"
#   subnet_id = var.backend_subnet
#   vpc_security_group_ids = [var.security_group]
#   key_name = "${aws_key_pair.weaver.key_name}"
#   user_data = data.template_file.backend.rendered
#   associate_public_ip_address = true


#   tags = {
#     Name = "backend_ec2"
#   }

# }


# resource "tls_private_key" "RSA" {
#   algorithm = "RSA"
#   rsa_bits = 4096
# }

# resource "aws_key_pair" "weaver" {
#   key_name = "weaver"
#   public_key = tls_private_key.RSA.public_key_openssh
# }

# resource "local_file" "weaver" {
#   content = tls_private_key.RSA.private_key_openssh
#   filename = "weaver.pem"
# }


# data "template_file" "user_data" {
#   template = file("${path.module}/frontend.sh")
#   #   vars = {
#   #   domain_or_ip = aws_instance.webweaver_ec2.public_ip
#   # }
# }

# data "template_file" "backend" {
#   template = file("${path.module}/backend.sh")
#   #   vars = {
#   #   domain_or_ip = aws_instance.webweaver_ec2.public_ip
#   # }
# }
