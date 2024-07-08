resource "aws_instance" "consolidated_ec2" {
  ami                         = "ami-04b70fa74e45c3917"
  instance_type               = "t3.medium"
  subnet_id                   = var.frontend_subnet
  vpc_security_group_ids      = [var.security_group]
  key_name                    = aws_key_pair.weaver.key_name
  associate_public_ip_address = true

  tags = {
    Name = "consolidated_ec2"
  }
}

resource "null_resource" "setup_consolidated_instance" {
  depends_on = [aws_instance.consolidated_ec2]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.RSA.private_key_pem
    host        = aws_instance.consolidated_ec2.public_ip
  }

  provisioner "file" {
    source      = "${path.module}/setup.sh"
    destination = "/tmp/setup_script.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup_script.sh",
      "/tmp/setup_script.sh"
    ]
  }
}

resource "tls_private_key" "RSA" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "weaver" {
  key_name   = "weaver"
  public_key = tls_private_key.RSA.public_key_openssh
}

resource "local_file" "weaver" {
  content  = tls_private_key.RSA.private_key_openssh
  filename = "weaver.pem"
}