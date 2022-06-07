output "public_subnets_id" {
  value = [ aws_subnet.public_subnet[*].id]
}

output "private_subnets_id" {
  value = [ aws_subnet.private_subnet[*].id ]
}

output "security_groups_id" {
description = "The ID of the security group"
  value       = try(aws_security_group.sg.*.id, aws_security_group.sg.*.id, "")
}