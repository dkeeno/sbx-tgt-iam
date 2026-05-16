# =============================================================================
# github-oidc.tf — IAM role for GitHub Actions in tgt-* repos
# =============================================================================
#
# Purpose: provision a SEPARATE IAM role (tgt-github-actions) that GitHub
# Actions workflows in dkeeno/tgt-* repos can assume via OIDC. Parallel
# to the existing sbx-github-actions role (which serves dkeeno/sbx-*).
#
# Why a separate role (not extending sbx-github-actions)?
#   - Clean blast radius: if the simulation env is compromised, the
#     source env's role isn't implicated.
#   - Clean teardown: when Phase 2 simulation ends, destroy this stack
#     and the tgt access vanishes; the sbx role is untouched.
#   - Avoids modifying state owned by the bootstrap module elsewhere.
#
# This stack does NOT provision the OIDC provider — the provider already
# exists in the account (provisioned by the sbx bootstrap; one-per-account
# forever). We reference it via a data source.

# -----------------------------------------------------------------------------
# Data source — the existing GitHub OIDC provider
# -----------------------------------------------------------------------------
data "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

# -----------------------------------------------------------------------------
# Trust policy — only repo:dkeeno/tgt-*:* can assume
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "tgt_github_actions_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github_actions.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    # Audience must be sts.amazonaws.com (what configure-aws-credentials sends).
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Subject lock: one StringLike pattern per repo prefix.
    # Defaults to ["tgt-"] so any branch / tag / PR from a tgt-* repo
    # can assume. Tighten per-repo+per-branch in production.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for p in var.iam_role_repo_prefix : "repo:${var.github_owner}/${p}*:*"]
    }
  }
}

# -----------------------------------------------------------------------------
# The IAM role
# -----------------------------------------------------------------------------
resource "aws_iam_role" "tgt_github_actions" {
  name               = var.iam_role_name
  description        = "Assumed by GitHub Actions in dkeeno/tgt-* repos via OIDC. WC-003 Phase 2 simulation. Sandbox: AdministratorAccess."
  assume_role_policy = data.aws_iam_policy_document.tgt_github_actions_trust.json

  max_session_duration = 3600 # 1 hour — Terraform applies finish well within this
}

# -----------------------------------------------------------------------------
# Permissions
# -----------------------------------------------------------------------------
# Sandbox-grade: AdministratorAccess. Production would use a custom policy
# scoped to exactly the resource ARNs the tgt-* stacks manage.
resource "aws_iam_role_policy_attachment" "tgt_github_actions_admin" {
  role       = aws_iam_role.tgt_github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
