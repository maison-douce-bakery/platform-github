locals {
  organization = "maison-douce-bakery"

  # App ID of GitHub Actions. Required checks must come from it, not from any app with the same name.
  github_actions_app_id = 15368

  # Every repo in the org. All share the same settings and branch protection.
  # required_checks are the CI job names that must pass before merging into main.
  repositories = {
    "platform-aws-foundation" = {
      description = "Base AWS layer: Terraform state, account guardrails, CI access and audit."
      auto_init   = false
      required_checks = [
        "terraform / static checks",
        "plan (bootstrap)",
        "plan (account-baseline)",
        "plan (iam-baseline)",
        "plan (ci-access)",
        "plan (audit)",
      ]
    }
    "platform-github" = {
      description     = "GitHub organization settings, repositories and rulesets as code."
      auto_init       = true
      required_checks = ["terraform / static checks"]
    }
    "platform-terraform-modules" = {
      description     = "Reusable, versioned Terraform modules for the platform."
      auto_init       = true
      required_checks = ["terraform / static checks"]
    }
    "platform-ci-workflows" = {
      description     = "Reusable GitHub Actions workflows for the platform repos."
      auto_init       = true
      required_checks = ["actionlint"]
    }
  }

  # Repos whose tags are releases that consumers pin. Their tags can't be moved or deleted.
  tag_protected_repositories = ["platform-terraform-modules", "platform-ci-workflows"]

  # Org-level Actions variables. They aren't secret, so Terraform manages their values.
  org_variables = {
    AWS_REGION = {
      value        = "ap-southeast-2"
      visibility   = "all"
      repositories = []
    }
    AWS_CI_PLAN_ROLE_ARN = {
      value        = "arn:aws:iam::452258152479:role/platform/mdb-shared-ci-plan"
      visibility   = "selected"
      repositories = ["platform-aws-foundation"]
    }
  }

  # Org-level Actions secrets. Their values are set with `gh secret set` and never stored here,
  # because Terraform would keep them in state. Only which repos can read them is managed.
  org_secret_repositories = {
    AWS_CI_PLAN_ACCESS_KEY_ID     = ["platform-aws-foundation"]
    AWS_CI_PLAN_SECRET_ACCESS_KEY = ["platform-aws-foundation"]
  }

  # Third-party actions allowed in the org, on top of GitHub-owned ones. They must be pinned by SHA.
  allowed_actions = [
    "hashicorp/setup-terraform@*",
    "aws-actions/configure-aws-credentials@*",
    "terraform-linters/setup-tflint@*",
  ]
}
