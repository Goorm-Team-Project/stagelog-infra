# 1. SQS 큐 생성
resource "aws_sqs_queue" "karpenter_interruption" {
  name                      = "stagelog-eks-karpenter"
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true
}

# 2. SQS 정책 (EventBridge가 메시지를 보낼 수 있게 허용)
resource "aws_sqs_queue_policy" "karpenter_interruption" {
  queue_url = aws_sqs_queue.karpenter_interruption.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sqs:SendMessage"
        Effect   = "Allow"
        Resource = aws_sqs_queue.karpenter_interruption.arn
        Principal = {
          Service = [
            "events.amazonaws.com",
            "sqs.amazonaws.com"
          ]
        }
      }
    ]
  })
}

# 3. EventBridge 규칙들 (Spot 중단, 인스턴스 상태 변경 등 감지)
resource "aws_cloudwatch_event_rule" "karpenter_rules" {
  for_each = {
    spot_interruption = "EC2 Spot Instance Interruption Warning"
    rebalance        = "EC2 Instance Rebalance Recommendation"
    state_change     = "EC2 Instance State-change Notification"
  }

  name        = "karpenter-${each.key}"
  description = "Karpenter interruption rule for ${each.key}"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    "detail-type" = [each.value]
  })
}

# 4. EventBridge 타겟 설정 (SQS로 보내기)
resource "aws_cloudwatch_event_target" "karpenter_rules" {
  for_each = aws_cloudwatch_event_rule.karpenter_rules

  rule      = each.value.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}