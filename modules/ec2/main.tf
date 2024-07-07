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
  provisioner "remote-exec" {
    inline = [
      "tail -f /var/log/cloud-init-output.log &"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.RSA.private_key_pem
      host        = self.public_ip
    }
  }
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
  depends_on = [aws_instance.frontend_ec2, aws_instance.backend_ec2]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.RSA.private_key_pem
    host        = aws_instance.frontend_ec2.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /home/ubuntu/setup_complete ]; do sleep 2; done",
      "sudo docker cp /home/ubuntu/nginx.conf frontend_nginx_1:/etc/nginx/nginx.conf",
      "sudo docker restart frontend_nginx_1"
    ]
  }

  provisioner "file" {
    content = templatefile("${path.module}/nginx.conf.tpl", {
      backend_ip = aws_instance.backend_ec2.public_ip
    })
    destination = "/home/ubuntu/nginx.conf"
  }
}

# resource "null_resource" "frontend_nginx_config" {
#   depends_on = [aws_instance.frontend_ec2, aws_instance.backend_ec2]

#   connection {
#     type        = "ssh"
#     user        = "ubuntu"
#     private_key = tls_private_key.RSA.private_key_pem
#     host        = aws_instance.frontend_ec2.public_ip
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "while [ ! -f /home/ubuntu/setup_complete ]; do sleep 10; done",
#       "sudo docker cp /home/ubuntu/nginx.conf frontend_nginx_1:/etc/nginx/nginx.conf",
#       "sudo docker restart frontend_nginx_1"
#     ]
#   }

#   provisioner "file" {
#     content = templatefile("${path.module}/nginx.conf.tpl", {
#       backend_ip = aws_instance.backend_ec2.public_ip
#     })
#     destination = "/home/ubuntu/nginx.conf"
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
      "sudo apt-get update",
      "sudo apt-get install -y docker.io docker-compose git",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo usermod -aG docker ubuntu",
      "git clone https://github.com/alvo254/devops-stage-2.git",
      "cd devops-stage-2/backend",
      "sudo docker network create app_network || true",
      "sudo sed -i 's/- \"80:80\"/- \"8080:80\"/' docker-compose.yml",
      "sudo docker-compose up -d"
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /home/ubuntu/setup_complete ]; do sleep 2; done",
      "echo 'Backend setup complete'"
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
#       "echo 'Updating Nginx configuration'",
#       "sudo cp /home/ubuntu/nginx.conf /etc/nginx/nginx.conf",
#       "sudo systemctl restart nginx",
#       "echo 'Nginx configuration updated and service restarted'",
#     ]
#   }
# }

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
