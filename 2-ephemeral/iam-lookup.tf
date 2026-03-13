data "aws_iam_role" "eks_role" {
  name = data.terraform_remote_state.permanent.outputs.iam_roles["EKS_Role"]
}

data "aws_iam_role" "eks_node_group_role" {
  name = data.terraform_remote_state.permanent.outputs.iam_roles["EKS_node_group_Role"]
}
