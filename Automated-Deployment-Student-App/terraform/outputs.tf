output "website_url" {
  description = "Public static website URL."
  value       = "http://${aws_s3_bucket_website_configuration.web.website_endpoint}"
}

output "api_url" {
  description = "HTTP API base URL."
  value       = aws_apigatewayv2_api.http.api_endpoint
}

output "students_table" {
  value = aws_dynamodb_table.students.name
}
