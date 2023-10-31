output "vpc_id" {
  description = "IDs of the VPC'"
  value       = aws_vpc.abb_vpc.id
}

output "subnets_public" {
  description = "IDs of public subnets"
  value       = aws_subnet.public.*.id
}

output "subnets_private" {
  description = "IDs of private subnets"
  value       = aws_subnet.private.*.id
}

output "private_subnet_cidrs" {
  value = aws_subnet.private.*.cidr_block
}
