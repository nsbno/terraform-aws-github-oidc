variable "github_org" {
  type        = string
  description = "The GitHub organization that owns the repositories."
  default     = "nsbno"
}

variable "github_org_id" {
  type        = string
  description = "The immutable GitHub organization ID for github_org. Needed to match GitHub's immutable OIDC subject claim format (repo:org@org_id/repo@repo_id), which new/renamed repos use."
  default     = "21105515"
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

variable "disable_guardrails" {
  type        = bool
  default     = false
  description = "DANGEROUS OPERATION! Will allow GitHub Actions to run as unrestricted Administrator. Only enable temporarily, and with a very good reason"
}
