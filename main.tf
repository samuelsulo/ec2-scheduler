locals {
  schedules = [
    {
      name                = var.schedule_start_instances_name
      role_name           = var.schedule_start_instances_name
      schedule_expression = "cron(0 9 ? * MON-FRI *)"
      payload = jsonencode({
        action   = "start"
        schedule = "office-hours"
      })
    },
    {
      name                = var.schedule_stop_instances_name
      role_name           = var.schedule_stop_instances_name
      schedule_expression = "cron(0 13 ? * MON-FRI *)"
      payload = jsonencode({
        action   = "stop"
        schedule = "office-hours"
      })
    }
  ]
}

module "lambda_instance_scheduler" {
  source = "../terraform-aws-lambda"

  function_name = "instance-scheduler"
  description   = "Start/Stop EC2 instances based on schedule."
  root_dir      = "${path.module}/lambdas/instance-scheduler"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  build_command = "yarn build"

  files_to_watch = [
    "src/**/*.ts",
    "package.json",
    "yarn.lock",
    "tsconfig.json"
  ]

  inline_policies = [
    {
      name = "EC2Access"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "ec2:DescribeInstances",
              "ec2:StartInstances",
              "ec2:StopInstances"
            ]
            Resource = "*"
          }
        ]
      })
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
      FunctionName   = module.lambda_instance_scheduler.arn
      InvocationType = "Event"
      Payload        = local.schedules[count.index].payload
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
      module.lambda_instance_scheduler.arn
    ]
  }
}
