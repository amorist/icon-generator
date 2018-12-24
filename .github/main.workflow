workflow "Build and deploy on push" {
  on = "push"
  resolves = ["build"]
}

action "GitHub Action for npm" {
  uses = "actions/npm@e7aaefe"
  runs = "install"
  secrets = ["GITHUB_TOKEN"]
}

action "build" {
  uses = "actions/npm@e7aaefe"
  needs = ["GitHub Action for npm"]
  runs = "build"
}
