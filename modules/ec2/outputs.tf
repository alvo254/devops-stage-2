output "frontend_ip" {
  value = aws_instance.frontend_ec2.public_ip
}

output "backend_ip" {
  value = aws_instance.backend_ec2.public_ip
}

output "frontend_public_ip" {
  value = aws_instance.frontend_ec2.public_ip
}

output "backend_public_ip" {
  value = aws_instance.backend_ec2.public_ip
}

output "private_key" {
  value     = tls_private_key.RSA.private_key_pem
  sensitive = true
}