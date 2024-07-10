resource "aws_instance" "consolidated_ec2" {
  ami                         = "ami-04b70fa74e45c3917"
  instance_type               = "t3.medium"
  subnet_id                   = var.frontend_subnet
  vpc_security_group_ids      = [var.security_group]
  key_name                    = aws_key_pair.weaver.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 80 # Custom size, e.g., 20 GB
    delete_on_termination = true
  }

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

  provisioner "remote-exec" {
    inline = [
      "cd ~/devops-stage-2/backend",
      "docker-compose up -d",
      "sleep 30",  # Give containers time to start up
      "docker-compose logs > docker_logs.txt",
      "cat docker_logs.txt"
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