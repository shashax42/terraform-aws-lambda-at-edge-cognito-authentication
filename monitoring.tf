# ================================================================================================================
# Enhanced Monitoring and Observability
# ================================================================================================================

# SNS Topic for alarm notifications
resource "aws_sns_topic" "lambda_alerts" {
  count = var.enable_enhanced_monitoring && length(var.alarm_notification_emails) > 0 ? 1 : 0
  name  = "${var.name}-lambda-edge-alerts"

  tags = merge(var.tags, {
    Purpose = "Lambda@Edge Alert Notifications"
    Module  = "terraform-aws-lambda-at-edge-cognito-authentication"
  })
}

resource "aws_sns_topic_subscription" "email_alerts" {
  count     = var.enable_enhanced_monitoring && length(var.alarm_notification_emails) > 0 ? length(var.alarm_notification_emails) : 0
  topic_arn = aws_sns_topic.lambda_alerts[0].arn
  protocol  = "email"
  endpoint  = var.alarm_notification_emails[count.index]
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "lambda_edge_dashboard" {
  count          = var.enable_enhanced_monitoring ? 1 : 0
  dashboard_name = "${var.name}-lambda-edge-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.cloudfront_auth_edge.function_name],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."],
            [".", "Throttles", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Lambda@Edge Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.cloudfront_auth_edge.function_name],
            [".", "Invocations", ".", "."]
          ]
          view   = "singleValue"
          region = "us-east-1"
          title  = "Error Rate"
          period = 300
          stat   = "Sum"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 24
        height = 6
        properties = {
          query  = "SOURCE '/aws/lambda/us-east-1.${aws_lambda_function.cloudfront_auth_edge.function_name}'\n| fields @timestamp, @message\n| filter @message like /ERROR/\n| sort @timestamp desc\n| limit 100"
          region = "us-east-1"
          title  = "Recent Errors"
          view   = "table"
        }
      }
    ]
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "lambda_error_rate" {
  count               = var.enable_enhanced_monitoring ? 1 : 0
  alarm_name          = "${var.name}-lambda-edge-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.error_rate_threshold
  alarm_description   = "This metric monitors lambda error rate"
  alarm_actions       = length(var.alarm_notification_emails) > 0 ? [aws_sns_topic.lambda_alerts[0].arn] : []
  ok_actions          = length(var.alarm_notification_emails) > 0 ? [aws_sns_topic.lambda_alerts[0].arn] : []

  dimensions = {
    FunctionName = aws_lambda_function.cloudfront_auth_edge.function_name
  }

  tags = merge(var.tags, {
    Purpose = "Lambda@Edge Error Rate Monitoring"
    Module  = "terraform-aws-lambda-at-edge-cognito-authentication"
  })
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  count               = var.enable_enhanced_monitoring ? 1 : 0
  alarm_name          = "${var.name}-lambda-edge-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = var.duration_threshold_ms
  alarm_description   = "This metric monitors lambda execution duration"
  alarm_actions       = length(var.alarm_notification_emails) > 0 ? [aws_sns_topic.lambda_alerts[0].arn] : []
  ok_actions          = length(var.alarm_notification_emails) > 0 ? [aws_sns_topic.lambda_alerts[0].arn] : []

  dimensions = {
    FunctionName = aws_lambda_function.cloudfront_auth_edge.function_name
  }

  tags = merge(var.tags, {
    Purpose = "Lambda@Edge Duration Monitoring"
    Module  = "terraform-aws-lambda-at-edge-cognito-authentication"
  })
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  count               = var.enable_enhanced_monitoring ? 1 : 0
  alarm_name          = "${var.name}-lambda-edge-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors lambda throttles"
  alarm_actions       = length(var.alarm_notification_emails) > 0 ? [aws_sns_topic.lambda_alerts[0].arn] : []
  ok_actions          = length(var.alarm_notification_emails) > 0 ? [aws_sns_topic.lambda_alerts[0].arn] : []

  dimensions = {
    FunctionName = aws_lambda_function.cloudfront_auth_edge.function_name
  }

  tags = merge(var.tags, {
    Purpose = "Lambda@Edge Throttle Monitoring"
    Module  = "terraform-aws-lambda-at-edge-cognito-authentication"
  })
}

# Custom CloudWatch Log Group with retention
resource "aws_cloudwatch_log_group" "lambda_edge_logs" {
  count             = var.enable_enhanced_monitoring ? 1 : 0
  name              = "/aws/lambda/us-east-1.${aws_lambda_function.cloudfront_auth_edge.function_name}"
  retention_in_days = 14

  tags = merge(var.tags, {
    Purpose = "Lambda@Edge Logs"
    Module  = "terraform-aws-lambda-at-edge-cognito-authentication"
  })
}

# CloudWatch Insights Queries (saved queries for common investigations)
resource "aws_cloudwatch_query_definition" "error_analysis" {
  count = var.enable_enhanced_monitoring ? 1 : 0
  name  = "${var.name}-lambda-edge-error-analysis"

  log_group_names = [
    "/aws/lambda/us-east-1.${aws_lambda_function.cloudfront_auth_edge.function_name}"
  ]

  query_string = <<EOF
fields @timestamp, @message, @requestId
| filter @message like /ERROR/
| stats count() by bin(5m)
| sort @timestamp desc
EOF
}

resource "aws_cloudwatch_query_definition" "performance_analysis" {
  count = var.enable_enhanced_monitoring ? 1 : 0
  name  = "${var.name}-lambda-edge-performance-analysis"

  log_group_names = [
    "/aws/lambda/us-east-1.${aws_lambda_function.cloudfront_auth_edge.function_name}"
  ]

  query_string = <<EOF
fields @timestamp, @duration, @billedDuration, @memorySize, @maxMemoryUsed
| filter @type = "REPORT"
| stats avg(@duration), max(@duration), min(@duration) by bin(5m)
| sort @timestamp desc
EOF
}

# X-Ray Tracing (optional)
resource "aws_lambda_function" "cloudfront_auth_edge_with_tracing" {
  count         = var.enable_enhanced_monitoring ? 0 : 0 # Disabled for now as Lambda@Edge has limitations
  function_name = "${var.name}-edge-auth"

  tracing_config {
    mode = "Active"
  }
}
