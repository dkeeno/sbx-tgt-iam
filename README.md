# sbx-tgt-iam

Provisions the `tgt-github-actions` IAM role used by GitHub Actions workflows in `dkeeno/tgt-*` repositories during the WC-003 Phase 2 simulation.

## What this stack creates

| Resource | Purpose |
|---|---|
| `aws_iam_role.tgt_github_actions` | Role that tgt-* repos assume via OIDC |
| `aws_iam_role_policy_attachment` | Attaches AWS-managed `AdministratorAccess` (sandbox-grade) |

The OIDC provider itself (`token.actions.githubusercontent.com`) already exists in the account — provisioned by the sbx bootstrap stack — and is referenced here via a `data` source.

## Why a separate role (not extending `sbx-github-actions`)?

- Clean blast radius — simulation env compromise doesn't implicate the source env's role.
- Clean teardown — destroy this stack to remove tgt access; the sbx role stays put.
- Avoids state surgery on the sbx bootstrap module.

## CI workflow

`.github/workflows/terraform.yml` mirrors the `sbx-cluster-iac` pattern (GitLab-style validate → plan → manual-apply, chained via `needs:`):

| Trigger | Jobs |
|---|---|
| PR open / sync | validate → plan (plan posted as PR comment) |
| Push to main | validate → plan → apply (apply pauses on `production` environment gate) |
| `workflow_dispatch` (`action=apply`) | validate → plan → apply (fresh plan + apply, same gate) |
| `workflow_dispatch` (`action=destroy`) | destroy (gated by same environment) |

This repo is **named with the `sbx-` prefix** so it inherits the existing `sbx-github-actions` role's OIDC trust (`repo:dkeeno/sbx-*:*`). The workflow assumes `sbx-github-actions` to apply (creating `tgt-github-actions`). After apply, set `AWS_ROLE_ARN` on each `tgt-*` repo to the new role's ARN (printed in the Terraform output).

## Apply (standard pattern)

1. Open a PR with the desired change.
2. Wait for CI `plan` to complete; review the plan output as a PR comment.
3. Merge the PR (squash).
4. The merge triggers a new workflow run: validate → plan → apply.
5. The `apply` job pauses at the `production` environment gate. A banner appears at the top of the run page: **Review deployments → select `production` → Approve and deploy**.
6. Apply runs. Capture the `tgt_role_arn` value from the `terraform-outputs-<run_id>` artifact and set it as `AWS_ROLE_ARN` secret on each `tgt-*` repo.

Environment is configured with `Required reviewers: dkeeno` and `prevent_self_review: false` — GitHub still REQUIRES the click (does NOT auto-approve), but allows the reviewer to be the deployer in solo-dev mode.

## Destroy

1. **Actions → terraform → Run workflow → action: `destroy`**.
2. Approve.
3. Verify the role + attachment are gone; tgt-* repos lose CI ability immediately.
