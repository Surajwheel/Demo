# Practical Git Workflow Guide for Kubernetes Microservices

## Quick Reference Commands

### Setup & Configuration

```bash
# Initial setup
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config commit.template .gitmessage
git config core.hooksPath .githooks

# View configuration
git config --list
git config --local --list
```

---

## Daily Workflow Scenarios

### Scenario 1: Starting New Feature

```bash
# 1. Start on develop branch
git checkout develop
git pull origin develop

# 2. Create feature branch
git checkout -b feature/add-user-validation

# 3. Make changes to files
# Edit: 6-user-service.yaml
# Edit: services/user-service/app.js

# 4. Stage and commit changes
git add 6-user-service.yaml services/user-service/app.js
git commit

# This opens your editor with commit template
# Type: feat(user-service): add email validation
# Add description...

# 5. Push to remote
git push origin feature/add-user-validation

# 6. Create Pull Request on GitHub/GitLab
```

---

### Scenario 2: Working on Multiple Commits

```bash
# Make first feature
git add api-gateway.yaml
git commit -m "feat(api-gateway): add rate limiting"

# Make second feature  
git add prometheus-values.yaml
git commit -m "infra(monitoring): increase retention period"

# Make third feature
git add 6-user-service.yaml
git commit -m "feat(user-service): add caching"

# Review commits
git log --oneline -3

# Push all commits
git push origin feature/comprehensive-update
```

---

### Scenario 3: Fixing Commits

#### Fix typo in last commit
```bash
# Change file
git add file.yaml
git commit --amend --no-edit

# If you need to change commit message
git commit --amend
```

#### Combine multiple commits
```bash
# Show last 3 commits
git log --oneline -3

# Interactive rebase last 3 commits
git rebase -i HEAD~3

# In editor:
# pick abc1234 feat: first feature
# squash def5678 feat: second feature
# squash ghi9012 feat: third feature

# Save and close editor
# Edit combined commit message
# Git will prompt for new message
```

#### Undo last commit (keep changes)
```bash
git reset --soft HEAD~1
# Changes are staged, ready to re-commit

git reset --mixed HEAD~1
# Changes are unstaged (default)

git reset --hard HEAD~1
# Changes are discarded (use with caution!)
```

---

### Scenario 4: Updating Feature Branch from Develop

```bash
# Option 1: Rebase (preferred for trunk-based)
git fetch origin
git rebase origin/develop
# Resolves conflicts locally
git push origin feature/something --force-with-lease

# Option 2: Merge (preferred for Git Flow)
git fetch origin
git merge origin/develop
git push origin feature/something
```

---

### Scenario 5: Handling Merge Conflicts

```bash
# Start rebase
git fetch origin
git rebase origin/develop

# If conflicts occur:
# 1. Git pauses and shows conflicted files
# 2. Edit files to resolve conflicts
# 3. Look for conflict markers:
#    <<<<<<< HEAD (your changes)
#    your code
#    =======
#    incoming code
#    >>>>>>> origin/develop

# 4. Edit to keep what you need
# 5. Stage resolved files
git add resolved-file.yaml

# 6. Continue rebase
git rebase --continue

# If rebase goes wrong
git rebase --abort
git reset --hard origin/develop
```

---

### Scenario 6: Switching Between Branches

```bash
# List all branches
git branch -a

# Switch to existing branch
git checkout develop
git checkout feature/something

# Using newer syntax (Git 2.23+)
git switch develop
git switch feature/something

# Create and switch in one command
git checkout -b feature/new-feature
git switch -c feature/new-feature  # newer syntax

# Switch to previous branch
git checkout -

# Delete local branch
git branch -d feature/completed

# Delete remote branch
git push origin --delete feature/completed
```

---

### Scenario 7: Stashing Changes

```bash
# Save work in progress without committing
git stash

# List stashes
git stash list

# Apply most recent stash
git stash pop

# Apply specific stash
git stash pop stash@{0}

# Apply without removing from stash
git stash apply

# Delete stash
git stash drop stash@{0}

# Delete all stashes
git stash clear
```

---

### Scenario 8: Cherry-picking Commits

```bash
# Apply specific commit to current branch
git cherry-pick abc1234

# If needed from another branch
git cherry-pick feature/something~2

# Multiple commits in sequence
git cherry-pick abc1234 def5678 ghi9012

# Range of commits
git cherry-pick abc1234..ghi9012  # excludes abc1234
git cherry-pick abc1234^..ghi9012  # includes abc1234
```

---

### Scenario 9: Creating Release Branch (Git Flow)

```bash
# Ensure develop is up to date
git checkout develop
git pull origin develop

# Create release branch
git checkout -b release/1.2.0

# Update version numbers
# Edit: package.json - bump to 1.2.0
# Edit: CHANGELOG.md - add release notes

git add package.json CHANGELOG.md
git commit -m "chore(release): prepare v1.2.0"

# Push release branch
git push origin release/1.2.0

# Create PR to main for final approval
# After merge, tag the release

git checkout main
git pull origin main
git tag -a v1.2.0 -m "Release version 1.2.0"
git push origin v1.2.0

# Back-merge to develop
git checkout develop
git pull origin develop
git merge main
git push origin develop
```

---

### Scenario 10: Creating Hotfix (Git Flow)

```bash
# Create hotfix from main
git checkout main
git pull origin main
git checkout -b hotfix/1.1.1-security

# Fix the issue
# Edit: 6-user-service.yaml (security fix)

git add 6-user-service.yaml
git commit -m "fix(user-service): security vulnerability in auth"

# Push hotfix branch
git push origin hotfix/1.1.1-security

# Create PR to main
# After approval and merge:

git checkout main
git pull origin main
git tag -a v1.1.1 -m "Hotfix v1.1.1"
git push origin v1.1.1

# Also merge to develop
git checkout develop
git pull origin develop
git merge main
git push origin develop
```

---

## Common Issues and Solutions

### Issue: Committed to wrong branch

```bash
# You committed to main by mistake, but needed develop

# Create correct branch from current HEAD
git branch feature/correct-place

# Reset main to before commit
git reset --hard origin/main

# Switch to new branch
git checkout feature/correct-place

# Now you're on correct branch with your changes
```

### Issue: Forgot to add file to commit

```bash
# Add forgotten file
git add forgotten-file.yaml

# Amend previous commit
git commit --amend --no-edit

# Push with force (only on feature branches!)
git push origin feature/something --force-with-lease
```

### Issue: Need to see what changed

```bash
# See changes not yet staged
git diff

# See staged changes
git diff --cached

# See all changes since branch point
git diff origin/develop..HEAD

# See commit details
git show abc1234

# See file history
git log --oneline -- file.yaml
git log -p -- file.yaml  # with diff
```

### Issue: Accidentally deleted branch

```bash
# Find deleted branch SHA
git reflog

# Recreate branch from SHA
git checkout -b feature/recovered abc1234

# Push recovered branch
git push origin feature/recovered
```

### Issue: Large files committed

```bash
# Remove file from last commit (keep locally)
git rm --cached large-file.bin
git commit --amend --no-edit

# Add to .gitignore
echo "large-file.bin" >> .gitignore
git add .gitignore
git commit -m "chore: add large file to gitignore"

# For bigger issues, use git-lfs
git lfs install
git lfs track "*.bin"
git add .gitattributes
```

---

## Branch Comparison and Review

### Compare branches before merge

```bash
# See commits on feature that aren't on develop
git log develop..feature/something --oneline

# See what will be added
git diff develop...feature/something

# See specific files
git diff develop...feature/something -- k8s/

# See stats
git diff develop...feature/something --stat
```

### Code review workflow

```bash
# Reviewer reviews on GitHub/GitLab interface
# Or locally:

# Fetch PR branch
git fetch origin pull/123/head:pr-123
git checkout pr-123

# Review code
# Run tests
npm test

# If changes needed, comment on PR
# Developer makes fixes and pushes

# Reviewer approves
# Maintainer merges PR
```

---

## Useful Aliases

Add to your `.gitconfig`:

```bash
[alias]
    # Shortcuts
    st = status
    co = checkout
    br = branch
    ci = commit
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = log --graph --oneline --all
    
    # Useful combinations
    amend = commit --amend --no-edit
    sync = !git fetch origin && git rebase origin/main
    squash = rebase -i HEAD~
    contributors = shortlog --summary --numbered
    
    # Branch management
    cleanup = !git remote prune origin && git branch -vv | grep gone | awk '{print $1}' | xargs git branch -D
    recent = for-each-ref --count=10 --sort=-committerdate --format='%(refname:short)' refs/heads/
    stale = for-each-ref --sort=committerdate --format='%(refname:short) %(committerdate:short)' refs/heads/
    
    # Logs
    log-graph = log --graph --oneline --all --decorate
    log-commits = log --oneline -n 20
    log-stat = log --stat --oneline -n 10
```

Usage:
```bash
git st           # status
git co develop   # checkout develop
git amend        # amend last commit
git sync         # sync with main
git visual       # visualize branches
git cleanup      # clean stale branches
```

---

## Team Workflow Process

### Feature Development (1-3 days)

```
1. Developer creates feature branch from develop
2. Developer makes commits with clear messages
3. Developer keeps branch updated with git fetch/rebase
4. When ready, developer creates PR with description
5. Code review happens (1-2 reviewers)
6. Developer addresses feedback (if any)
7. PR approved and merged to develop
8. Branch automatically deleted
```

### Integration (Develop → Staging)

```
1. Daily at 4 PM, features are merged from develop to staging
2. Automated tests run (CI/CD)
3. Automated deployment to staging namespace
4. QA team tests in staging for 24 hours
5. If issues found, PR back to develop with fixes
6. Otherwise, ready for production
```

### Release to Production

```
1. Create release branch from main
2. Update version numbers and CHANGELOG
3. Deploy to production
4. Monitor metrics and logs
5. If issues found, create hotfix branch from main
6. After hotfix, back-merge to develop
7. Monitor for 24 hours
8. Tag release and archive
```

---

## Git Commands by Use Case

### View Information

```bash
git status                          # Current status
git log                            # Commit history
git show commit-hash               # Details of specific commit
git diff                           # Unstaged changes
git diff --cached                  # Staged changes
git branch -a                      # All branches
git remote -v                      # Remote repositories
git reflog                         # Local reference history
```

### Make Changes

```bash
git add file.yaml                  # Stage file
git add .                          # Stage all changes
git commit -m "message"            # Create commit
git commit --amend                 # Modify last commit
git reset HEAD~1                   # Undo last commit
git revert commit-hash             # Create reverse commit
```

### Work with Branches

```bash
git branch feature/name            # Create branch
git checkout feature/name          # Switch branch
git switch feature/name            # Switch branch (newer)
git branch -d feature/name         # Delete branch
git push origin feature/name       # Push branch
git pull origin develop            # Fetch and merge
git fetch origin                   # Fetch updates
git rebase origin/develop          # Rebase on develop
```

### Clean Up

```bash
git branch -D feature/old          # Force delete local
git push origin --delete feature/old  # Delete remote
git remote prune origin            # Clean deleted remotes
git clean -fd                      # Remove untracked files
git reflog expire --all --expire=now  # Clean reflog
```

---

## Performance Tips

### Speed up Git

```bash
# Use credential caching
git config --global credential.helper store

# Speed up git status
git config --global core.preloadindex true

# Increase window size for compression
git config --global pack.windowMemory "100m"
git config --global pack.packSizeLimit "100m"
```

### Handle large repositories

```bash
# Shallow clone for large repos
git clone --depth 1 <repo-url>

# Sparse checkout (only certain directories)
git clone --sparse <repo-url>
git sparse-checkout add k8s/

# Use git worktree for multiple branches
git worktree add ../k8s-feature-branch feature/something
```

---

## Summary: Recommended Daily Workflow

```bash
# Morning: sync with latest
git fetch origin
git rebase origin/develop

# Work: make changes
git add changed-file.yaml
git commit -m "feat(service): description"

# Noon: push progress
git push origin feature/something

# Afternoon: address PR feedback
git add reviewed-file.yaml
git commit --amend --no-edit
git push origin feature/something --force-with-lease

# End of day: prepare for merge
git log --oneline -5  # Review your commits
git diff origin/develop..HEAD  # Review all changes
# Create or update PR for next day review

# After PR approved: merge and cleanup
git checkout develop
git pull origin develop
git merge feature/something
git push origin develop
git branch -d feature/something
```

