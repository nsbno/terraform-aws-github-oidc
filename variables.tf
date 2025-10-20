variable "github_org" {
  type        = string
  description = "The GitHub organization that owns the repositories."
  default     = "nsbno"
}

variable "environment" {
  type        = string
  description = "The environment to deploy to. Valid values: dev, test, service, stage, prod"

  validation {
    condition     = contains(["dev", "test", "stage", "prod", "service"], var.environment)
    error_message = "Invalid environment. Valid values are: dev, test, stage, prod, service."
  }
}

variable "github_oidc_provider_arn" {
  type        = string
  description = "The ARN of the GitHub OIDC provider. Used to migrate older implementations of GHA."
  default     = null
}

variable "github_repos_to_allow" {
  type        = list(string)
  description = "List of GitHub repositories that are allowed to deploy to the specified environment."
  default     = []

  validation {
    condition     = contains(var.github_repos_to_allow, "") == false
    error_message = "Repository names in github_repos_to_allow cannot be empty strings."
  }
}
