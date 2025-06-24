variable "github_org" {
  type        = string
  description = "The GitHub organization that owns the repositories."
  default     = "nsbno"
}

variable "environment" {
  type        = string
  description = "The environment to deploy to. Valid values: test, service, stage, prod"
}

variable "oidc_assume_role_arn" {
  type        = string
  description = "The ARN of the OIDC role to assume for GitHub Actions. Used to migrate older implementations of GHA."
  default     = null
}
