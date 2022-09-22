variable "aws_region" {
  type = string
}
variable "aws_access_key" {
  type = string
}
variable "aws_secret_key" {
  type = string
}
variable "api_gateway_path" {
  type = string
}
variable "lambda_function_name" {
  default = "github_webhook"
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region  = var.aws_region
}

resource "aws_iam_role" "iam_for_github_webhook" {
  name = "${var.lambda_function_name}_iam"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "github_webhook" {
  filename      = "../src/lambda.zip"
  function_name = var.lambda_function_name
  role          = aws_iam_role.iam_for_github_webhook.arn
  handler       = "index.handler"
  source_code_hash = filebase64sha256("../src/lambda.zip")
  runtime = "nodejs16.x"

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs_github_webhook,
    aws_cloudwatch_log_group.github_webhook,
  ]
}

resource "aws_cloudwatch_log_group" "github_webhook" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "lambda_logging_github_webhook" {
  name        = "${var.lambda_function_name}_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs_github_webhook" {
  role       = aws_iam_role.iam_for_github_webhook.name
  policy_arn = aws_iam_policy.lambda_logging_github_webhook.arn
}

resource "aws_api_gateway_rest_api" "github_webhook" {
  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "${var.lambda_function_name}_api_gateway"
      version = "1.0"
    }
    paths = {
      "/${var.api_gateway_path}" = {
        post = {
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "aws_proxy"
            uri                  = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.github_webhook.arn}/invocations"
          }
        }
      }
    }
  })

  name = var.lambda_function_name

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "github_webhook" {
  rest_api_id = aws_api_gateway_rest_api.github_webhook.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.github_webhook.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "github_webhook" {
  deployment_id = aws_api_gateway_deployment.github_webhook.id
  rest_api_id   = aws_api_gateway_rest_api.github_webhook.id
  stage_name    = var.lambda_function_name
}

resource "aws_lambda_permission" "github_webhook" {
  statement_id  = "AllowAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.github_webhook.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.github_webhook.execution_arn}/*/*/${var.api_gateway_path}"
}