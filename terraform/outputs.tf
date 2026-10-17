output "bastion_public_ip" {
  description = "Public IP address of ewb-bastion"
  value       = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Private IP address of ewb-bastion"
  value       = aws_instance.bastion.private_ip
}

output "app_a_private_ip" {
  description = "Private IP address of ewb-app-a"
  value       = aws_instance.app_a.private_ip
}

output "app_b_private_ip" {
  description = "Private IP address of ewb-app-b"
  value       = aws_instance.app_b.private_ip
}

output "peering_connection_id" {
  description = "AWS VPC Peering Connection ID"
  value       = aws_vpc_peering_connection.peering.id
}
