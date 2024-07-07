resource "aws_instance" "frontend_ec2" {
  ami                         = "ami-04b70fa74e45c3917"
  instance_type               = "t2.micro"
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
}

resource "aws_instance" "backend_ec2" {
  ami                         = "ami-04b70fa74e45c3917"
  instance_type               = "t2.micro"
  subnet_id                   = var.backend_subnet
  vpc_security_group_ids      = [var.security_group]
  key_name                    = aws_key_pair.weaver.key_name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/backend.sh", {})

  tags = {
    Name = "backend_ec2"
  }
}

resource "null_resource" "nginx_config" {
  depends_on = [aws_instance.frontend_ec2, aws_instance.backend_ec2]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.RSA.private_key_pem
    host        = aws_instance.frontend_ec2.public_ip
  }

  provisioner "file" {
    content = templatefile("${path.module}/nginx.conf.tpl", {
      frontend_ip = aws_instance.frontend_ec2.public_ip
      backend_ip  = aws_instance.backend_ec2.public_ip
    })
    destination = "/home/ubuntu/nginx.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /home/ubuntu/nginx.conf /etc/nginx/nginx.conf",
       "sudo systemctl restart nginx"
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
