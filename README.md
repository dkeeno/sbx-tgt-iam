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

`.github/workflows/terraform.yml` mirrors the sbx-* pattern:

| Trigger | Job |
|---|---|
| PR open / sync | fmt-check → validate → plan (posted as PR comment) |
| Push to main | fmt-check → validate → plan (artifacted) |
| `workflow_dispatch` (`action=apply`) | apply, gated by GitHub Environment `production` |
| `workflow_dispatch` (`action=destroy`) | destroy, same gate |

This repo is **named with the `sbx-` prefix** so it inherits the existing `sbx-github-actions` role's OIDC trust (`repo:dkeeno/sbx-*:*`). The workflow assumes `sbx-github-actions` to apply (creating `tgt-github-actions`). After apply, set `AWS_ROLE_ARN` on each `tgt-*` repo to the new role's ARN (printed in the Terraform output).

## Apply

Standard pattern:

1. Open a PR with the desired change.
2. Wait for CI plan to complete; review the plan in the PR comment.
3. Merge PR (squash).
4. Go to **Actions → terraform → Run workflow → action: `apply`**.
5. Approve at the `production` environment gate.
6. Capture the `tgt_role_arn` output and set it as `AWS_ROLE_ARN` secret on each `tgt-*` repo.

## Destroy

1. **Actions → terraform → Run workflow → action: `destroy`**.
2. Approve.
3. Verify the role + attachment are gone; tgt-* repos lose CI ability immediately.
