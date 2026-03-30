output "bastion_instance_id" {
  value = aws_instance.stagelog_bastion.id
}

output "bastion_public_ip" {
  value = aws_instance.stagelog_bastion.public_ip
}

output "rds_address" {
  value = data.terraform_remote_state.permanent.outputs.rds_address
}
