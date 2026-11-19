# Auth uses GITHUB_TOKEN if it is set, otherwise the provider falls back to `gh auth token`.
# Admins only need `gh` signed in to the right account. The token needs the repo, workflow
# and admin:org scopes.
provider "github" {
  owner = local.organization
}
