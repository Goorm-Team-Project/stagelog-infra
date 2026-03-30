output "backend_workload_role_arn" {
  description = "Legacy combined backend workload IAM role ARN"
  value       = aws_iam_role.backend_workload.arn
}

output "posts_workload_role_arn" {
  description = "Posts API workload IAM role ARN"
  value       = aws_iam_role.posts_workload.arn
}

output "notifications_api_workload_role_arn" {
  description = "Notifications API workload IAM role ARN"
  value       = aws_iam_role.notifications_api_workload.arn
}

output "notifications_consumer_workload_role_arn" {
  description = "Notifications consumer workload IAM role ARN"
  value       = aws_iam_role.notifications_consumer_workload.arn
}

output "outbox_worker_workload_role_arn" {
  description = "Outbox worker workload IAM role ARN"
  value       = aws_iam_role.outbox_worker_workload.arn
}
