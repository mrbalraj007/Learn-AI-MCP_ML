# CloudWatch Monitoring Module
# File: terraform/modules/cloudwatch/main.tf
#
# Purpose: Create CloudWatch monitoring, alarms, and dashboards
# Features: EC2 monitoring, SNS alerts, custom metrics, dashboards

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# SNS Topic for Alerts
resource "aws_sns_topic" "monitoring_alerts" {
  name              = "${var.environment}-${var.project_name}-alerts"
  display_name      = "${upper(var.environment)} - ${var.project_name} Infrastructure Alerts"
  kms_master_key_id = var.sns_kms_key_id

  tags = {
    Name        = "${var.environment}-${var.project_name}-sns-topic"
    Environment = var.environment
    Project     = var.project_name
  }
}

# SNS Topic Policy for CloudWatch
resource "aws_sns_topic_policy" "monitoring_alerts" {
  arn = aws_sns_topic.monitoring_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.monitoring_alerts.arn
      }
    ]
  })
}

# SNS Topic Subscription (Email)
resource "aws_sns_topic_subscription" "monitoring_alerts_email" {
  count     = var.alert_email != null ? 1 : 0
  topic_arn = aws_sns_topic.monitoring_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Log Group for EC2 System Logs
resource "aws_cloudwatch_log_group" "ec2_system_logs" {
  name              = "/aws/ec2/${var.environment}-${var.project_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.environment}-${var.project_name}-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Metric Alarm - High CPU Utilization
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_utilization" {
  alarm_name          = "${var.environment}-${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "Alert when EC2 CPU exceeds ${var.cpu_threshold}%"
  alarm_actions       = [aws_sns_topic.monitoring_alerts.arn]
  ok_actions          = [aws_sns_topic.monitoring_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = "All"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Metric Alarm - Status Check Failed
resource "aws_cloudwatch_metric_alarm" "ec2_status_check_failed" {
  alarm_name          = "${var.environment}-${var.project_name}-status-check-failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "Alert when EC2 status check fails"
  alarm_actions       = [aws_sns_topic.monitoring_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = "All"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Metric Alarm - Network In
resource "aws_cloudwatch_metric_alarm" "ec2_network_in" {
  alarm_name          = "${var.environment}-${var.project_name}-high-network-in"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Sum"
  threshold           = var.network_in_threshold
  alarm_description   = "Alert when network inbound exceeds threshold"
  alarm_actions       = [aws_sns_topic.monitoring_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = "All"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Metric Alarm - Disk Usage (Custom Metric)
resource "aws_cloudwatch_metric_alarm" "ec2_disk_usage" {
  count               = var.enable_disk_monitoring ? 1 : 0
  alarm_name          = "${var.environment}-${var.project_name}-high-disk-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DiskUsagePercent"
  namespace           = "CustomEC2Metrics"
  period              = 300
  statistic           = "Average"
  threshold           = var.disk_usage_threshold
  alarm_description   = "Alert when disk usage exceeds ${var.disk_usage_threshold}%"
  alarm_actions       = [aws_sns_topic.monitoring_alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "infrastructure" {
  dashboard_name = "${var.environment}-${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average" }],
            [".", "NetworkIn", { stat = "Sum" }],
            [".", "NetworkOut", { stat = "Sum" }],
            [".", "StatusCheckFailed", { stat = "Maximum" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 Instance Metrics"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type = "log"
        properties = {
          query   = "fields @timestamp, @message | stats count() by @message | limit 20"
          region  = var.aws_region
          title   = "Recent Log Events"
          queryId = "logs-insights-query-1"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "DiskReadBytes", { stat = "Sum" }],
            [".", "DiskWriteBytes", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Disk I/O Performance"
        }
      }
    ]
  })
}

# IAM Role for EC2 CloudWatch Agent
resource "aws_iam_role" "ec2_cloudwatch_role" {
  count = var.enable_cloudwatch_agent ? 1 : 0
  name  = "${var.environment}-${var.project_name}-ec2-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attach CloudWatch Agent Policy
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_policy" {
  count      = var.enable_cloudwatch_agent ? 1 : 0
  role       = aws_iam_role.ec2_cloudwatch_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# IAM Instance Profile for EC2
resource "aws_iam_instance_profile" "ec2_cloudwatch_profile" {
  count = var.enable_cloudwatch_agent ? 1 : 0
  name  = "${var.environment}-${var.project_name}-ec2-cloudwatch-profile"
  role  = aws_iam_role.ec2_cloudwatch_role[0].name
}

# CloudWatch Event Rule for EC2 State Changes
resource "aws_cloudwatch_event_rule" "ec2_state_change" {
  name        = "${var.environment}-${var.project_name}-ec2-state-change"
  description = "Capture EC2 instance state changes"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
    detail = {
      state = ["pending", "running", "stopping", "stopped", "shutting-down", "terminated"]
    }
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Event Target - SNS
resource "aws_cloudwatch_event_target" "ec2_state_change_sns" {
  rule      = aws_cloudwatch_event_rule.ec2_state_change.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.monitoring_alerts.arn

  input_transformer = {
    input_paths = {
      instance_id = "$.detail.instance-id"
      state       = "$.detail.state"
      time        = "$.time"
    }
    input_template = "\"EC2 Instance <instance_id> changed to state: <state> at <time>\""
  }
}

# CloudWatch Composite Alarm
resource "aws_cloudwatch_composite_alarm" "infrastructure_health" {
  count          = var.enable_composite_alarm ? 1 : 0
  alarm_name     = "${var.environment}-${var.project_name}-infrastructure-health"
  alarm_description = "Composite alarm for overall infrastructure health"
  actions_enabled = true
  alarm_actions  = [aws_sns_topic.monitoring_alerts.arn]

  alarm_rule = join(" OR ", [
    "arn:aws:cloudwatch:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.ec2_cpu_utilization.alarm_name}",
    "arn:aws:cloudwatch:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.ec2_status_check_failed.alarm_name}"
  ])

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Get current AWS account
data "aws_caller_identity" "current" {}
