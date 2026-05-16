# =============================================================================
# variables.tf
# =============================================================================

variable "aws_region" {
  description = "AWS region for the IAM role (IAM is global but provider needs a region)."
  type        = string
  default     = "us-east-1"
}

variable "github_owner" {
  description = "GitHub username (personal account) that owns the tgt-* repos."
  type        = string
  default     = "dkeeno"
}

variable "iam_role_name" {
  description = "Name of the IAM role GitHub Actions in tgt-* repos assume via OIDC."
  type        = string
  default     = "tgt-github-actions"
}

variable "iam_role_repo_prefix" {
  description = "Repo-name prefix(es) the IAM role trusts. Trust policy emits one StringLike pattern per entry: repo:<owner>/<prefix>*:*. For Phase 2 of the WC-003 simulation we trust only tgt-*."
  type        = list(string)
  default     = ["tgt-"]
}
