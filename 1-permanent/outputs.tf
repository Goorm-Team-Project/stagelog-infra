output "vpc_id" {
    value = aws_vpc.stagelog-vpc.id
}

output "public_subnet_ids" {
    value = {
        public-01 = aws_subnet.stagelog-subnet-public-01.id
        public-02 = aws_subnet.stagelog-subnet-public-02.id
        public-03 = aws_subnet.stagelog-subnet-public-03.id
    }
}

output "private_subnet_ids" {
    value = {
        private-01 = aws_subnet.stagelog-subnet-private-01.id
        private-02 = aws_subnet.stagelog-subnet-private-02.id
    }
}

output "private_route_table_ids" {
    value = {
        private-rtb-01 = aws_route_table.private-rtb-01.id
        private-rtb-02 = aws_route_table.private-rtb-02.id
    }
}

output "security_groups" {
    value = {
        "alb_sg" = aws_security_group.alb-sg.id
        "frontend_sg" = aws_security_group.frontend-sg.id
        "backend_sg" = aws_security_group.backend-sg.id
        "bastion_sg" = aws_security_group.bastion-sg.id
    }
}

output "iam_roles" {
    value = {
        "SSM_CloudWatchlog_Role" = aws_iam_role.SSM_CloudWatchlog_Role_Managed.id
        "Combine_SSM_CloudWatchlog_S3_Uploader" = aws_iam_role.Combine_SSM_CloudWatchlog_S3_Uploader_Managed.id
    }
}

output "iam_instance_backend_profile_name" {
    value = aws_iam_instance_profile.backend_profile.name
}

output "iam_frontend_profile_name" {
    value = aws_iam_instance_profile.frontend_profile.name
}

output "rds_endpoint" {
    description = "RDS Endpoint Address:Port"
    value = aws_db_instance.stagelog-rds-managed.endpoint
}

output "rds_address" {
    description = "RDS Address"
    value       = aws_db_instance.stagelog-rds-managed.address
}