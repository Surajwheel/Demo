# Git Branching Strategies for Kubernetes Microservices - Complete Guide

## 📋 Document Overview

This comprehensive guide provides everything you need to implement Git branching strategies for your Kubernetes microservices project. 

### Files Included

1. **GIT-BRANCHING-STRATEGIES.md** (Core Strategy)
   - 4 main branching models explained
   - Pros and cons of each approach
   - Implementation steps
   - Best practices
   - Recommended hybrid strategy

2. **GIT-CONFIG-FILES.md** (Setup & Configuration)
   - .gitmessage template
   - .gitignore for Kubernetes/Docker
   - GitHub CODEOWNERS
   - CI/CD workflows (GitHub Actions, GitLab)
   - Makefile for common commands
   - Pre-commit hooks
   - Issue and PR templates

3. **GIT-WORKFLOW-PRACTICAL-GUIDE.md** (Day-to-Day)
   - Step-by-step workflow examples
   - Common scenarios and solutions
   - Troubleshooting guide
   - Useful Git aliases
   - Team workflow process
   - Git commands organized by use case

4. **GIT-QUICK-REFERENCE.md** (Quick Start)
   - Decision matrix for choosing strategy
   - Implementation checklist
   - Branch naming conventions
   - Commit message examples
   - CI/CD pipeline integration
   - Protection rules configuration
   - Quick command reference

---

## 🚀 Quick Start (5 Minutes)

### 1. Choose Your Strategy

For your Kubernetes microservices project, we recommend:

**Hybrid Approach (Trunk-Based + Environment-Based)**

```
main (production) ← staging (pre-prod) ← develop (dev) ← feature branches
```

### 2. Initial Setup

```bash
# Clone your repository
git clone <your-repo-url>
cd your-k8s-microservices

# Configure Git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config commit.template .gitmessage
git config core.hooksPath .githooks

# Create commit message template
cat > .gitmessage << 'EOF'
<type>(<scope>): <subject>

# Description, why, what changed
# Example: feat(user-service): add JWT authentication

# Types: feat, fix, docs, style, refactor, perf, test, ci, infra, chore
# Scopes: user-service, product-service, order-service, k8s, monitoring
EOF

# Make first commit
git add .gitmessage
git commit -m "docs: add commit message template"
git push origin develop
```

### 3. Create Branch Protection Rules

On GitHub:
- Go to Settings → Branches
- Add rule for `main`: Require 2 approvals
- Add rule for `develop`: Require 1 approval
- Add rule for `staging`: Require 1 approval

### 4. Start Development

```bash
# Create feature branch
git checkout develop
git pull origin develop
git checkout -b feature/PROJ-123-user-authentication

# Make changes and commit
git add user-service.yaml
git commit
# (editor opens with template, fill in details)

# Keep updated
git fetch origin
git rebase origin/develop

# Push and create PR
git push origin feature/PROJ-123-user-authentication
# Create pull request on GitHub
```

---

## 📊 Strategy Comparison

### Trunk-Based Development
- **Best for:** Continuous deployment, small teams
- **Release frequency:** Multiple times per day
- **Branch lifetime:** 1-2 days
- **Merge strategy:** Squash and merge
- **Complexity:** Low
- **Example:** Netflix, Google, Facebook

### Git Flow
- **Best for:** Scheduled releases, multiple versions
- **Release frequency:** Weekly/Monthly
- **Branch lifetime:** Days to weeks
- **Merge strategy:** Merge commit
- **Complexity:** High
- **Example:** Some enterprise apps

### GitHub Flow
- **Best for:** Simple, web-focused projects
- **Release frequency:** Daily
- **Branch lifetime:** 1-3 days
- **Merge strategy:** Squash and merge
- **Complexity:** Low-Medium
- **Example:** GitHub itself

### Environment-Based (Recommended for Your Project)
- **Best for:** Multi-environment deployments
- **Release frequency:** Scheduled
- **Branch lifetime:** varies by environment
- **Merge strategy:** Merge commits
- **Complexity:** Medium
- **Example:** Enterprise microservices

---

## 📁 Recommended Branch Structure

```
main (production-ready, always deployable)
  ↓ (PR + 2 approvals)
staging (pre-production, final testing)
  ↓ (PR + 1 approval)
develop (development/integration)
  ↓ (PR + 1 approval)
feature/PROJ-123-description (short-lived, < 3 days)
bugfix/PROJ-456-issue-name
hotfix/PROJ-789-critical-fix
```

### Branch Policies

| Branch | Protected | Deploy | Delete After | Reviews |
|--------|-----------|--------|---------------|---------|
| main | Yes | Prod | No | 2 required |
| staging | Yes | Staging | No | 1 required |
| develop | Yes | Dev | No | 1 required |
| feature/* | No | None (test only) | Auto-yes | 1 optional |
| bugfix/* | No | None (test only) | Auto-yes | 1 optional |
| hotfix/* | No | None (test) | Auto-yes | 1 required |

---

## 💾 Commit Message Convention

### Format
```
<type>(<scope>): <subject>

<body (why and what)>

<footer (references)>
```

### Examples

```
# Feature
feat(user-service): add JWT authentication
- Implement token generation and validation
- Add auth middleware for protected endpoints
- Update deployment with auth config
Fixes #123

# Bug fix
fix(redis): resolve connection timeout
- Increase connection pool from 10 to 50
- Add exponential backoff for retries
- Update resource limits in deployment
Fixes #456

# Infrastructure
infra(k8s): upgrade prometheus monitoring
- Update prometheus-values.yaml to v45.0.0
- Add new ServiceMonitors for services
- Add alert rules for error rates > 5%
Related-To: #789

# Documentation
docs: add git branching strategy guide

# Chore
chore(deps): bump kubernetes version to 1.27
```

### Types
```
feat:     New feature
fix:      Bug fix
docs:     Documentation
style:    Formatting (no code change)
refactor: Code refactoring
perf:     Performance improvement
test:     Tests only
ci:       CI/CD configuration
infra:    Kubernetes/Infrastructure
chore:    Build, deps, etc
```

---

## 🔄 Daily Workflow

### Step 1: Start Your Day
```bash
git checkout develop
git pull origin develop
git fetch origin
```

### Step 2: Create Feature Branch
```bash
git checkout -b feature/PROJ-123-add-caching
```

### Step 3: Make Changes
```bash
# Edit your files
git add changed-files.yaml
git commit  # Use template
git push origin feature/PROJ-123-add-caching
```

### Step 4: Create Pull Request
```
Title: feat(user-service): add response caching

Description:
## Description
Implements Redis-based caching for user queries

## Related Issues
Fixes #123

## Changes
- Add Redis client to user service
- Cache GET /users endpoints
- Implement cache invalidation on POST/PUT
- Add cache metrics to Prometheus

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing in dev

## Checklist
- [x] Code follows style guide
- [x] Tests added
- [x] Documentation updated
- [x] CHANGELOG updated
```

### Step 5: Keep Updated (During Review)
```bash
git fetch origin
git rebase origin/develop
git push origin feature/PROJ-123-add-caching --force-with-lease
```

### Step 6: Address Feedback
```bash
# Make changes
git add files.yaml
git commit --amend --no-edit
git push origin feature/PROJ-123-add-caching --force-with-lease
```

### Step 7: After Approval
```bash
# Merge to develop
git checkout develop
git pull origin develop
git merge feature/PROJ-123-add-caching
git push origin develop

# Cleanup
git branch -d feature/PROJ-123-add-caching
git push origin --delete feature/PROJ-123-add-caching
```

---

## 🛠️ Setting Up Automation

### GitHub Actions Workflows

Create `.github/workflows/ci.yml`:
```yaml
name: CI

on:
  push:
    branches: [main, develop, staging, feature/*, bugfix/*, hotfix/*]
  pull_request:
    branches: [main, develop, staging]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: yamllint k8s/
      - run: shellcheck scripts/*.sh

  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: kubeval $(find . -name "*.yaml")

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: npm test
      - run: npm run coverage
```

Create `.github/workflows/cd-develop.yml`:
```yaml
name: CD - Develop

on:
  push:
    branches: [develop]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to dev
        run: kubectl apply -f k8s/dev/ -n dev-microservices
```

---

## 🔐 Branch Protection Rules

### Main Branch Protection

```
✓ Require pull request reviews before merging
  - Required approving reviews: 2
  - Dismiss stale pull request approvals
  - Require review from code owners

✓ Require status checks to pass before merging
  - ci/build
  - ci/test
  - ci/lint
  - ci/security

✓ Require conversation resolution before merging

✓ Require branches to be up to date before merging

✓ Require signed commits

✓ Restrict who can push to matching branches
  - Maintainers only

✓ Allow auto-merge
  - Squash and merge
```

### Develop Branch Protection

```
✓ Require pull request reviews: 1
✓ Require status checks: Yes
✓ Auto-merge enabled: Yes
```

---

## 👥 Team Roles

### Developer
- Create feature branches from develop
- Write clear commit messages
- Keep branch up to date
- Create PRs with descriptions
- Request reviews
- Respond to feedback

### Code Reviewer
- Review PRs within 24 hours
- Check code quality
- Verify tests pass
- Check for security issues
- Provide constructive feedback
- Approve when satisfied

### Tech Lead
- Approve PRs to main
- Manage releases
- Create hotfix branches
- Update CHANGELOG
- Merge PRs
- Tag releases

### DevOps
- Review infrastructure changes
- Manage secrets
- Monitor deployments
- Set up automation
- Manage protection rules

---

## 🆘 Troubleshooting

### Problem: Committed to wrong branch
```bash
git branch feature/correct-place  # Create from current
git reset --hard origin/main      # Reset main
git checkout feature/correct-place # Go to correct branch
```

### Problem: Merge conflict
```bash
git fetch origin
git rebase origin/develop
# Edit files to resolve conflicts
git add resolved-files.yaml
git rebase --continue
git push origin feature/something --force-with-lease
```

### Problem: Forgot to add file
```bash
git add forgotten-file.yaml
git commit --amend --no-edit
git push origin feature/something --force-with-lease
```

### Problem: Need to undo commits
```bash
# Safe way - create reverse commit
git revert abc1234
git commit -m "revert: undo previous changes"
git push origin develop

# Dangerous way - rewrite history (feature only!)
git reset --soft HEAD~3  # Undo last 3 commits
```

---

## 📚 Additional Resources

### Git Learning
- Git Documentation: https://git-scm.com/doc
- Interactive Learning: https://learngitbranching.js.org/
- Conventional Commits: https://www.conventionalcommits.org/

### Kubernetes
- K3d: https://k3d.io/
- Kubernetes: https://kubernetes.io/
- Helm: https://helm.sh/

### CI/CD
- GitHub Actions: https://docs.github.com/en/actions
- GitLab CI: https://docs.gitlab.com/ee/ci/

---

## ✅ Implementation Checklist

### Initial Setup
```
☐ Create Git repository
☐ Set default branch to develop
☐ Create main and staging branches
☐ Add branch protection rules
☐ Create .gitmessage template
☐ Create .githooks/ directory
☐ Create .github/CODEOWNERS
☐ Create .github/workflows/ CI/CD files
☐ Create BRANCHING.md documentation
☐ Train team on workflow
```

### Before First Release
```
☐ Set up CI/CD pipelines
☐ Configure secret management
☐ Set up artifact storage
☐ Configure auto-deployments
☐ Set up monitoring/logging
☐ Create runbooks for operations
☐ Test hotfix workflow
☐ Document manual processes
```

### Ongoing
```
☐ Monthly review of Git workflow
☐ Update protection rules as needed
☐ Clean up stale branches
☐ Monitor CI/CD performance
☐ Update team documentation
☐ Collect team feedback
☐ Optimize automation
```

---

## 🎯 Success Metrics

Track these to ensure your Git workflow is working well:

```
☐ Average PR review time: < 24 hours
☐ Average time to merge: < 48 hours
☐ Merge conflicts per week: < 1
☐ Failed deployments: < 1%
☐ Team satisfaction: > 4/5
☐ Documentation up-to-date: 100%
☐ CI/CD pass rate: > 95%
☐ Feature velocity: tracked
☐ Release frequency: on schedule
☐ Hotfix resolution time: < 1 hour
```

---

## 📞 Getting Help

### Common Questions

**Q: Can I push directly to main?**
A: No, main is protected. All changes require PR and 2 approvals.

**Q: How long should feature branches live?**
A: 1-3 days maximum. Longer branches = more conflicts.

**Q: Should I squash or merge?**
A: Squash for develop/staging, merge for main (keeps history).

**Q: What if I commit secrets?**
A: Rotate immediately, then use git filter-branch to remove.

**Q: Can I work on multiple features simultaneously?**
A: Yes, use different branches. Switch with `git checkout`.

**Q: How do I handle breaking changes?**
A: Document in CHANGELOG, use major version bump (semver).

**Q: What's the difference between rebase and merge?**
A: Rebase rewrites history (cleaner), merge preserves history (safer).

---

## 📝 Next Steps

1. **Read the main document:** `GIT-BRANCHING-STRATEGIES.md`
2. **Set up configuration:** `GIT-CONFIG-FILES.md`
3. **Learn the workflow:** `GIT-WORKFLOW-PRACTICAL-GUIDE.md`
4. **Keep this handy:** `GIT-QUICK-REFERENCE.md`
5. **Train your team**
6. **Implement gradually**
7. **Collect feedback**
8. **Refine as needed**

---

## 📄 Document Summary

| Document | Purpose | Length | Best For |
|----------|---------|--------|----------|
| GIT-BRANCHING-STRATEGIES.md | Core concepts & strategies | 30 min read | Understanding options |
| GIT-CONFIG-FILES.md | Setup & configuration | 40 min read | Implementation |
| GIT-WORKFLOW-PRACTICAL-GUIDE.md | Day-to-day workflows | 30 min read | Daily reference |
| GIT-QUICK-REFERENCE.md | Quick lookup | 20 min read | Quick decisions |

---

## 🙏 Thank You

This guide is designed to help your Kubernetes microservices project maintain clean, organized code history while supporting rapid development and safe deployments.

**Remember:** The best Git workflow is the one your team actually uses consistently. Start simple, iterate, and improve over time.

Good luck! 🚀

