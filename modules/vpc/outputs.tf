output "vpc_id" {
  value = aws_vpc.webweaver.id
}

output "frontend_subnet" {
  value = aws_subnet.frontend.id
}

output "backend_subnet"{
  value = aws_subnet.backend.id
}