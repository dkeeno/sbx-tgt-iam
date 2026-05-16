# =============================================================================
# outputs.tf
# =============================================================================

output "tgt_role_arn" {
  description = "ARN of the new tgt-github-actions IAM role. Set this as AWS_ROLE_ARN secret on each tgt-* repo."
  value       = aws_iam_role.tgt_github_actions.arn
}

output "tgt_role_name" {
  description = "Name of the new role."
  value       = aws_iam_role.tgt_github_actions.name
}

output "trusted_repo_patterns" {
  description = "GitHub repo subject patterns the new role trusts."
  value       = [for p in var.iam_role_repo_prefix : "repo:${var.github_owner}/${p}*:*"]
}
