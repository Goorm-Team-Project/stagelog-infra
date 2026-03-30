variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "instance_type" {
  description = "Bastion instance type"
  type        = string
  default     = "t3.micro"
}

variable "bastion_name" {
  description = "Bastion EC2 Name tag"
  type        = string
  default     = "stagelog-bastion-ssm"
}
