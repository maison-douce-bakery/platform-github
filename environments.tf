resource "github_repository_environment" "this" {
  for_each = local.environments

  repository        = github_repository.this[each.value.repository].name
  environment       = each.value.name
  can_admins_bypass = false

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "main" {
  for_each = local.environments

  repository     = github_repository_environment.this[each.key].repository
  environment    = github_repository_environment.this[each.key].environment
  branch_pattern = "main"
}

resource "github_actions_environment_variable" "this" {
  for_each = merge([
    for key, env in local.environments : {
      for name, value in env.variables : "${key}/${name}" => {
        env   = key
        name  = name
        value = value
      }
    }
  ]...)

  repository    = github_repository_environment.this[each.value.env].repository
  environment   = github_repository_environment.this[each.value.env].environment
  variable_name = each.value.name
  value         = each.value.value
}
