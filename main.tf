locals {
  // obtained from https://github.blog/changelog/2023-06-27-github-actions-update-on-oidc-integration-with-aws/
  thumbprint = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = local.thumbprint
}

resource "aws_iam_role" "oidc_assume_role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.oidc_authenticate_policy.json
}

data "aws_iam_policy_document" "oidc_authenticate_policy" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      identifiers = [aws_iam_openid_connect_provider.oidc_provider.arn]
      type        = "Federated"
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }
    condition {
      test     = "StringLike"
      values   = var.github_repositories
      variable = "token.actions.githubusercontent.com:sub"
    }
  }
}

/*
 * = S3 Permissions
 */
resource "aws_iam_role_policy" "s3_read" {
  count  = length(var.allowed_s3_read_arns) > 0 ? 1 : 0
  policy = data.aws_iam_policy_document.s3_read.json
  role   = aws_iam_role.oidc_assume_role.id
}

data "aws_iam_policy_document" "s3_read" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*",
    ]
    resources = concat(var.allowed_s3_read_arns, formatlist("%s/*", var.allowed_s3_read_arns))
  }
}

resource "aws_iam_role_policy" "s3_write" {
  count  = length(var.allowed_s3_write_arns) > 0 ? 1 : 0
  policy = data.aws_iam_policy_document.s3_write.json
  role   = aws_iam_role.oidc_assume_role.id
}

data "aws_iam_policy_document" "s3_write" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:List*",
    ]
    resources = concat(var.allowed_s3_write_arns, formatlist("%s/*", var.allowed_s3_write_arns))
  }
}

/*
 * = ECR Permissions
 */

resource "aws_iam_role_policy" "ecr" {
  count  = length(var.allowed_ecr_arns) > 0 ? 1 : 0
  policy = data.aws_iam_policy_document.ecr.json
  role   = aws_iam_role.oidc_assume_role.id
}

data "aws_iam_policy_document" "ecr" {
  version = "2012-10-17"
  statement {
    effect = "Allow"

    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:BatchGetImage"
    ]
    resources = var.allowed_ecr_arns
  }
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

/*
 * = ECS Permissions
 */

resource "aws_iam_role_policy" "ecs" {
  count  = length(var.allowed_ecs_arns) > 0 ? 1 : 0
  policy = data.aws_iam_policy_document.ecs.json
  role   = aws_iam_role.oidc_assume_role.id
}

data "aws_iam_policy_document" "ecs" {
  statement {
    effect    = "Allow"
    sid = "RegisterTaskDefinition"
    actions = [
      "ecs:RegisterTaskDefinition",
    ]
    resources = var.allowed_ecs_arns
    // Permissions to allow creating task definition and update ECS service to use the task definition
  }

  statement {
    effect = "Allow"
    sid = "DeployService"
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeServices"
    ]

    resources = var.allowed_ecs_arns
  }

  statement {
    effect = "Allow"
    sid = "PassRolesInTaskDefinition"
    actions = [
      "iam:PassRole",
    ]
    resources = ["*"]
  }
}

/*
 * = Allow Deployment Service Access
 */

resource "aws_iam_role_policy" "deployment_service_access" {
  policy = data.aws_iam_policy_document.api_access.json
  role   = aws_iam_role.oidc_assume_role.id
}

data "aws_iam_policy_document" "api_access" {
  statement {
    effect    = "Allow"
    actions   = ["execute-api:Invoke"]
    resources = ["*"]
  }
}
