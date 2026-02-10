# Git Branching Strategy: Quick Reference & Decision Matrix

## Decision Matrix: Which Strategy Should You Use?

### For Your Kubernetes Microservices Project

```
┌─────────────────────────────────────────────────────────────────┐
│                    CHOOSE YOUR STRATEGY                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Question 1: How often do you deploy?                           │
│  ├─ Multiple times per day     → TRUNK-BASED DEVELOPMENT        │
│  ├─ Once per day               → GITHUB FLOW                    │
│  ├─ Weekly/Monthly             → GIT FLOW                       │
│  └─ Multiple environments      → ENVIRONMENT-BASED (HYBRID)     │
│                                                                  │
│  Question 2: Team size and experience?                          │
│  ├─ Small (< 5 devs), experienced    → TRUNK-BASED              │
│  ├─ Small to medium (5-10 devs)      → GITHUB FLOW              │
│  ├─ Large (> 10 devs) or distributed → GIT FLOW                 │
│  └─ Need strict control              → ENVIRONMENT-BASED        │
│                                                                  │
│  Question 3: Release strategy?                                  │
│  ├─ Continuous deployment (CD)       → TRUNK-BASED              │
│  ├─ Multiple versions in production  → GIT FLOW                 │
│  ├─ Staged rollout (dev→staging→prod)→ ENVIRONMENT-BASED        │
│  └─ Feature flags with master only   → GITHUB FLOW              │
│                                                                  │
│  RECOMMENDATION FOR THIS PROJECT:                               │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Trunk-Based Development + Environment Branching (Hybrid)│   │
│  │                                                          │   │
│  │ Why:                                                     │   │
│  │ • Supports local development (develop branch)           │   │
│  │ • Staged promotion (dev→staging→prod)                   │   │
│  │ • Fast iteration with automatic testing                 │   │
│  │ • Good for microservices architecture                   │   │
│  │ • Scales with team growth                               │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Recommended Strategy: Hybrid Approach

### Branch Structure

```
┌─────────────────────────────────────┐
│         main (production)           │
│  (tagged, protected, 2x review)     │
├─────────────────────────────────────┤
│  Used for: Prod deployments only    │
│  Protected: Yes                     │
│  Auto-deploy: Yes (prod namespace)  │
│  Delete after merge: No             │
└─────────────────────────────────────┘
                  ↑
              (PR review)
                  │
┌─────────────────────────────────────┐
│       staging (pre-production)       │
│  (protected, 1x review required)    │
├─────────────────────────────────────┤
│  Used for: Final testing & approval │
│  Protected: Yes                     │
│  Auto-deploy: Yes (staging NS)      │
│  Delete after merge: No             │
└─────────────────────────────────────┘
                  ↑
              (PR review)
                  │
┌─────────────────────────────────────┐
│         develop (integration)        │
│  (protected, 1x review required)    │
├─────────────────────────────────────┤
│  Used for: Integration & testing    │
│  Protected: Yes                     │
│  Auto-deploy: Yes (dev namespace)   │
│  Delete after merge: No             │
└─────────────────────────────────────┘
                  ↑
              (PR review)
                  │
┌─────────────────────────────────────┐
│      feature/* (short-lived)        │
│      bugfix/*  (short-lived)        │
│      hotfix/*  (short-lived)        │
│  (unprotected, auto CI/CD)          │
├─────────────────────────────────────┤
│  Used for: Feature/bugfix work      │
│  Protected: No                      │
│  Auto-deploy: No (testing only)     │
│  Delete after merge: Yes (automatic)│
│  Lifetime: 1-3 days max             │
└─────────────────────────────────────┘
```

---

## Implementation Checklist

### Week 1: Initial Setup

```bash
☐ Choose branching strategy (use recommended hybrid)
☐ Set up main branch protection rules (2 approvals)
☐ Set up staging branch protection rules (1 approval)
☐ Set up develop branch protection rules (1 approval)
☐ Create .github/CODEOWNERS file
☐ Create branch protection rules as code
☐ Set up commit message template (.gitmessage)
☐ Create pre-commit hooks (.githooks/)
☐ Set up GitHub Actions CI/CD workflows
☐ Document in BRANCHING.md or wiki
```

### Week 2: Team Onboarding

```bash
☐ Schedule team training on Git workflow
☐ Pair with developers on first PR
☐ Create checklists for common tasks
☐ Set up Slack notifications for PRs
☐ Define PR naming conventions
☐ Define commit message examples
☐ Test emergency hotfix workflow
☐ Create runbook for broken main branch
```

### Week 3: Automation

```bash
☐ Set up automatic branch deletion on merge
☐ Set up automatic status checks
☐ Set up dependency updates (Dependabot)
☐ Set up auto-merge for dependencies
☐ Set up merge queue for main branch
☐ Create automation for version bumping
☐ Create automation for release tags
☐ Create automation for CHANGELOG updates
```

### Week 4: Refinement

```bash
☐ Collect feedback from team
☐ Adjust protection rules if needed
☐ Optimize CI/CD pipeline
☐ Create troubleshooting guide
☐ Schedule monthly process review
☐ Document lessons learned
☐ Plan improvements for next month
```

---

## Branch Naming Convention

### Format

```
<type>/<ticket-id>-<short-description>

Examples:
feature/PROJ-123-user-authentication
bugfix/PROJ-456-cache-invalidation
hotfix/PROJ-789-security-patch
infra/upgrade-prometheus-stack
docs/deployment-guide
test/add-integration-tests
refactor/user-service-cleanup
```

### Types

```
feature/   → New functionality
bugfix/    → Fix for non-critical issue
hotfix/    → Emergency fix for production issue
infra/     → Infrastructure/deployment changes
docs/      → Documentation updates
test/      → Test additions/modifications
refactor/  → Code refactoring
perf/      → Performance improvements
chore/     → Maintenance, dependencies, etc
ci/        → CI/CD configuration changes
```

---

## Commit Message Convention

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Examples by Service

```
# User Service
feat(user-service): add email validation
fix(user-service): resolve memory leak in auth handler
refactor(user-service): simplify JWT token generation

# Product Service
feat(product-service): add product caching layer
fix(product-service): correct MongoDB query for filters
perf(product-service): optimize search performance

# Order Service
feat(order-service): implement order status notifications
fix(order-service): resolve concurrent order processing
infra(order-service): upgrade to new base image

# Infrastructure
infra(k8s): upgrade Prometheus monitoring stack
infra(k8s): add network policies for microsvc communication
infra(redis): increase memory limit for cache

# Monitoring
infra(monitoring): add custom Prometheus metrics
infra(monitoring): create Grafana dashboard for services
infra(monitoring): add alert rules for error rates

# General
docs: update deployment guide
ci: add security scanning to pipeline
test: add integration tests for order service
```

---

## Daily Workflow Checklist

### Start of Day

```
☐ Pull latest from develop: git pull origin develop
☐ Check for conflicts: git status
☐ Review PR comments if any
☐ Start feature work: git checkout -b feature/PROJ-XYZ-...
```

### During Development

```
☐ Commit often (every 1-2 hours)
☐ Use proper commit messages
☐ Push daily: git push origin feature/...
☐ Rebase to latest: git rebase origin/develop
☐ Run local tests: npm test
```

### End of Day

```
☐ Push all changes: git push origin feature/...
☐ Create/update PR if first time
☐ Add summary comment to PR
☐ Request review from team
☐ Leave notes for next day
```

### PR Review

```
☐ Request at least 1 reviewer
☐ Link to relevant issues
☐ Wait for CI/CD to pass
☐ Respond to feedback promptly
☐ Make requested changes
☐ Push amended commits (force-with-lease)
```

### Merging

```
☐ All checks pass (green)
☐ At least 1 approval (2 for main)
☐ No conflicts with base branch
☐ Squash-and-merge for develop/staging
☐ Merge commit for main (keeps history)
☐ Delete feature branch
☐ Close related issues
```

---

## CI/CD Pipeline Integration

### Branch Triggers

```
Feature/Bugfix Branches:
├─ Trigger: Any push to feature/*, bugfix/*, hotfix/*
├─ Actions:
│  ├─ Lint (YAML, shell scripts)
│  ├─ Validate Kubernetes manifests
│  ├─ Security scan (dependencies, secrets)
│  ├─ Unit tests
│  ├─ Integration tests
│  └─ Build Docker images (no push)
└─ Artifacts: Test reports, coverage

Develop Branch:
├─ Trigger: PR merge to develop
├─ Actions:
│  ├─ All from feature branches
│  ├─ Build and tag Docker images
│  ├─ Push to staging registry
│  ├─ Deploy to dev namespace
│  ├─ Run smoke tests
│  └─ Notify Slack
└─ Environment: dev-microservices (k3d)

Staging Branch:
├─ Trigger: PR merge to staging
├─ Actions:
│  ├─ All CI checks
│  ├─ Build and tag Docker images
│  ├─ Push to registry
│  ├─ Deploy to staging namespace
│  ├─ Run full test suite
│  ├─ Monitor metrics
│  └─ Notify QA team
└─ Environment: staging-microservices

Main Branch:
├─ Trigger: PR merge to main (manual approval)
├─ Actions:
│  ├─ All CI checks
│  ├─ Create release notes
│  ├─ Build final Docker images
│  ├─ Push to production registry
│  ├─ Deploy to prod namespace (blue-green)
│  ├─ Run smoke tests
│  ├─ Create GitHub release
│  ├─ Tag commit with version
│  └─ Notify team & customers
└─ Environment: prod-microservices
```

---

## Troubleshooting Quick Reference

### Problem: Accidentally committed to main

```bash
# Solution:
git log --oneline -5  # Find your commit hash (abc1234)
git reset --soft abc1234^  # Undo commit, keep changes
git stash  # Save changes
git checkout main
git reset --hard origin/main  # Back to origin
git checkout -b feature/correct-branch
git stash pop  # Apply changes
git commit -m "feat: correct commit message"
git push origin feature/correct-branch
```

### Problem: Merge conflict in k8s manifests

```bash
# Solution:
git fetch origin
git rebase origin/develop

# Resolve conflicts in files
# Look for <<<<<<< and >>>>>>>
# Keep necessary parts from both sides

git add resolved-files.yaml
git rebase --continue
git push origin feature/something --force-with-lease
```

### Problem: Branch is way behind main

```bash
# Solution:
git fetch origin
git rebase -i origin/main

# Or if rebase is too complex:
git reset origin/main
git add .
git commit -m "feat: consolidated changes from main"
git push origin feature/something --force-with-lease
```

### Problem: Need to undo published commits

```bash
# Solution - Don't force push to main/develop
# Instead:
git revert abc1234  # Creates inverse commit
git commit -m "revert: undo previous changes"
git push origin develop
```

### Problem: Accidentally pushed secrets

```bash
# Solution:
# 1. Rotate the secret immediately
# 2. Remove from Git history:
git filter-branch --tree-filter 'rm -f secret-file' -- --all
git push origin --force --all
# 3. Remove from all branches and tags
git for-each-ref --format='delete %(refname)' refs/original | git update-ref --stdin
git reflog expire --expire=now --all
git gc --prune=now
# 4. Update CODEOWNERS to catch this in future
```

---

## Team Roles and Responsibilities

### Developer

```
✓ Create feature branches from develop
✓ Write clear commit messages
✓ Keep branch up to date
✓ Create PRs with good descriptions
✓ Request reviews from appropriate people
✓ Respond to feedback within 24 hours
✓ Rebase/squash before merge
✗ Cannot: Push directly to main/develop
✗ Cannot: Merge own PR without review
```

### Code Reviewer

```
✓ Review PR within 24 hours
✓ Check code quality and standards
✓ Check tests are passing
✓ Check for security issues
✓ Provide constructive feedback
✓ Approve when satisfied
✓ Test in dev environment if needed
✗ Cannot: Merge PR without developer response
```

### Tech Lead / Maintainer

```
✓ Approve PRs to main/develop
✓ Decide on architecture/design issues
✓ Manage releases and versioning
✓ Create hotfix branches
✓ Merge PRs to main
✓ Tag releases
✓ Update CHANGELOG
✓ Review team's Git practices
```

### DevOps / Infrastructure

```
✓ Review infra/*.yaml changes
✓ Review Kubernetes manifest changes
✓ Review CI/CD configuration
✓ Manage secrets and credentials
✓ Monitor deployments
✓ Create automation for releases
✓ Manage branch protection rules
```

---

## Protection Rules Configuration

### For Main Branch

```yaml
- Branch name pattern: main
- Require pull request reviews before merging:
  ✓ Enabled
  ✓ Required number of approvals: 2
  ✓ Dismiss stale PR approvals: Yes
  ✓ Require review from code owners: Yes
- Require status checks to pass:
  ✓ Enabled
  ✓ Require branches to be up to date: Yes
  ✓ Required checks:
    - ci/build
    - ci/test
    - ci/lint
    - ci/security
    - ci/k8s-validate
- Additional restrictions:
  ✓ Require conversation resolution: Yes
  ✓ Require signed commits: Yes
  ✓ Require linear history: Yes
  ✓ Restrict who can push: Enable
    - Allow: Maintainers only
  ✓ Allow auto-merge: Yes (squash)
```

### For Develop/Staging Branches

```yaml
- Branch name pattern: develop|staging
- Require pull request reviews:
  ✓ Enabled
  ✓ Required number of approvals: 1
  ✓ Dismiss stale PR approvals: Yes
- Require status checks:
  ✓ Enabled
  ✓ Require branches up to date: Yes
  ✓ Required checks:
    - ci/build
    - ci/test
    - ci/lint
    - ci/k8s-validate
- Allow auto-merge: Yes
```

### For Feature Branches

```yaml
- Branch name pattern: feature/*|bugfix/*|hotfix/*
- No protection rules
- CI/CD runs automatically
```

---

## Quick Command Reference

### Setup

```bash
git config --global user.name "Your Name"
git config --global user.email "email@example.com"
git config --global pull.rebase true
git config --global fetch.prune true
git config commit.template .gitmessage
git config core.hooksPath .githooks
```

### Create & Switch

```bash
git checkout develop                    # Switch to develop
git pull origin develop                 # Get latest
git checkout -b feature/PROJ-123-...   # Create feature
```

### Commit

```bash
git status                              # See changes
git diff                                # Review changes
git add file.yaml                       # Stage file
git commit                              # Opens editor with template
git commit --amend                      # Fix last commit
```

### Push & PR

```bash
git push origin feature/PROJ-123-...    # Push feature
# Create PR on GitHub/GitLab

# After review and approval:
git checkout develop
git pull origin develop
git merge feature/PROJ-123-...
git push origin develop
git branch -d feature/PROJ-123-...
git push origin --delete feature/PROJ-123-...
```

### Keep Updated

```bash
git fetch origin                        # Get updates
git rebase origin/develop               # Update feature
git push origin feature/... --force-with-lease
```

---

## Links and Resources

### Git Learning

- Git Documentation: https://git-scm.com/doc
- Git Branching Guide: https://git-scm.com/book/en/v2
- Interactive Git Learning: https://learngitbranching.js.org/

### Kubernetes

- Official Docs: https://kubernetes.io/docs/
- Helm: https://helm.sh/
- K3d: https://k3d.io/

### CI/CD

- GitHub Actions: https://docs.github.com/en/actions
- GitLab CI: https://docs.gitlab.com/ee/ci/
- Jenkins: https://www.jenkins.io/doc/

### Best Practices

- Conventional Commits: https://www.conventionalcommits.org/
- Semantic Versioning: https://semver.org/
- Git Flow: https://nvie.com/posts/a-successful-git-branching-model/

