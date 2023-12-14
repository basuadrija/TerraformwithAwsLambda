
provider "aws" {
  region = "ap-south-1"
  access_key  = var.AWS_ACCESS_KEY_ID
  secret_key  = var.AWS_SECRET_ACCESS_KEY
}

resource "aws_instance" "ec2" {
  count                  = var.instance_count
  ami                    = "ami-02a2af70a66af6dfb"  
  instance_type          = "t2.micro"  # Update with your desired instance type
  vpc_security_group_ids = [var.security_group_id]
  subnet_id              = var.subnet_id
  key_name               = var.key
  tags = merge(var.default_ec2_tags,
    {
      Name = "${var.name}-${count.index + 1}"
    }
  )
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_policy" "lambda_policy_start_stop_instance" {
  name        = "lambda_policy_start_stop_instance"
  path        = "/"
  description = "My test policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:Start*",
                "ec2:Stop*",
                "ec2:Describe*"
            ],
            "Resource": "*"
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy_start_stop_instance.arn
}


resource "aws_lambda_function" "stop_ec2_instance" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "stopec2instance.zip"
  function_name = "stop_ec2_instance"
  role          =  aws_iam_role.lambda_role.arn
  handler       = "stopec2instance.lambda_handler"
  source_code_hash = filebase64sha256("stopec2instance.zip")

  runtime = "python3.11"
}

resource "aws_lambda_function" "start_ec2_instance" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "startec2instance.zip"
  function_name = "startec2instance"
  role          =  aws_iam_role.lambda_role.arn
  handler       = "startec2instance.lambda_handler"
  source_code_hash = filebase64sha256("startec2instance.zip")

  runtime = "python3.11"
}


resource "aws_cloudwatch_event_rule" "stop_ec2_schedule" {
  name                = "stop_ec2_schedule"
  description         = "Schedule to trigger Lambda to stop EC2 instances on Friday at 10.30 PM IST"
  schedule_expression = "cron(0 17 ? * 6 *)"  
}

resource "aws_cloudwatch_event_target" "stop_ec2_target" {
  rule      = aws_cloudwatch_event_rule.stop_ec2_schedule.name
  target_id = "lambda"
  arn       = aws_lambda_function.stop_ec2_instance.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_stop" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_ec2_instance.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_ec2_schedule.arn
}

resource "aws_cloudwatch_event_rule" "start_ec2_schedule" {
  name                = "start_ec2_schedule"
  description         = "Schedule to trigger Lambda to start EC2 instances on Monday at 8 AM IST"
  schedule_expression = "cron(30 2 ? * 2 *)" 
}

resource "aws_cloudwatch_event_target" "start_ec2_target" {
  rule      = aws_cloudwatch_event_rule.start_ec2_schedule.name
  target_id = "lambda"
  arn       = aws_lambda_function.start_ec2_instance.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_start" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_ec2_instance.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_ec2_schedule.arn
}
