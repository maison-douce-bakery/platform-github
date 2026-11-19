# Same protection for main in every repo. No bypass actors: to merge past a broken CI,
# disable the ruleset here, which leaves a trace in the PR history and the audit log.
resource "github_repository_ruleset" "main" {
  for_each = local.repositories

  name        = "protect-main"
  repository  = github_repository.this[each.key].name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    deletion                = true
    non_fast_forward        = true
    required_linear_history = true

    # Solo maintainer for now, so 0 approvals. Raise to 1 when a second person joins.
    pull_request {
      required_approving_review_count   = 0
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_review_thread_resolution = true
      allowed_merge_methods             = ["rebase", "squash"]
    }

    dynamic "required_status_checks" {
      for_each = length(each.value.required_checks) > 0 ? [1] : []

      content {
        strict_required_status_checks_policy = true

        dynamic "required_check" {
          for_each = each.value.required_checks

          content {
            context        = required_check.value
            integration_id = local.github_actions_app_id
          }
        }
      }
    }
  }
}

# Release tags are immutable: a moved or deleted tag silently changes what consumers run.
# No bypass actors, same as protect-main. Creation stays open to anyone with write access.
resource "github_repository_ruleset" "tags" {
  for_each = toset(local.tag_protected_repositories)

  name        = "protect-tags"
  repository  = github_repository.this[each.key].name
  target      = "tag"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  rules {
    update   = true
    deletion = true
  }
}
