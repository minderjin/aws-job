############## [output] ################

output "vpc_id" {
    value = aws_vpc.this.id
}

output "public_subnet_ids" {
    value = aws_subnet.public.*.id
}

output "private_subnet_ids" {
    value = aws_subnet.private.*.id
}

output "nat_gateway_ip" {
    value = aws_eip.nat.public_ip
}

output "bastion_ip" {
    value = aws_eip.bastion.public_ip
}
