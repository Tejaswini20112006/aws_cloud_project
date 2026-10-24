provider "aws" {
  region = var.aws_region
  default_tags { tags = { Project = var.project_name, ManagedBy = "Terraform" } }
}

data "aws_caller_identity" "current" {}
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../lambda/app.py"
  output_path = "${path.module}/student_api.zip"
}

resource "random_id" "suffix" { byte_length = 4 }

resource "aws_dynamodb_table" "students" {
  name         = "${var.project_name}-students-${random_id.suffix.hex}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "student_id"
  attribute {
    name = "student_id"
    type = "S"
  }
  point_in_time_recovery { enabled = true }
  server_side_encryption { enabled = true }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.project_name}-lambda-${random_id.suffix.hex}"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }] })
}
resource "aws_iam_role_policy" "lambda" {
  name = "${var.project_name}-dynamodb-access"
  role = aws_iam_role.lambda.id
  policy = jsonencode({ Version = "2012-10-17", Statement = [
    { Effect = "Allow", Action = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:DeleteItem", "dynamodb:Scan"], Resource = aws_dynamodb_table.students.arn },
    { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = "arn:aws:logs:*:*:*" }
  ] })
}
resource "aws_lambda_function" "api" {
  function_name    = "${var.project_name}-api-${random_id.suffix.hex}"
  role             = aws_iam_role.lambda.arn
  handler          = "app.handler"
  runtime          = "python3.12"
  timeout          = 15
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  environment { variables = { TABLE_NAME = aws_dynamodb_table.students.name, ALLOWED_ORIGIN = var.allowed_origin } }
}

resource "aws_apigatewayv2_api" "http" {
  name          = "${var.project_name}-http-${random_id.suffix.hex}"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = [var.allowed_origin]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["content-type"]
    max_age       = 300
  }
}
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}
resource "aws_apigatewayv2_route" "routes" {
  for_each  = toset(["GET /students", "POST /students", "GET /students/{id}", "PUT /students/{id}", "DELETE /students/{id}"])
  api_id    = aws_apigatewayv2_api.http.id
  route_key = each.value
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true
}
resource "aws_lambda_permission" "api" {
  statement_id  = "AllowHttpApiInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

resource "aws_s3_bucket" "web" {
  bucket        = "${var.project_name}-web-${data.aws_caller_identity.current.account_id}-${random_id.suffix.hex}"
  force_destroy = true
}
resource "aws_s3_bucket_public_access_block" "web" {
  bucket                  = aws_s3_bucket.web.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
resource "aws_s3_bucket_website_configuration" "web" {
  bucket = aws_s3_bucket.web.id
  index_document { suffix = "index.html" }
  error_document { key = "index.html" }
}
resource "aws_s3_bucket_policy" "web" {
  bucket     = aws_s3_bucket.web.id
  depends_on = [aws_s3_bucket_public_access_block.web]
  policy     = jsonencode({ Version = "2012-10-17", Statement = [{ Sid = "PublicReadForStaticSite", Effect = "Allow", Principal = "*", Action = ["s3:GetObject"], Resource = "${aws_s3_bucket.web.arn}/*" }] })
}
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.web.id
  key          = "index.html"
  content      = replace(file("${path.module}/../web/index.html"), "__API_URL__", aws_apigatewayv2_api.http.api_endpoint)
  etag         = md5(replace(file("${path.module}/../web/index.html"), "__API_URL__", aws_apigatewayv2_api.http.api_endpoint))
  content_type = "text/html; charset=utf-8"
}



