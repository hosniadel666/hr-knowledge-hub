data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../lambda/index.py"
  output_path = "${path.module}/../lambda/lambda.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.name_prefix}-query"
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_lambda_function" "query" {
  function_name    = "${local.name_prefix}-query"
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 256
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      KNOWLEDGE_BASE_ID    = aws_bedrockagent_knowledge_base.hr_kb.id
      FOUNDATION_MODEL_ARN = local.foundation_model_arn
      REGION               = var.region
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
  tags       = var.tags
}
