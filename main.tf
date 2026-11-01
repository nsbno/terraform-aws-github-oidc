terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_iam_openid_connect_provider" "this" {
  count = var.github_oidc_provider_arn != null ? 0 : 1

  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]
  thumbprint_list = [
    # From this GitHub blog:
    # https://github.blog/changelog/2023-06-27-github-actions-update-on-oidc-integration-with-aws/
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

locals {
  environment_mapping = {
    dev     = "Development",
    test    = "Test",
    stage   = "Stage"
    prod    = "Production"
    service = "Service"
  }

  # GitHub now issues OIDC tokens with an immutable-ID subject claim
  # (repo:org@org_id/repo@repo_id:...) for new and renamed repos, alongside
  # the legacy name-based claim (repo:org/repo:...). We match both so trust
  # doesn't depend on when a repo was created or last renamed. See:
  # https://github.blog/changelog/2026-04-23-immutable-subject-claims-for-github-actions-oidc-tokens/
  allowed_git_repos = length(var.github_repos_to_allow) == 0 ? [
    "repo:${var.github_org}/*:environment:${local.environment_mapping[var.environment]}",
    "repo:${var.github_org}@${var.github_org_id}/*:environment:${local.environment_mapping[var.environment]}",
    ] : flatten([
      for repo in var.github_repos_to_allow : [
        "repo:${var.github_org}/${repo}:environment:${local.environment_mapping[var.environment]}",
        "repo:${var.github_org}@${var.github_org_id}/${repo}@*:environment:${local.environment_mapping[var.environment]}",
      ]
  ])
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = var.github_oidc_provider_arn != null ? [var.github_oidc_provider_arn] : [aws_iam_openid_connect_provider.this[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.allowed_git_repos
    }
  }
}

resource "aws_iam_role" "this" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  path               = local.management_iam_path
  name               = "deployment"
}

data "aws_caller_identity" "current" {}

locals {
  management_iam_path            = "/__management__/"
  denied_permissions_policy_name = "deployment-denied-permissions"
  # Built by hand instead of referencing aws_iam_policy.denied_permissions.arn,
  # since the policy document refers to its own ARN.
  denied_permissions_policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy${local.management_iam_path}${local.denied_permissions_policy_name}"
}

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.this.name
}

data "aws_iam_policy_document" "denied_permissions" {
  statement {
    sid    = "DenyOrganizationEdits"
    effect = "Deny"
    actions = [
      "organizations:InviteAccountToOrganization",
      "organizations:DeclineHandshake",
      "organizations:DeletePolicy",
      "organizations:TerminateResponsibilityTransfer",
      "organizations:CreateAccount",
      "organizations:DeleteOrganization",
      "organizations:UpdateResponsibilityTransfer",
      "organizations:DeleteResourcePolicy",
      "organizations:EnableAWSServiceAccess",
      "organizations:CloseAccount",
      "organizations:CreateGovCloudAccount",
      "organizations:EnableAllFeatures",
      "organizations:EnablePolicyType",
      "organizations:UpdatePolicy",
      "organizations:AttachPolicy",
      "organizations:RegisterDelegatedAdministrator",
      "organizations:MoveAccount",
      "organizations:CreatePolicy",
      "organizations:CreateOrganization",
      "organizations:DisableAWSServiceAccess",
      "organizations:DetachPolicy",
      "organizations:DeleteOrganizationalUnit",
      "organizations:DisablePolicyType",
      "organizations:AcceptHandshake",
      "organizations:CancelHandshake",
      "organizations:LeaveOrganization",
      "organizations:RemoveAccountFromOrganization",
      "organizations:UpdateOrganizationalUnit",
      "organizations:PutResourcePolicy",
      "organizations:CreateOrganizationalUnit",
      "organizations:DeregisterDelegatedAdministrator",
      "organizations:InviteOrganizationToTransferResponsibility"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyAccountEdits"
    effect = "Deny"
    actions = [
      "account:SendPhoneNumberVerification",
      "account:PutContactInformation",
      "account:ReopenAccount",
      "account:EnableRegion",
      "account:DisableRegion",
      "account:DeleteAlternateContact",
      "account:VerifyPhoneNumber",
      "account:CloseAccount",
      "account:StartPrimaryEmailUpdate",
      "account:PutAlternateContact",
      "account:AcceptPrimaryEmailUpdate",
      "account:PutAccountName",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyIdentityCenterAdmin"
    effect = "Deny"
    actions = [
      "sso:CreateInstance",
      "sso:DeleteInstance",
      "sso:UpdateInstance",
      "sso:CreatePermissionSet",
      "sso:UpdatePermissionSet",
      "sso:DeletePermissionSet",
      "sso:CreateAccountAssignment",
      "sso:DeleteAccountAssignment",
      "sso:AttachManagedPolicyToPermissionSet",
      "sso:DetachManagedPolicyFromPermissionSet",
      "sso:AttachCustomerManagedPolicyReferenceToPermissionSet",
      "sso:DetachCustomerManagedPolicyReferenceFromPermissionSet",
      "sso:PutInlinePolicyToPermissionSet",
      "sso:DeleteInlinePolicyFromPermissionSet",
      "sso:PutPermissionsBoundaryToPermissionSet",
      "sso:DeletePermissionsBoundaryFromPermissionSet",
      "sso:ProvisionPermissionSet",
      "sso:CreateApplication",
      "sso:DeleteApplication",
      "sso:CreateApplicationAssignment",
      "sso:DeleteApplicationAssignment",
      "sso:CreateTrustedTokenIssuer",
      "sso:DeleteTrustedTokenIssuer",
      "sso-directory:*",
      "identitystore:Create*",
      "identitystore:Update*",
      "identitystore:Delete*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyModifySSORoles"
    effect = "Deny"
    actions = [
      "iam:DeleteRole",
      "iam:UpdateRole",
      "iam:UpdateRoleDescription",
      "iam:UpdateAssumeRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:PutRolePermissionsBoundary",
      "iam:DeleteRolePermissionsBoundary",
      "iam:TagRole",
      "iam:UntagRole",
    ]
    # Identity Center roles live under /aws-reserved/sso.amazonaws.com/, with an
    # extra region segment outside us-east-1. The trailing wildcard covers both.
    resources = ["arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/*"]
  }

  # SAML provider configured and managed by Identity Center
  statement {
    sid    = "DenyModifySSOIdentityProviders"
    effect = "Deny"
    actions = [
      "iam:CreateSAMLProvider",
      "iam:UpdateSAMLProvider",
      "iam:DeleteSAMLProvider",
    ]
    resources = ["arn:aws:iam::*:saml-provider/AWSSSO_*"]
  }

  # The role may otherwise modify itself, but must not be able to detach this
  # policy. IAM can scope DetachRolePolicy to a policy ARN, which is why this is
  # a managed policy and not an inline one.
  statement {
    sid       = "ProtectOwnDeniedPermissionsAttachment"
    effect    = "Deny"
    actions   = ["iam:DetachRolePolicy"]
    resources = [aws_iam_role.this.arn]

    condition {
      test     = "ArnEquals"
      variable = "iam:PolicyARN"
      values   = [local.denied_permissions_policy_arn]
    }
  }

  # If the IAM Role is allowed to modify the denied permissions,
  # then there is no point in having it.
  statement {
    sid    = "ProtectDeniedPermissionsPolicy"
    effect = "Deny"
    actions = [
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion",
    ]
    resources = [local.denied_permissions_policy_arn]
  }

  statement {
    sid    = "ProtectOwnRoleDeletion"
    effect = "Deny"
    actions = [
      "iam:DeleteRole", // Could cause some problems if we want to delete the role, but we can temporary disable it in that case
    ]
    resources = [aws_iam_role.this.arn]
  }

  statement {
    sid    = "DenyAuditAndSecurityToolingTampering"
    effect = "Deny"
    actions = [
      "cloudtrail:StopLogging",
      "cloudtrail:DeleteTrail",
      "cloudtrail:UpdateTrail",
      "cloudtrail:PutEventSelectors",
      "cloudtrail:PutInsightSelectors",
      "cloudtrail:DeleteEventDataStore",
      "config:StopConfigurationRecorder",
      "config:DeleteConfigurationRecorder",
      "config:DeleteDeliveryChannel",
      "guardduty:DeleteDetector",
      "guardduty:UpdateDetector",
      "guardduty:DisassociateFromMasterAccount",
      "guardduty:DisassociateFromAdministratorAccount",
      "securityhub:DisableSecurityHub",
      "securityhub:DisassociateFromAdministratorAccount",
      "access-analyzer:DeleteAnalyzer",
    ]
    resources = ["*"]
  }

  # Break the seal IAM roles. Should not have access to assume it
  statement {
    sid     = "DenyAssumingOrganizationAdminRoles"
    effect  = "Deny"
    actions = ["sts:AssumeRole"]
    resources = [
      "arn:aws:iam::*:role/OrganizationAccountAccessRole",
      "arn:aws:iam::*:role/AWSControlTowerExecution",
    ]
  }
}

resource "aws_iam_policy" "denied_permissions" {
  path        = local.management_iam_path
  name        = local.denied_permissions_policy_name
  description = "Policies that restricts what the GitHub Actions pipeline is permitted to modify"
  policy      = data.aws_iam_policy_document.denied_permissions.json
}

resource "aws_iam_role_policy_attachment" "denied_permissions" {
  // In certain situations you need permission to disable the guardrails
  count = var.disable_guardrails ? 0 : 1

  policy_arn = aws_iam_policy.denied_permissions.arn
  role       = aws_iam_role.this.name
}
