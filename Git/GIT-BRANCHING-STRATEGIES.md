# Git Branching Strategies for Kubernetes Microservices

## Table of Contents
1. [Overview](#overview)
2. [Branching Models](#branching-models)
3. [Implementation Guide](#implementation-guide)
4. [Branch Protection Rules](#branch-protection-rules)
5. [Workflow Examples](#workflow-examples)
6. [Best Practices](#best-practices)

---

## Overview

This document outlines Git branching strategies for managing microservices in Kubernetes environments. We'll cover multiple strategies suitable for different team sizes and deployment models.

### Branching Strategy Decision Tree
```
Are you deploying continuously?
├─ YES → Use Trunk-Based Development
├─ NO → Use Git Flow or GitHub Flow based on release frequency
```

---

## Branching Models

### 1. TRUNK-BASED DEVELOPMENT (Recommended for CI/CD)

**Best for:** Continuous deployment, small teams, fast iteration

```
main (production)
  ↑
  ├─ feature/user-auth
  ├─ feature/api-gateway
  ├─ bugfix/cache-issue
  └─ hotfix/security-patch
```

**Characteristics:**
- Single main branch
- Short-lived feature branches (1-3 days max)
- Frequent merges to main
- Automated testing required
- Production deployments multiple times per day

**Branch Naming:**
```
feature/feature-name
bugfix/issue-number
hotfix/critical-issue
docs/documentation-update
refactor/code-improvement
test/test-coverage
infra/infrastructure-change
```

---

### 2. GIT FLOW (For Scheduled Releases)

**Best for:** Scheduled releases, multiple environments, large teams

```
main (production)
  ↑
  ├─ release/1.2.0
  │   ↑
  │   └─ bugfix/release-issues
  │
develop (staging)
  ↑
  ├─ feature/user-service
  ├─ feature/product-service
  ├─ feature/order-service
  └─ bugfix/minor-issues

hotfix/critical-issue
  ↑
  └─ main (for emergency fixes)
```

**Characteristics:**
- Two main branches: `main` and `develop`
- `main` = production-ready
- `develop` = integration branch
- Release and hotfix branches for controlled releases
- Well-suited for scheduled releases

**Branch Naming:**
```
feature/JIRA-123-user-authentication
release/1.2.0
hotfix/1.1.1-security-patch
bugfix/JIRA-456-cache-leak
docs/user-service-readme
```

---

### 3. GITHUB FLOW (Simple & Effective)

**Best for:** Small teams, web applications, frequent deployments

```
main (production)
  ↑
  ├─ feature/user-service-refactor
  ├─ feature/add-metrics
  ├─ bugfix/memory-leak
  └─ docs/deployment-guide
```

**Characteristics:**
- Single `main` branch (always production-ready)
- Feature branches for all changes
- Pull requests for code review
- Merge to main triggers deployment
- Simpler than Git Flow

**Branch Naming:**
```
feature/description
bugfix/issue-number
docs/topic
infra/k8s-upgrade
```

---

### 4. ENVIRONMENT-BASED BRANCHING (Multi-Environment)

**Best for:** Multiple deployment environments (dev, staging, prod)

```
main (production)
  ↑
  │
staging (staging environment)
  ↑
  │
develop (development environment)
  ↑
  ├─ feature/user-service
  ├─ feature/product-service
  └─ bugfix/database-issue
```

**Flow:**
```
feature/something
    ↓ PR to develop
develop (deploy to dev namespace)
    ↓ PR to staging
staging (deploy to staging namespace)
    ↓ PR to main
main (deploy to production)
```

---

## Implementation Guide

### Setup for Trunk-Based Development

```bash
# Clone repository
git clone <repo-url>
cd k8s-microservices

# Create feature branch
git checkout -b feature/user-service-auth

# Make changes
git add .
git commit -m "feat(user-service): add authentication"

# Push to remote
git push origin feature/user-service-auth

# Create Pull Request on GitHub/GitLab
# After review and approval, merge to main
git checkout main
git pull origin main
git merge feature/user-service-auth
git push origin main

# Clean up
git branch -d feature/user-service-auth
git push origin --delete feature/user-service-auth
```

### Setup for Git Flow

```bash
# Install git-flow (optional but recommended)
# macOS
brew install git-flow

# Linux
sudo apt-get install git-flow

# Initialize git-flow
git flow init
# Follow prompts (press enter for defaults)

# Start feature
git flow feature start user-service

# Finish feature (merges to develop)
git flow feature finish user-service

# Start release
git flow release start 1.2.0

# Finish release (merges to main and develop)
git flow release finish 1.2.0

# Create hotfix
git flow hotfix start 1.1.1

# Finish hotfix
git flow hotfix finish 1.1.1
```

### Setup for Environment-Based

```bash
# Create branches for each environment
git branch develop
git branch staging
git push origin develop staging

# Feature development
git checkout develop
git checkout -b feature/new-feature
# ... make changes ...
git push origin feature/new-feature
# Create PR to develop

# Promote to staging
# Create PR from develop to staging

# Promote to production
# Create PR from staging to main
```

---

## Branch Protection Rules

### For GitHub

#### Main/Production Branch Rules
```yaml
Branch name pattern: main

Protection Settings:
✓ Require a pull request before merging
  - Required approving reviews: 2
  - Dismiss stale pull request approvals when new commits are pushed
  - Require review from code owners
✓ Require branches to be up to date before merging
✓ Require status checks to pass before merging
  - Required checks:
    - ci/build
    - ci/test
    - ci/lint
    - ci/security-scan
✓ Require conversation resolution before merging
✓ Require signed commits
✓ Require linear history
✓ Restrict who can push to matching branches
✓ Allow auto-merge
```

#### Develop/Staging Branch Rules
```yaml
Branch name pattern: develop|staging

Protection Settings:
✓ Require a pull request before merging
  - Required approving reviews: 1
  - Dismiss stale pull request approvals
✓ Require branches to be up to date before merging
✓ Require status checks to pass before merging
  - Required checks:
    - ci/build
    - ci/test
    - ci/lint
✓ Allow auto-merge
```

#### Feature Branch Rules
```yaml
Branch name pattern: feature/*|bugfix/*|hotfix/*

No protection rules needed
- Developers have full control
- CI/CD runs automatically
```

### For GitLab

```yaml
# .gitlab/merge_request_rules.yml
protected_branches:
  - name: main
    push_access:
      - access_level: no_one
    merge_access:
      - access_level: maintainer
    code_owner_approval_required: true
    require_signed_commits: true
    
  - name: develop
    push_access:
      - access_level: no_one
    merge_access:
      - access_level: developer
    require_signed_commits: false
```

---

## Workflow Examples

### Example 1: Trunk-Based Development Workflow

**Scenario:** Add authentication to User Service

```bash
# Step 1: Create feature branch from main
git checkout main
git pull origin main
git checkout -b feature/user-auth

# Step 2: Make changes
# File: 6-user-service.yaml
# - Add auth middleware
# - Add secret configuration
# - Update deployment

git add 6-user-service.yaml
git commit -m "feat(user-service): add JWT authentication

- Add JWT validation middleware
- Configure auth endpoints
- Update service deployment with auth config"

# Step 3: Keep feature branch up to date
git fetch origin
git rebase origin/main

# Step 4: Push and create PR
git push origin feature/user-auth

# Step 5: PR Description
"""
## Description
Add JWT authentication to User Service

## Changes
- JWT token generation and validation
- Auth middleware for protected endpoints
- Updated deployment configuration
- Added tests for auth flows

## Related Issues
Fixes #123

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing in staging
"""

# Step 6: After approval, merge
git checkout main
git pull origin main
git merge --squash feature/user-auth
git push origin main

# Step 7: Cleanup
git branch -d feature/user-auth
git push origin --delete feature/user-auth
```

### Example 2: Git Flow Workflow with Release

**Scenario:** Release version 1.2.0 with multiple features

```bash
# Step 1: Start feature branches from develop
git flow feature start user-service-enhancement
# ... code changes ...
git flow feature finish user-service-enhancement
# Auto-merges to develop and deletes branch

git flow feature start product-service-cache
# ... code changes ...
git flow feature finish product-service-cache

# Step 2: Start release when ready
git flow release start 1.2.0
# Optional: Update version numbers, CHANGELOG

# Step 3: Bugfix in release if needed
git flow bugfix start release-critical-fix
# ... fix changes ...
git flow bugfix finish release-critical-fix

# Step 4: Finish release
git flow release finish 1.2.0
# - Merges to main (with tag v1.2.0)
# - Merges back to develop
# - Deletes release branch

# Step 5: Push everything
git push origin main develop --tags
```

### Example 3: Environment-Based Workflow

**Scenario:** Progressive promotion through environments

```bash
# Step 1: Create feature on develop
git checkout develop
git pull origin develop
git checkout -b feature/metrics-dashboard

# Make changes to microservices and Kubernetes manifests
# Example: 6-user-service.yaml, 7-product-service.yaml

git add *.yaml
git commit -m "feat: add metrics dashboard to services"
git push origin feature/metrics-dashboard

# Step 2: PR to develop (dev environment)
# Create PR: feature/metrics-dashboard → develop
# CI/CD deploys to dev namespace
# Testing: kubectl get pods -n dev-microservices

# Step 3: After dev testing, PR to staging
# Create PR: develop → staging
# CI/CD deploys to staging namespace
# Testing: kubectl get pods -n staging-microservices

# Step 4: After staging approval, PR to main
# Create PR: staging → main
# CI/CD deploys to prod namespace
# Testing: kubectl get pods -n prod-microservices

# Step 5: Merge and tag
git checkout main
git merge staging
git tag -a v1.2.0 -m "Release version 1.2.0"
git push origin main --tags
```

---

## Commit Message Conventions

### Conventional Commits Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
```
feat:     New feature
fix:      Bug fix
docs:     Documentation changes
style:    Code style changes (formatting, semicolons, etc.)
refactor: Code refactoring without changing functionality
perf:     Performance improvements
test:     Adding or updating tests
ci:       CI/CD configuration changes
infra:    Infrastructure/deployment changes
chore:    Build process, dependencies, etc.
```

### Examples

```bash
# Feature
git commit -m "feat(user-service): add JWT authentication

- Implement JWT token generation
- Add auth middleware
- Update deployment config"

# Bug fix
git commit -m "fix(redis): resolve connection timeout issue

- Increase connection pool size
- Add retry logic with exponential backoff
- Update service configuration

Fixes #456"

# Infrastructure
git commit -m "infra(k8s): upgrade Prometheus monitoring

- Update prometheus-values.yaml
- Add new ServiceMonitors
- Add alert rules for critical services

Related-To: #789"

# Multiple scopes
git commit -m "feat: add distributed tracing across services

- user-service: add Jaeger middleware
- product-service: add Jaeger middleware
- order-service: add Jaeger middleware"
```

### Commit Template (Save as .gitmessage)

```
<type>(<scope>): <subject>

# Description of the change (wrap at 72 characters)
# Why this change is needed
# What was changed
# Any side effects or breaking changes

# Fixes: #<issue-number>
# Related-To: #<issue-number>

# --- COMMIT TYPE ---
# feat:     A new feature
# fix:      A bug fix
# docs:     Documentation only changes
# style:    Changes that don't affect code meaning
# refactor: Code change that neither fixes a bug nor adds a feature
# perf:     Code change that improves performance
# test:     Adding missing tests or correcting existing tests
# ci:       Changes to CI configuration
# infra:    Infrastructure/deployment changes
```

Setup git to use template:
```bash
git config commit.template .gitmessage
```

---

## Recommended Strategy: Trunk-Based + Environment-Based Hybrid

For your Kubernetes microservices project, we recommend:

### Branch Structure

```
main (production - always deployable)
  ↑
staging (staging environment)
  ↑
develop (development environment)
  ↑
├─ feature/user-service-enhancement
├─ feature/order-service-caching
├─ feature/metrics-dashboard
├─ bugfix/memory-leak-redis
├─ hotfix/security-patch
└─ infra/k8s-upgrade
```

### Workflow

```
1. Feature Development
   ├─ Create branch from develop
   ├─ Keep branch short-lived (< 3 days)
   ├─ Push daily
   └─ Create PR for code review

2. Integration (Develop → Staging)
   ├─ PR to develop (auto-deploy to dev)
   ├─ After approval, PR to staging
   └─ Auto-deploy to staging namespace

3. Release (Staging → Production)
   ├─ PR to main only when ready
   ├─ Requires 2 approvals
   ├─ All checks must pass
   ├─ Create release tag
   └─ Auto-deploy to prod namespace

4. Hotfixes
   ├─ Create hotfix/issue-name from main
   ├─ Fix and test in staging
   ├─ PR directly to main
   ├─ Back-port to develop
   └─ Tag as patch release
```

---

## Best Practices

### 1. Branch Naming Conventions

```
✓ Good:
  feature/user-authentication
  bugfix/404-not-found
  hotfix/database-connection-pool
  infra/prometheus-upgrade

✗ Bad:
  feature
  fix-bug
  update
  john-stuff
  temp-changes
```

### 2. Commit Message Best Practices

```
✓ Good:
  feat(user-service): add JWT authentication
  fix(redis): resolve connection timeout
  infra(k8s): upgrade monitoring stack

✗ Bad:
  fixed stuff
  update code
  WIP
  asdfgh
  multiple changes
```

### 3. Pull Request Guidelines

```
✓ Good PR:
  - Clear, descriptive title
  - Detailed description with context
  - References to issues
  - Small scope (< 400 LOC)
  - One feature per PR
  - All tests passing
  - Ready for immediate merge

✗ Bad PR:
  - Vague title
  - No description
  - Large scope (> 1000 LOC)
  - Multiple unrelated changes
  - Failing tests
  - Work in progress
```

### 4. Code Review Checklist

```
- [ ] Code follows style guide
- [ ] Changes are well-commented
- [ ] No debug code or console logs
- [ ] Tests are added/updated
- [ ] Documentation is updated
- [ ] No security vulnerabilities
- [ ] Performance impact assessed
- [ ] Kubernetes manifests are valid
- [ ] Environment variables documented
- [ ] Backwards compatible or migration plan
```

### 5. Merging Strategy

```
Trunk-Based Development:
├─ Use "Squash and merge"
│  └─ Keeps main history clean
│  └─ One commit per feature
│
Environment-Based:
├─ Use "Create a merge commit"
│  └─ Preserves full feature history
│  └─ Better for traceability
```

### 6. Deletion Policy

```
Delete branches after merge:
- ✓ Automatically via GitHub/GitLab
- ✓ Reduces branch clutter
- ✓ Prevents stale branches

Commands:
git remote prune origin
git branch -vv | grep gone | awk '{print $1}' | xargs git branch -D
```

### 7. Tag Convention

```
Version Tags (Semantic Versioning):
v1.2.3          # Major.Minor.Patch
v1.2.3-rc.1     # Release candidate
v1.2.3-alpha    # Alpha release

Release Tags:
release/1.2.0
release/1.2.1-hotfix

Commit Tags:
commit/abc1234   # Reference specific commits
```

### 8. Syncing Branches

```bash
# Develop from main
git checkout develop
git rebase main

# Feature from develop
git checkout feature/something
git rebase develop

# Stay updated during development
git fetch origin
git rebase origin/develop

# Before merging
git rebase origin/main
git push origin feature/something --force-with-lease
```

### 9. Handling Conflicts

```bash
# During rebase
git fetch origin
git rebase origin/develop
# Fix conflicts in your editor
git add .
git rebase --continue

# If rebase goes wrong
git rebase --abort
git reset --hard origin/develop
git checkout -b feature/something-else
```

---

## Directory Structure with Branching

```
k8s-microservices/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml (runs on all branches)
│   │   ├── cd-develop.yml (deploy to dev)
│   │   ├── cd-staging.yml (deploy to staging)
│   │   └── cd-main.yml (deploy to prod)
│   └── CODEOWNERS
├── .gitlab-ci.yml (for GitLab)
├── k8s/
│   ├── dev/
│   │   ├── namespace.yaml
│   │   ├── services/ (dev configs)
│   │   └── kustomization.yaml
│   ├── staging/
│   │   ├── namespace.yaml
│   │   ├── services/ (staging configs)
│   │   └── kustomization.yaml
│   ├── prod/
│   │   ├── namespace.yaml
│   │   ├── services/ (prod configs)
│   │   └── kustomization.yaml
│   └── base/
│       ├── user-service/
│       ├── product-service/
│       ├── order-service/
│       └── databases/
├── services/
│   ├── user-service/
│   │   ├── src/
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   └── k8s/
│   ├── product-service/
│   ├── order-service/
│   └── api-gateway/
├── terraform/ (for infrastructure)
├── docs/
├── CHANGELOG.md
├── .gitmessage
└── README.md
```

---

## CI/CD Integration with Branching

### GitHub Actions Example

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [ main, develop, staging, feature/*, bugfix/*, hotfix/* ]
  pull_request:
    branches: [ main, develop, staging ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: npm test
      - name: Run linting
        run: npm run lint

# .github/workflows/cd-develop.yml
name: CD - Develop

on:
  push:
    branches: [ develop ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to dev
        run: kubectl apply -f k8s/dev/ --namespace=dev-microservices

# .github/workflows/cd-main.yml
name: CD - Production

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to production
        run: kubectl apply -f k8s/prod/ --namespace=prod-microservices
```

---

## Summary Table

| Strategy | Team Size | Release Frequency | Complexity | Best For |
|----------|-----------|-------------------|------------|----------|
| Trunk-Based | Small | Continuous | Low | CI/CD, rapid iteration |
| Git Flow | Large | Scheduled | High | Planned releases, multiple versions |
| GitHub Flow | Small-Medium | Frequent | Low-Medium | Web apps, simple workflows |
| Environment-Based | Medium-Large | Scheduled | Medium-High | Multi-env deployments, controlled rollouts |
| Hybrid (Recommended) | Medium | Frequent | Medium | Balanced approach, flexibility |

