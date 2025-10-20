variable "github_org" {
  type        = string
  description = "The GitHub organization that owns the repositories."
  default     = "nsbno"
}

variable "environment" {
  type        = string
  description = "The environment to deploy to. Valid values: test, service, stage, prod"
}

variable "github_oidc_provider_arn" {
  type        = string
  description = "The ARN of the GitHub OIDC provider. Used to migrate older implementations of GHA."
  default     = null
}

variable "github_repo_list_to_allow" {
  type        = list(string)
  description = "List of GitHub repositories that are allowed to deploy to the specified environment. Format: owner/repo"
  default     = []
}
