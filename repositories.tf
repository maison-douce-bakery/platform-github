resource "github_repository" "this" {
  for_each = local.repositories

  name        = each.key
  description = each.value.description
  visibility  = "public"

  # Only for repos created by Terraform: makes the first commit so main exists before protection.
  auto_init = each.value.auto_init

  has_issues      = true
  has_projects    = false
  has_wiki        = false
  has_discussions = false

  # Linear history: rebase or squash only, matching the ruleset.
  allow_merge_commit     = false
  allow_squash_merge     = true
  allow_rebase_merge     = true
  allow_auto_merge       = false
  allow_update_branch    = true
  delete_branch_on_merge = true

  # Free for public repos. Push protection blocks commits that contain known secret formats.
  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"
    }
  }

  # Archive instead of delete if the resource is ever destroyed.
  archive_on_destroy = true

  lifecycle {
    prevent_destroy = true
  }
}

# Dependabot alerts for vulnerable dependencies.
resource "github_repository_vulnerability_alerts" "this" {
  for_each = github_repository.this

  repository = each.value.name
  enabled    = true
}
