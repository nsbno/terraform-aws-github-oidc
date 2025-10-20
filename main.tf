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
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_org}/*:environment:${local.environment_mapping[var.environment]}"
      ]
    }
  }
}

resource "aws_iam_role" "this" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  path               = "/__management__/"
  name               = "deployment"
}

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.this.name
}
