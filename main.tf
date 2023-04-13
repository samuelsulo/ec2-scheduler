locals {
  schedules = [
    {
      name                = var.schedule_start_instances_name
      role_name           = var.schedule_start_instances_name
      schedule_expression = "cron(0 9 ? * MON-FRI *)"
      action              = "start"
    },
    {
      name                = var.schedule_stop_instances_name
      role_name           = var.schedule_stop_instances_name
      schedule_expression = "cron(0 13 ? * MON-FRI *)"
      action              = "stop"
    }
  ]
}

resource "aws_scheduler_schedule" "this" {
  count = length(local.schedules)

  name       = local.schedules[count.index].name
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = local.schedules[count.index].schedule_expression

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:lambda:invoke"
    role_arn = aws_iam_role.this[count.index].arn

    input = jsonencode({
      FunctionName   = ""
      InvocationType = "Event"
      Payload = jsonencode({
        action = local.schedules[count.index].action
      })
    })
  }
}

resource "aws_iam_role" "this" {
  count = length(local.schedules)

  name               = local.schedules[count.index].name
  assume_role_policy = data.aws_iam_policy_document.events_assume_role.json

  inline_policy {
    name   = "InvokeScheduler"
    policy = data.aws_iam_policy_document.invoke_scheduler.json
  }

  tags = {
    Name = local.schedules[count.index].name
  }
}

data "aws_iam_policy_document" "events_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "invoke_scheduler" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:Invoke"
    ]

    resources = [
      "arn:aws:lambda:*:*:function:*"
    ]
  }
}
