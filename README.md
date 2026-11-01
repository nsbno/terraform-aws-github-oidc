# OIDC Role for GitHub Actions

A module to help you configure an OIDC role to use with GitHub Actions. The role is created in the AWS account where the module is applied, and has `AdministratorAccess` minus a set of explicit Deny statements.

## Example Usage

```terraform
module "oidc_role" {
  source = "github.com/nsbno/terraform-aws-github-oidc?ref=x.y.z"

  environment = var.environment

  # To restrict which repositories can assume the role, provide a list here.
  # github_repos_to_allow = ["infrademo-aws", "infrademo-service"]
}
```

## Guardrails

The role has guardrails (a Deny policy) around dangerous operations, such as changing the AWS Organization or account, Identity Center, audit and security tooling, and the role's own guardrails. See `main.tf` for the exact list.

> [!NOTE]
> Changes to the Deny policy itself must be applied by another principal, for example an Identity Center administrator role.

> [!NOTE]
> These guardrails are defense-in-depth. AWS recommends enforcing account and organization guardrails with Service Control Policies at the organization root.
