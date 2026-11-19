# Supply chain: only GitHub-owned actions and an explicit allow list, all pinned by commit SHA.
resource "github_actions_organization_permissions" "this" {
  enabled_repositories = "all"
  allowed_actions      = "selected"
  sha_pinning_required = true

  allowed_actions_config {
    github_owned_allowed = true
    verified_allowed     = false
    patterns_allowed     = local.allowed_actions
  }
}

# GITHUB_TOKEN is read-only by default, and workflows can't approve pull requests.
resource "github_actions_organization_workflow_permissions" "this" {
  organization_slug                = local.organization
  default_workflow_permissions     = "read"
  can_approve_pull_request_reviews = false
}

resource "github_actions_organization_variable" "this" {
  for_each = local.org_variables

  variable_name = each.key
  value         = each.value.value
  visibility    = each.value.visibility
  selected_repository_ids = (
    each.value.visibility == "selected"
    ? [for repo in each.value.repositories : github_repository.this[repo].repo_id]
    : null
  )
}

resource "github_actions_organization_secret_repositories" "this" {
  for_each = local.org_secret_repositories

  secret_name             = each.key
  selected_repository_ids = [for repo in each.value : github_repository.this[repo].repo_id]
}
