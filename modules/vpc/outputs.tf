output "vpc_id" {
  value = aws_vpc.webweaver.id
}

output "public_subnet" {
  value = aws_subnet.webweaver.id
}