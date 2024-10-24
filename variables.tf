variable "role_name" {
  description = "The name of the IAM role used by GitHub Actions."
  type        = string
  default     = "github_actions_assume_role"
}

variable "allowed_s3_write_arns" {
  description = "S3 bucket ARNs the role can write to."
  default     = []
  type        = list(string)
}

variable "allowed_s3_read_arns" {
  description = "S3 bucket ARNs the role can read from."
  default     = []
  type        = list(string)
}

variable "allowed_ecr_arns" {
  description = "ECR repository ARNs the role can publish images to."
  default     = []
  type        = list(string)
}

variable "allowed_ecs_arns" {
  description = "ECS clusters ARNs the role can update task definitions and services of."
}

variable "github_repositories" {
  description = "A list of repositories that the OIDC role can access"
  default     = []
  type        = list(string)
}
