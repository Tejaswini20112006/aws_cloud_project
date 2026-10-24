variable "aws_region" {
  description = "AWS region for the application."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to tag resources."
  type        = string
  default     = "student-app"
}

variable "allowed_origin" {
  description = "Browser origin allowed to call the API."
  type        = string
  default     = "*"
}
