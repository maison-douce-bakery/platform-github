# Auth comes from GITHUB_TOKEN. Admins run: export GITHUB_TOKEN="$(gh auth token)"
# The token needs the repo, workflow and admin:org scopes.
provider "github" {
  owner = local.organization
}
