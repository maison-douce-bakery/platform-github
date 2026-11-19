# platform-github

GitHub organization settings for `maison-douce-bakery`, managed with Terraform:

- **Repositories**: settings shared by every repo (merge methods, secret scanning, branch cleanup)
- **Branch protection**: a `protect-main` ruleset per repo, with its required CI checks
- **Actions policy**: allowed actions, SHA pinning, read-only `GITHUB_TOKEN`
- **Org variables and secret access**: which repos can read the shared CI variables and secrets

## Why a separate repo

- **It isn't AWS.** It uses a different provider and different credentials from `platform-aws-foundation`.
- **It manages every repo**, including itself, so it sits beside the other platform repos rather than inside one.
- **Changes go through review.** A new required check or a new repo is a PR with a `terraform plan`, not a hand-written API call.

## What is not managed here

| Item | Why |
|---|---|
| Secret values | Terraform would store them in state. Set them with `gh secret set`, reading from stdin |
| Fork PR approval policy (`all_external_contributors`) | Not supported by the provider. Set per repo with `gh api` |
| Org 2FA requirement, billing | Not available through the API used here |

## Making a change

`main` is protected. Every change goes through a pull request.

1. Create a branch and edit `locals.tf`. Most changes are a new repo, a new required check, or a new allowed action.
2. Run `terraform plan` and `terraform apply` with admin credentials:
   - GitHub: `gh auth refresh -h github.com -s admin:org`, then `export GITHUB_TOKEN="$(gh auth token)"`
   - AWS (state backend): `aws login`
3. Open a PR. CI runs `fmt`, `validate` and `tflint`.
4. Merge with rebase, then drop the scope again with `gh auth refresh -h github.com -r admin:org`.

**Adding a repo:** add it to `repositories` in `locals.tf` with `auto_init = true` and its required checks. Terraform creates it, protects `main` and enables secret scanning. Then set its fork PR approval policy with `gh api`.

## Decisions

- **No bypass actors on `protect-main`.** To merge past a broken CI, disable the ruleset here, so it shows up in history.
- **0 required approvals.** There is one maintainer, and GitHub doesn't allow approving your own PR. Raise it when a second person joins.
- **Actions allow list with SHA pinning.** Only GitHub-owned actions and the listed third-party actions can run, and only when pinned to a commit SHA. This limits supply-chain attacks such as a hijacked tag.
- **Repos are archived, not deleted, if destroyed.**
