variable "github_org" {
  type        = string
  description = "The GitHub organization that owns the repositories."
  default     = "nsbno"
}

variable "environment" {
  type        = string
  description = "The environment to deploy to. Valid values: test, service, stage, prod"
}
