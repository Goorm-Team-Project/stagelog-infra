# NOTE:
# Existing RDS is intentionally unmanaged by Terraform in this stack.
#
# Reason:
# - We keep the DB running as-is and prevent accidental modify/destroy from this state.
# - The previous resources were detached from state with:
#   terraform state rm aws_db_instance.stagelog-rds-managed aws_db_subnet_group.stagelog-db-subnet-group
#
# If you decide to manage DB by Terraform again later,
# re-add aws_db_subnet_group/aws_db_instance resources in this file.
