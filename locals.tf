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
        "plan / plan (bootstrap)",
        "plan / plan (account-baseline)",
        "plan / plan (iam-baseline)",
        "plan / plan (ci-access)",
        "plan / plan (audit)",
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
    "platform-infra-live" = {
      description = "Live AWS infrastructure per environment, planned on PRs and applied by CI on main."
      auto_init   = true
      required_checks = [
        "terraform / static checks",
        "plan / plan (prod/ap-southeast-2/network)",
        "plan / plan (prod/ap-southeast-2/ecs)",
        "plan / plan (prod/ap-southeast-2/data-platform)",
        "plan / plan (prod/ap-southeast-2/rds)",
        "plan / plan (prod/ap-southeast-2/commerce)",
        "plan / plan (prod/ap-southeast-2/datalake)",
        "plan / plan (prod/ap-southeast-2/ingest-open-meteo)",
        "plan / plan (prod/ap-southeast-2/certificate)",
        "plan / plan (prod/ap-southeast-2/edge)",
        "plan / plan (prod/ap-southeast-2/marmot)",
      ]
    }
    "commerce-api" = {
      description     = "Maison Douce operational database: schema, opening seed and the operations simulator."
      auto_init       = true
      required_checks = ["test"]
    }
    "data-orchestration" = {
      description     = "DAGs and the Dagu runtime image of the data platform."
      auto_init       = true
      required_checks = ["build"]
    }
    "data-catalog" = {
      description     = "Runtime image of the data catalog: Marmot with only the plugins we use."
      auto_init       = true
      required_checks = ["build"]
    }
    "data-transform" = {
      description     = "dbt project of the data platform: models, tests and snapshots."
      auto_init       = true
      required_checks = ["parse"]
    }
    "data-ingestion" = {
      description     = "Ingestion of external sources into the data platform: dlt pipelines and the Lambda that lands raw files in S3."
      auto_init       = true
      required_checks = ["build"]
    }
    "platform-deployments" = {
      description = "GitOps for application services: per-environment ECS task definitions and image digests."
      auto_init   = true
      required_checks = [
        "terraform / static checks",
        "plan / plan (prod/ap-southeast-2/commerce-api)",
      ]
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
      repositories = ["platform-aws-foundation", "platform-infra-live", "platform-deployments"]
    }
    AWS_CI_PUSH_ROLE_ARN = {
      value        = "arn:aws:iam::452258152479:role/platform/mdb-shared-ci-push"
      visibility   = "selected"
      repositories = ["commerce-api", "data-orchestration", "data-ingestion", "data-catalog"]
    }
    AWS_CI_DEPLOY_ROLE_ARN = {
      value        = "arn:aws:iam::452258152479:role/platform/mdb-shared-ci-deploy"
      visibility   = "selected"
      repositories = ["platform-deployments"]
    }
  }

  # Org-level Actions secrets. Their values are set with `gh secret set` and never stored here,
  # because Terraform would keep them in state. Only which repos can read them is managed.
  org_secret_repositories = {
    AWS_CI_PLAN_ACCESS_KEY_ID       = ["platform-aws-foundation", "platform-infra-live", "platform-deployments"]
    AWS_CI_PLAN_SECRET_ACCESS_KEY   = ["platform-aws-foundation", "platform-infra-live", "platform-deployments"]
    AWS_CI_PUSH_ACCESS_KEY_ID       = ["commerce-api", "data-orchestration", "data-ingestion", "data-catalog"]
    AWS_CI_PUSH_SECRET_ACCESS_KEY   = ["commerce-api", "data-orchestration", "data-ingestion", "data-catalog"]
    AWS_CI_DEPLOY_ACCESS_KEY_ID     = ["platform-deployments"]
    AWS_CI_DEPLOY_SECRET_ACCESS_KEY = ["platform-deployments"]
  }

  # Deployment environments. Only main can deploy, so PR code never sees their secrets.
  # Secret values are set with `gh secret set --env`.
  environments = {
    "platform-infra-live/prod" = {
      repository = "platform-infra-live"
      name       = "prod"
      variables = {
        AWS_CI_APPLY_ROLE_ARN = "arn:aws:iam::452258152479:role/platform/mdb-shared-ci-apply"
      }
    }
    "platform-deployments/prod" = {
      repository = "platform-deployments"
      name       = "prod"
      variables  = {}
    }
  }

  # Third-party actions allowed in the org, on top of GitHub-owned ones. They must be pinned by SHA.
  allowed_actions = [
    "hashicorp/setup-terraform@*",
    "aws-actions/configure-aws-credentials@*",
    "terraform-linters/setup-tflint@*",
  ]
}
