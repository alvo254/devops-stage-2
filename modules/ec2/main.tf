resource "aws_instance" "frontend_ec2" {
  ami = "ami-04b70fa74e45c3917"
  instance_type = "t2.micro"
  subnet_id = var.subnet_id
  vpc_security_group_ids = [var.security_group]
  key_name = "${aws_key_pair.weaver.key_name}"
  user_data = data.template_file.user_data.rendered
  associate_public_ip_address = true


  tags = {
    Name = "frontend_ec2"
  }

}

# resource "aws_instance" "backend_ec2" {
#   ami = "ami-04b70fa74e45c3917"
#   instance_type = "t2.micro"
#   subnet_id = var.subnet_id
#   vpc_security_group_ids = [var.security_group]
#   key_name = "${aws_key_pair.weaver.key_name}"
#   user_data = data.template_file.user_data.rendered
#   associate_public_ip_address = true


#   tags = {
#     Name = "frontend_ec2"
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


data "template_file" "user_data" {
  template = file("${path.module}/backend.sh")
  #   vars = {
  #   domain_or_ip = aws_instance.webweaver_ec2.public_ip
  # }
}

