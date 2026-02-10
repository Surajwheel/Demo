# Git Configuration Files for Kubernetes Microservices

## 1. .gitmessage - Commit Message Template

```
<type>(<scope>): <subject>

# Description of the change
# Why this change is needed
# What problem does it solve

# Fixes: #<issue-number>
# Related-To: #<issue-number>
# Breaking-Change: (if applicable)

# --- COMMIT TYPE ---
# feat:     New feature
# fix:      Bug fix
# docs:     Documentation only
# style:    Code style changes (formatting, semicolons, etc)
# refactor: Code refactoring
# perf:     Performance improvements
# test:     Tests only
# ci:       CI/CD configuration
# infra:    Kubernetes/Infrastructure changes
# chore:    Build process, dependencies

# --- SCOPE EXAMPLES ---
# user-service, product-service, order-service
# api-gateway, auth-service
# database, cache, monitoring
# k8s, docker, helm

# --- SUBJECT LINE RULES ---
# - Use imperative, present tense: "add" not "added"
# - Don't capitalize first letter
# - No period (.) at the end
# - Limit to 50 characters
```

Save as `.gitmessage` in root directory:
```bash
git config --global commit.template .gitmessage
```

---

## 2. .gitignore - Kubernetes and Docker Specific

```
# IDE
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# Node.js
node_modules/
npm-debug.log
yarn-error.log
dist/
build/

# Python
__pycache__/
*.py[cod]
*$py.class
*.egg-info/
.pytest_cache/
venv/
env/

# Java
target/
*.class
*.jar
*.log

# Go
vendor/
*.exe

# Docker
Dockerfile.local
docker-compose.override.yml
.dockerignore

# Kubernetes
kubeconfig
*.kubeconfig
kube-config.yaml
secrets/
.kube/

# Helm
Chart.lock
charts/*/Chart.lock

# k3d
k3d-*.yaml

# Terraform
.terraform/
*.tfstate
*.tfstate.backup
.terraform.lock.hcl
terraform.tfvars

# Environment variables
.env
.env.local
.env.*.local

# Temporary files
*.tmp
*.temp
temp/
tmp/

# Logs
logs/
*.log
npm-debug.log*

# OS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db

# Build artifacts
dist/
build/
output/

# Sensitive data
**/secrets/**
**/.ssh/**
**/*.pem
**/*.key
```

---

## 3. .github/CODEOWNERS - Code Review Owners

```
# Kubernetes Infrastructure
k8s/                                @devops-team
kubernetes/                         @devops-team
*.yaml                             @devops-team
kustomization.yaml                 @devops-team
helm/                              @devops-team

# User Service
services/user-service/             @user-service-team
6-user-service.yaml                @user-service-team

# Product Service
services/product-service/          @product-service-team
7-product-service.yaml             @product-service-team

# Order Service
services/order-service/            @order-service-team
8-order-service.yaml               @order-service-team

# Database schemas
3-postgresql.yaml                  @database-team
5-mongodb.yaml                     @database-team
db/                                @database-team

# Monitoring
10-prometheus-servicemonitor.yaml  @platform-team
11-grafana-dashboard.yaml          @platform-team
prometheus-values.yaml             @platform-team

# Documentation
*.md                               @tech-writers
docs/                              @tech-writers

# CI/CD
.github/workflows/                 @devops-team
.gitlab-ci.yml                     @devops-team
Jenkinsfile                        @devops-team

# Configuration
setup.sh                           @devops-team
*.json                             @devops-team

# Root files
README.md                          @tech-leads
CHANGELOG.md                       @tech-leads
```

Save as `.github/CODEOWNERS`

---

## 4. .github/workflows/ci.yml - Continuous Integration

```yaml
name: Continuous Integration

on:
  push:
    branches:
      - main
      - develop
      - staging
      - 'feature/**'
      - 'bugfix/**'
      - 'hotfix/**'
  pull_request:
    branches:
      - main
      - develop
      - staging

jobs:
  lint:
    runs-on: ubuntu-latest
    name: Lint
    steps:
      - uses: actions/checkout@v3
      
      - name: Lint YAML
        uses: adrienverge/yamllint@master
        with:
          file_or_dir: 'k8s/'
          config: 'lint-config.yaml'
      
      - name: Lint Shell Scripts
        uses: ludeeus/action-shellcheck@master
        with:
          scandir: './scripts'

  validate-k8s:
    runs-on: ubuntu-latest
    name: Validate Kubernetes Manifests
    steps:
      - uses: actions/checkout@v3
      
      - name: Install kubeval
        run: |
          wget https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz
          tar xf kubeval-linux-amd64.tar.gz
          sudo mv kubeval /usr/local/bin

      - name: Validate all YAML
        run: |
          find . -name "*.yaml" -type f | grep -v node_modules | xargs kubeval

  docker-build:
    runs-on: ubuntu-latest
    name: Docker Build Test
    strategy:
      matrix:
        service: [user-service, product-service, order-service]
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Build Docker image
        uses: docker/build-push-action@v4
        with:
          context: services/${{ matrix.service }}
          push: false
          tags: localhost/${{ matrix.service }}:latest

  security-scan:
    runs-on: ubuntu-latest
    name: Security Scan
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'
      
      - name: Upload Trivy results to GitHub Security tab
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'

  test:
    runs-on: ubuntu-latest
    name: Run Tests
    strategy:
      matrix:
        node-version: [16.x, 18.x]
    steps:
      - uses: actions/checkout@v3
      
      - name: Use Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v3
        with:
          node-version: ${{ matrix.node-version }}
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run tests
        run: npm test
      
      - name: Generate coverage report
        run: npm run coverage
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/coverage-final.json

  pr-comment:
    runs-on: ubuntu-latest
    name: PR Comment
    if: github.event_name == 'pull_request'
    needs: [lint, validate-k8s, docker-build, test]
    steps:
      - name: Comment on PR
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '✅ All checks passed! This PR is ready for review.'
            })
```

---

## 5. .github/workflows/cd-develop.yml - Deploy to Development

```yaml
name: CD - Development

on:
  push:
    branches:
      - develop

jobs:
  deploy-dev:
    runs-on: ubuntu-latest
    name: Deploy to Development
    environment:
      name: development
      url: https://api-dev.example.com
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up kubectl
        uses: azure/setup-kubectl@v3
        with:
          version: v1.27.0
      
      - name: Configure kubeconfig
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBECONFIG_DEV }}" | base64 -d > $HOME/.kube/config
          chmod 600 $HOME/.kube/config
      
      - name: Deploy databases
        run: |
          kubectl apply -f 1-storage-class.yaml
          kubectl apply -f 2-persistent-volumes.yaml
          kubectl apply -f 3-postgresql.yaml
          kubectl apply -f 4-redis.yaml
          kubectl apply -f 5-mongodb.yaml
        env:
          KUBECONFIG: ${{ secrets.KUBECONFIG_DEV }}
      
      - name: Deploy microservices
        run: |
          kubectl apply -f 6-user-service.yaml
          kubectl apply -f 7-product-service.yaml
          kubectl apply -f 8-order-service.yaml
        env:
          KUBECONFIG: ${{ secrets.KUBECONFIG_DEV }}
      
      - name: Deploy ingress
        run: |
          kubectl apply -f 9-ingress.yaml
        env:
          KUBECONFIG: ${{ secrets.KUBECONFIG_DEV }}
      
      - name: Wait for deployment
        run: |
          kubectl rollout status deployment/user-service -n microservices --timeout=5m
          kubectl rollout status deployment/product-service -n microservices --timeout=5m
          kubectl rollout status deployment/order-service -n microservices --timeout=5m
        env:
          KUBECONFIG: ${{ secrets.KUBECONFIG_DEV }}
      
      - name: Run smoke tests
        run: |
          curl -f http://api-dev.example.com/users/health || exit 1
          curl -f http://api-dev.example.com/products/health || exit 1
      
      - name: Notify Slack
        if: always()
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          text: 'Deployment to dev: ${{ job.status }}'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

---

## 6. .github/workflows/cd-main.yml - Deploy to Production

```yaml
name: CD - Production

on:
  push:
    branches:
      - main
    tags:
      - 'v*.*.*'

jobs:
  deploy-prod:
    runs-on: ubuntu-latest
    name: Deploy to Production
    environment:
      name: production
      url: https://api.example.com
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up kubectl
        uses: azure/setup-kubectl@v3
        with:
          version: v1.27.0
      
      - name: Configure kubeconfig
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBECONFIG_PROD }}" | base64 -d > $HOME/.kube/config
          chmod 600 $HOME/.kube/config
      
      - name: Create backup
        run: |
          kubectl get all -n microservices -o yaml > backup-$(date +%Y%m%d-%H%M%S).yaml
          kubectl get pvc -n microservices -o yaml >> backup-$(date +%Y%m%d-%H%M%S).yaml
      
      - name: Deploy with blue-green
        run: |
          # Apply manifests
          kubectl apply -f 1-storage-class.yaml
          kubectl apply -f 2-persistent-volumes.yaml
          kubectl apply -f 3-postgresql.yaml
          kubectl apply -f 4-redis.yaml
          kubectl apply -f 5-mongodb.yaml
          kubectl apply -f 6-user-service.yaml
          kubectl apply -f 7-product-service.yaml
          kubectl apply -f 8-order-service.yaml
          kubectl apply -f 9-ingress.yaml
        env:
          KUBECONFIG: ${{ secrets.KUBECONFIG_PROD }}
      
      - name: Verify deployment health
        run: |
          kubectl rollout status deployment/user-service -n microservices --timeout=10m
          kubectl rollout status deployment/product-service -n microservices --timeout=10m
          kubectl rollout status deployment/order-service -n microservices --timeout=10m
        env:
          KUBECONFIG: ${{ secrets.KUBECONFIG_PROD }}
      
      - name: Run health checks
        run: |
          for i in {1..5}; do
            curl -f https://api.example.com/users/health && break || sleep 10
          done
      
      - name: Create GitHub Release
        if: startsWith(github.ref, 'refs/tags/')
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          body: 'See CHANGELOG.md for details'
          draft: false
          prerelease: false
      
      - name: Notify team
        if: always()
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          text: 'Production deployment: ${{ job.status }}'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

---

## 7. .gitlab-ci.yml - GitLab CI/CD

```yaml
image: ubuntu:latest

stages:
  - lint
  - validate
  - test
  - build
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  REGISTRY: registry.example.com

# Lint stage
lint:yaml:
  stage: lint
  script:
    - apt-get update && apt-get install -y yamllint
    - yamllint k8s/

lint:shell:
  stage: lint
  script:
    - apt-get update && apt-get install -y shellcheck
    - shellcheck scripts/*.sh || true

# Validate stage
validate:kubernetes:
  stage: validate
  image: alpine:latest
  script:
    - apk add --no-cache curl
    - curl -L https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz | tar xz
    - find . -name "*.yaml" -type f | grep -v node_modules | xargs ./kubeval

# Test stage
test:
  stage: test
  image: node:18
  script:
    - npm install
    - npm test
    - npm run coverage
  coverage: '/Coverage: \d+\.\d+%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml

# Build stage
build:docker:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $REGISTRY/user-service:$CI_COMMIT_SHA services/user-service/
    - docker build -t $REGISTRY/product-service:$CI_COMMIT_SHA services/product-service/
    - docker build -t $REGISTRY/order-service:$CI_COMMIT_SHA services/order-service/

# Deploy stages
deploy:develop:
  stage: deploy
  environment:
    name: development
    url: https://api-dev.example.com
  script:
    - kubectl apply -f k8s/dev/
  only:
    - develop
  tags:
    - kubernetes

deploy:staging:
  stage: deploy
  environment:
    name: staging
    url: https://api-staging.example.com
  script:
    - kubectl apply -f k8s/staging/
  only:
    - staging
  tags:
    - kubernetes

deploy:production:
  stage: deploy
  environment:
    name: production
    url: https://api.example.com
  script:
    - kubectl apply -f k8s/prod/
  only:
    - main
    - tags
  when: manual
  tags:
    - kubernetes
```

---

## 8. Makefile - Common Commands

```makefile
.PHONY: help setup lint test build deploy-dev deploy-staging deploy-prod

help:
	@echo "Available commands:"
	@echo "  make setup              - Setup git hooks and config"
	@echo "  make lint               - Lint all files"
	@echo "  make test               - Run tests"
	@echo "  make build              - Build Docker images"
	@echo "  make deploy-dev         - Deploy to development"
	@echo "  make deploy-staging     - Deploy to staging"
	@echo "  make deploy-prod        - Deploy to production"
	@echo "  make create-feature     - Create feature branch (interactive)"
	@echo "  make branch-status      - Show branch status"

setup:
	git config commit.template .gitmessage
	git config core.hooksPath .githooks
	chmod +x .githooks/*
	@echo "✓ Git configured with commit template and hooks"

lint:
	@echo "Linting YAML files..."
	@find . -name "*.yaml" -type f | grep -v node_modules | xargs yamllint
	@echo "Linting shell scripts..."
	@find scripts -name "*.sh" -type f | xargs shellcheck || true

validate-k8s:
	@echo "Validating Kubernetes manifests..."
	@find . -name "*.yaml" -type f | grep -v node_modules | xargs kubeval

test:
	@echo "Running tests..."
	npm test

coverage:
	@echo "Running tests with coverage..."
	npm run coverage

build:
	@echo "Building Docker images..."
	docker build -t user-service:latest services/user-service/
	docker build -t product-service:latest services/product-service/
	docker build -t order-service:latest services/order-service/

deploy-dev:
	@echo "Deploying to development..."
	kubectl apply -f k8s/dev/

deploy-staging:
	@echo "Deploying to staging..."
	kubectl apply -f k8s/staging/

deploy-prod:
	@echo "Deploying to production..."
	kubectl apply -f k8s/prod/

create-feature:
	@read -p "Enter feature name: " feature; \
	git checkout develop; \
	git pull origin develop; \
	git checkout -b feature/$$feature; \
	@echo "Feature branch created: feature/$$feature"

branch-status:
	@echo "Current branch: $$(git branch --show-current)"
	@echo "\nBranches:"
	@git branch -a
	@echo "\nRecent commits:"
	@git log --oneline -10

cleanup-branches:
	@echo "Deleting local branches that don't exist on remote..."
	git remote prune origin
	git branch -vv | grep 'gone' | awk '{print $$1}' | xargs git branch -D

sync:
	@echo "Syncing with main branch..."
	git fetch origin
	git rebase origin/main

pre-commit:
	@echo "Running pre-commit checks..."
	@make lint
	@make test

release:
	@read -p "Enter version (v1.2.3): " version; \
	git tag -a $$version -m "Release $$version"; \
	git push origin $$version; \
	@echo "Release tagged and pushed: $$version"
```

Save as `Makefile` in root directory

Usage:
```bash
make setup          # Initial setup
make lint           # Lint code
make test           # Run tests
make create-feature # Create feature branch
make deploy-dev     # Deploy to development
```

---

## 9. Pre-commit Git Hooks

Create `.githooks/pre-commit`:
```bash
#!/bin/bash

# Pre-commit hook - runs before commit

echo "Running pre-commit checks..."

# Check for secrets
echo "Checking for secrets..."
git diff --cached | grep -E "(password|token|secret|key|apikey)" && {
    echo "ERROR: Possible secrets detected in commit"
    exit 1
}

# Lint staged files
echo "Linting YAML files..."
git diff --cached --name-only --diff-filter=ACM | grep '\.yaml$' | while read file; do
    yamllint "$file" || exit 1
done

# Validate Kubernetes manifests
echo "Validating Kubernetes manifests..."
git diff --cached --name-only --diff-filter=ACM | grep '\.yaml$' | while read file; do
    kubeval "$file" || exit 1
done

echo "✓ Pre-commit checks passed"
exit 0
```

Create `.githooks/commit-msg`:
```bash
#!/bin/bash

# Commit message hook - validates commit message format

commit_msg_file=$1

# Read commit message
commit_msg=$(cat "$commit_msg_file")

# Check if commit message follows format: <type>(<scope>): <subject>
if ! echo "$commit_msg" | grep -qE "^(feat|fix|docs|style|refactor|perf|test|ci|infra|chore)(\(.+\))?!?: .{1,50}"; then
    echo "ERROR: Commit message must follow format: <type>(<scope>): <subject>"
    echo ""
    echo "Valid types: feat, fix, docs, style, refactor, perf, test, ci, infra, chore"
    echo "Example: feat(user-service): add JWT authentication"
    exit 1
fi

# Check line length
first_line=$(head -n 1 "$commit_msg_file")
if [ ${#first_line} -gt 72 ]; then
    echo "ERROR: First line must be 72 characters or less"
    echo "Current length: ${#first_line}"
    exit 1
fi

exit 0
```

Make hooks executable:
```bash
chmod +x .githooks/pre-commit
chmod +x .githooks/commit-msg
```

Configure git to use hooks:
```bash
git config core.hooksPath .githooks
```

---

## 10. GitHub Issue Template

Create `.github/ISSUE_TEMPLATE/bug_report.md`:
```markdown
---
name: Bug Report
about: Report a bug in the microservices
title: '[BUG] '
labels: bug
assignees: ''
---

## Description
Brief description of the bug.

## Steps to Reproduce
1. Step 1
2. Step 2
3. ...

## Expected Behavior
What should happen.

## Actual Behavior
What actually happens.

## Environment
- Kubernetes Version: 
- Service Affected: user-service / product-service / order-service
- Namespace: dev / staging / prod
- OS: Linux / macOS / Windows

## Logs
Relevant error logs or stack trace.

## Possible Solution
Any ideas about how to fix this.
```

Create `.github/ISSUE_TEMPLATE/feature_request.md`:
```markdown
---
name: Feature Request
about: Suggest an idea for improvement
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

## Description
Clear description of the feature.

## Motivation
Why is this feature needed?

## Proposed Solution
How should this feature work?

## Examples
Real-world examples or use cases.

## Related Service
- user-service
- product-service
- order-service
- infrastructure
```

---

## 11. Pull Request Template

Create `.github/pull_request_template.md`:
```markdown
## Description
Brief description of what this PR does.

## Related Issues
Fixes #123
Related to #456

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update
- [ ] Infrastructure/deployment change

## Changes Made
- Change 1
- Change 2
- Change 3

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests passed
- [ ] Manual testing in dev environment
- [ ] Manual testing in staging environment

## Checklist
- [ ] Code follows style guide
- [ ] No console logs or debugging code
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
- [ ] Kubernetes manifests validated
- [ ] All tests passing
- [ ] Committed message follows convention
- [ ] CHANGELOG.md updated

## Deployment Notes
Any special steps needed for deployment.

## Screenshots/Logs
If applicable, add screenshots or logs.

## Reviewers
@reviewer1 @reviewer2
```

