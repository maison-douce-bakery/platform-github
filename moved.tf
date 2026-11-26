# Renames keep the repo, ruleset and alerts instead of destroying them.
moved {
  from = github_repository.this["data-platform"]
  to   = github_repository.this["data-orchestration"]
}

moved {
  from = github_repository_ruleset.main["data-platform"]
  to   = github_repository_ruleset.main["data-orchestration"]
}

moved {
  from = github_repository_vulnerability_alerts.this["data-platform"]
  to   = github_repository_vulnerability_alerts.this["data-orchestration"]
}
