variable "region" {
  description = "The AWS region the aws provider uses."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "The name Act shows for the deployment."
  type        = string
  default     = "payments-prod"
}
