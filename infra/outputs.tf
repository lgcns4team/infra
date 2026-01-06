output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  value = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  value = aws_subnet.private_db[*].id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.nat.id
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "alb_arn" {
  value = aws_lb.this.arn
}

output "monitoring_private_ip" {
  value = aws_instance.monitoring.private_ip
}

output "jenkins_private_ip" {
  value = aws_instance.jenkins.private_ip
}

output "rds_endpoint" {
  value = aws_db_instance.mariadb.address
}