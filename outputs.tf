output "frontend_ip" {
  value = module.ec2.frontend_ip
}

output "backend_ip" {
  value = module.ec2.backend_ip
}