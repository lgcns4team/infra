output "packer_vpc_id" {
  value = aws_vpc.packer.id
}

output "packer_subnet_id" {
  value = aws_subnet.packer_public.id
}