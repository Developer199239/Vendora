# Git Conventions & Standards

This document defines the Git workflow, commit message format, branch naming conventions, and pull request guidelines for the Vendora project.

---

## 📋 Table of Contents

- [Commit Message Format](#-commit-message-format)
- [Branch Naming Conventions](#-branch-naming-conventions)
- [Pull Request Guidelines](#-pull-request-guidelines)
- [Code Review Process](#-code-review-process)
- [Git Workflow](#-git-workflow)
- [Best Practices](#-best-practices)

---

## 📝 Commit Message Format

We follow the **Conventional Commits** specification for clear and structured commit messages.

### Structure

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Components

#### 1. Type (Required)

The type describes the kind of change. Must be one of:

| Type | Description | Example |
|------|-------------|---------|
| `feat` | New feature | `feat(auth): add JWT refresh token rotation` |
| `fix` | Bug fix | `fix(order): prevent stock overselling bug` |
| `docs` | Documentation changes | `docs(readme): update installation instructions` |
| `style` | Code style/formatting (no logic change) | `style(product): format code with prettier` |
| `refactor` | Code refactoring (no feature/bug change) | `refactor(auth): extract JWT logic to utility` |
| `perf` | Performance improvements | `perf(product): add index on category_id` |
| `test` | Adding or updating tests | `test(order): add integration test for concurrent orders` |
| `build` | Build system or dependencies | `build: upgrade Spring Boot to 3.3.1` |
| `ci` | CI/CD configuration changes | `ci: add Docker build to GitHub Actions` |
| `chore` | Maintenance tasks | `chore: update .gitignore` |
| `revert` | Revert a previous commit | `revert: revert "feat(auth): add OAuth2"` |

#### 2. Scope (Optional but Recommended)

The scope specifies which module or component is affected:

- `auth` - Authentication module
- `product` - Product module
- `order` - Order module
- `common` - Common/shared code
- `config` - Configuration
- `db` - Database/migrations
- `api` - API layer
- `test` - Test infrastructure
- `docs` - Documentation
- `docker` - Docker configuration
- `ci` - CI/CD pipeline

#### 3. Subject (Required)

- **Maximum 50 characters**
- Use **imperative mood** ("add" not "added" or "adds")
- **Lowercase** first letter
- **No period** at the end
- Describe **what** the commit does, not why

✅ **Good Examples:**
```
feat(auth): add JWT refresh token rotation
fix(order): prevent overselling with pessimistic lock
docs(api): update Swagger authentication examples
```

❌ **Bad Examples:**
```
feat(auth): Added JWT refresh token rotation (wrong tense)
fix(order): Fixed bug (not descriptive)
FEAT(AUTH): ADD JWT REFRESH TOKEN ROTATION (wrong case)
docs(api): Update swagger authentication examples. (has period)
```

#### 4. Body (Optional)

- Separate from subject with a **blank line**
- Explain **what** and **why**, not **how**
- Wrap at **72 characters**
- Use multiple paragraphs if needed
- Reference issues: `Closes #123` or `Fixes #456`

#### 5. Footer (Optional)

- Used for **breaking changes** or **issue references**
- Breaking changes start with `BREAKING CHANGE:`

---

### Commit Message Examples

#### Example 1: Simple Feature

```
feat(auth): add password change endpoint

Users can now change their password through the /api/v1/auth/change-password endpoint.
Requires current password for validation.

Closes #11
```

#### Example 2: Bug Fix

```
fix(order): prevent stock overselling

Add pessimistic locking when checking product stock during order creation.
This prevents race conditions when multiple users order the same product simultaneously.

Before: Stock could go negative under concurrent load
After: Orders fail gracefully when stock is insufficient

Fixes #20
```

#### Example 3: Documentation

```
docs(readme): add Docker Compose setup instructions

Add step-by-step instructions for running the application with Docker Compose.
Include environment variable configuration and troubleshooting tips.
```

#### Example 4: Refactoring

```
refactor(product): extract ProductMapper to separate class

Move DTO mapping logic from ProductService to ProductMapper for better separation of concerns.
No functional changes.
```

#### Example 5: Breaking Change

```
feat(auth): change JWT token response format

BREAKING CHANGE: AuthResponse now returns separate accessToken and refreshToken fields
instead of a single token field.

Before:
{
  "token": "...",
  "user": {...}
}

After:
{
  "accessToken": "...",
  "refreshToken": "...",
  "user": {...}
}

Migration: Update frontend to use accessToken and refreshToken fields.

Closes #15
```

#### Example 6: Performance Improvement

```
perf(product): add database index on category_id

Add index to products.category_id to improve query performance when filtering by category.
Query time reduced from 450ms to 12ms on 10K products.

Closes #18
```

#### Example 7: Test Addition

```
test(order): add concurrent order creation test

Add integration test using Testcontainers to verify that concurrent orders
for the same product cannot cause overselling. Test creates 10 concurrent
threads attempting to order quantity 2 from a product with stock 15.

Verifies both successful orders and proper exception handling.
```

#### Example 8: Build/Dependencies

```
build: upgrade PostgreSQL driver to 42.7.1

Upgrade org.postgresql:postgresql from 42.6.0 to 42.7.1
to fix security vulnerability CVE-2024-1597.
```

#### Example 9: CI/CD

```
ci: add coverage report upload to Codecov

Add Codecov action to GitHub Actions workflow to track test coverage over time.
Coverage reports are generated after successful test runs.
```

#### Example 10: Multiple Issues

```
feat(product): add category management APIs

Implement CRUD endpoints for product categories:
- POST /api/v1/admin/categories - Create category (ADMIN only)
- PUT /api/v1/admin/categories/{id} - Update category (ADMIN only)
- DELETE /api/v1/admin/categories/{id} - Delete category (ADMIN only)
- GET /api/v1/categories - List all categories (public)

Includes validation, tests, and Swagger documentation.

Closes #15
Closes #16
```

---

## 🌿 Branch Naming Conventions

### Format

```
<type>/<issue-number>-<short-description>
```

### Branch Types

| Type | Purpose | Example |
|------|---------|---------|
| `feature/` | New features | `feature/11-jwt-refresh-rotation` |
| `bugfix/` | Bug fixes | `bugfix/20-stock-overselling` |
| `hotfix/` | Urgent production fixes | `hotfix/critical-auth-bypass` |
| `refactor/` | Code refactoring | `refactor/extract-jwt-utility` |
| `test/` | Test additions | `test/order-concurrent-tests` |
| `docs/` | Documentation | `docs/api-documentation` |
| `chore/` | Maintenance | `chore/upgrade-dependencies` |

### Branch Naming Rules

✅ **Good Examples:**
```
feature/11-password-change-endpoint
bugfix/20-order-stock-overselling
hotfix/critical-jwt-expiration
refactor/extract-product-mapper
test/order-integration-tests
docs/update-readme
chore/upgrade-spring-boot
```

❌ **Bad Examples:**
```
feature/passwordChange (no issue number, camelCase)
11-password-change (no type)
feature/add_password_change (underscores)
FEATURE/11-password-change (uppercase type)
```

### Guidelines

- **Always lowercase** (except technical acronyms like JWT, API)
- Use **hyphens** to separate words, not underscores or spaces
- Keep it **short but descriptive** (max 50 characters)
- Include **issue number** when applicable
- Use **descriptive slug** that summarizes the work

---

## 🔀 Pull Request Guidelines

### Pull Request Title Format

Follow the same format as commit messages:

```
<type>(<scope>): <description>
```

**Examples:**
```
feat(auth): add JWT refresh token rotation
fix(order): prevent stock overselling with pessimistic lock
docs(readme): update Docker installation instructions
```

### Pull Request Description Template

Use this template for all pull requests:

```markdown
## 📋 Description

Brief description of what this PR does and why.

## 🎯 Related Issues

Closes #123
Relates to #456

## 🔄 Type of Change

- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📝 Documentation update
- [ ] ♻️ Code refactoring (no functional changes)
- [ ] ✅ Test addition or update
- [ ] 🔧 Build/CI configuration change

## 🧪 Testing

Describe the tests you ran and how to reproduce them:

- [ ] Unit tests pass (`mvn test`)
- [ ] Integration tests pass (`mvn verify`)
- [ ] Manual testing completed
- [ ] New tests added for this change

**Test scenarios:**
1. Scenario 1: ...
2. Scenario 2: ...

## 📸 Screenshots (if applicable)

Add screenshots for UI changes or API responses.

## ✅ Checklist

- [ ] My code follows the project's code style
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings or errors
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published

## 📝 Additional Notes

Any additional information, context, or considerations.
```

### Pull Request Example

```markdown
## 📋 Description

This PR implements JWT refresh token rotation to enhance security. When a user refreshes their access token, the old refresh token is revoked and a new one is issued. This prevents token reuse attacks.

## 🎯 Related Issues

Closes #10

## 🔄 Type of Change

- [ ] 🐛 Bug fix
- [x] ✨ New feature
- [ ] 💥 Breaking change
- [ ] 📝 Documentation update
- [ ] ♻️ Code refactoring
- [ ] ✅ Test addition or update
- [ ] 🔧 Build/CI configuration change

## 🧪 Testing

- [x] Unit tests pass (`mvn test`)
- [x] Integration tests pass (`mvn verify`)
- [x] Manual testing completed
- [x] New tests added for this change

**Test scenarios:**
1. User refreshes token successfully → receives new access token and new refresh token
2. User attempts to reuse old refresh token → receives 401 Unauthorized
3. Refresh token expires → user must re-login
4. User can have multiple active refresh tokens from different devices

**Test results:**
```bash
mvn verify
# All tests passed (32 tests, 0 failures, 0 skipped)
# Coverage: 87% (target: 75%)
```

## ✅ Checklist

- [x] My code follows the project's code style
- [x] I have performed a self-review of my own code
- [x] I have commented my code, particularly in hard-to-understand areas
- [x] I have made corresponding changes to the documentation
- [x] My changes generate no new warnings or errors
- [x] I have added tests that prove my fix is effective or that my feature works
- [x] New and existing unit tests pass locally with my changes
- [x] Any dependent changes have been merged and published

## 📝 Additional Notes

### Implementation Details

- Refresh tokens are now hashed before storage using SHA-256
- Added `revoked_at` timestamp to `refresh_tokens` table
- Cleanup job can be added later to delete expired/revoked tokens (scheduled task)

### Migration

No breaking changes. Existing refresh tokens will continue to work until they expire naturally.

### Future Enhancements

- Add device fingerprinting for better security
- Implement "logout from all devices" functionality
- Add refresh token usage analytics
```

---

## 👀 Code Review Process

### For Authors

1. **Before Creating PR:**
   - ✅ Run all tests locally and ensure they pass
   - ✅ Review your own code first
   - ✅ Update documentation if needed
   - ✅ Ensure CI pipeline is green
   - ✅ Rebase on main branch if needed

2. **Creating the PR:**
   - Use the PR template
   - Write a clear, descriptive title
   - Reference related issues
   - Add reviewers
   - Label appropriately (bug, enhancement, documentation, etc.)

3. **During Review:**
   - Respond to feedback promptly
   - Ask questions if feedback is unclear
   - Make requested changes
   - Mark conversations as resolved after addressing
   - Request re-review after changes

### For Reviewers

1. **Review Focus Areas:**
   - ☑️ **Correctness**: Does the code do what it's supposed to?
   - ☑️ **Testing**: Are there adequate tests?
   - ☑️ **Security**: Are there any security vulnerabilities?
   - ☑️ **Performance**: Any performance concerns?
   - ☑️ **Maintainability**: Is the code readable and maintainable?
   - ☑️ **Documentation**: Is new functionality documented?
   - ☑️ **Design**: Does it follow project architecture?

2. **Review Guidelines:**
   - Be respectful and constructive
   - Explain the "why" behind suggestions
   - Distinguish between blocking issues and nits
   - Approve if minor issues can be addressed post-merge
   - Test the changes locally for complex PRs

3. **Review Comments Format:**

**Blocking Issue:**
```
🚨 BLOCKER: This introduces a SQL injection vulnerability.
Use parameterized queries instead of string concatenation.
```

**Suggestion:**
```
💡 SUGGESTION: Consider extracting this method to improve readability.
```

**Question:**
```
❓ QUESTION: Why did we choose pessimistic locking here instead of optimistic?
```

**Nitpick:**
```
🔍 NIT: Variable name could be more descriptive (e.g., `customerEmail` instead of `email`).
```

**Praise:**
```
✨ NICE: Great test coverage for edge cases!
```

---

## 🔄 Git Workflow

We use **Git Flow** with some modifications:

### Branch Structure

```
main (production-ready)
  └─ develop (integration branch)
      ├─ feature/11-jwt-refresh
      ├─ feature/12-order-creation
      ├─ bugfix/20-stock-issue
      └─ ...
```

### Workflow Steps

#### 1. Start New Work

```bash
# Update main branch
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/11-jwt-refresh-rotation

# OR create from develop if using develop branch
git checkout develop
git pull origin develop
git checkout -b feature/11-jwt-refresh-rotation
```

#### 2. Work on Feature

```bash
# Make changes
# ...

# Stage changes
git add .

# Commit with conventional format
git commit -m "feat(auth): add JWT refresh token rotation"

# Push to remote
git push origin feature/11-jwt-refresh-rotation
```

#### 3. Keep Branch Updated

```bash
# Fetch latest changes
git fetch origin

# Rebase on main (or develop)
git rebase origin/main

# If conflicts, resolve them, then:
git add .
git rebase --continue

# Force push (if already pushed)
git push origin feature/11-jwt-refresh-rotation --force-with-lease
```

#### 4. Create Pull Request

1. Go to GitHub repository
2. Click "New Pull Request"
3. Select: `main` ← `feature/11-jwt-refresh-rotation`
4. Fill in PR template
5. Add reviewers and labels
6. Submit PR

#### 5. Address Review Comments

```bash
# Make changes based on feedback
# ...

# Commit changes
git add .
git commit -m "fix(auth): address review comments"

# Push changes
git push origin feature/11-jwt-refresh-rotation
```

#### 6. Merge Pull Request

After approval:

1. **Squash and Merge** (preferred for features)
   - Combines all commits into one clean commit
   - Edit final commit message to follow conventions

2. **Rebase and Merge** (for clean history)
   - Preserves individual commits
   - Use when commits are already well-structured

3. **Merge Commit** (for large features)
   - Creates merge commit
   - Use for complex features with multiple logical changes

#### 7. Clean Up

```bash
# Delete local branch
git checkout main
git pull origin main
git branch -d feature/11-jwt-refresh-rotation

# Delete remote branch (if not auto-deleted)
git push origin --delete feature/11-jwt-refresh-rotation
```

---

## ✅ Best Practices

### Commit Best Practices

1. ✅ **Commit Often**: Small, focused commits are better than large ones
2. ✅ **Atomic Commits**: Each commit should be a single logical change
3. ✅ **Test Before Commit**: Ensure tests pass before committing
4. ✅ **Write Good Messages**: Future you will thank present you
5. ✅ **No WIP Commits**: Don't commit work-in-progress to main/develop

### Branch Best Practices

1. ✅ **Short-Lived Branches**: Merge features quickly to avoid conflicts
2. ✅ **One Feature Per Branch**: Don't mix unrelated changes
3. ✅ **Update Regularly**: Rebase frequently to stay up-to-date
4. ✅ **Delete After Merge**: Clean up merged branches
5. ✅ **No Direct Commits to Main**: Always use feature branches

### Pull Request Best Practices

1. ✅ **Small PRs**: Easier to review (< 400 lines changed)
2. ✅ **Self-Review First**: Review your own code before requesting reviews
3. ✅ **Clear Description**: Explain what, why, and how
4. ✅ **Link Issues**: Reference related issues
5. ✅ **Green CI**: Ensure all checks pass before review

### Git Commands Cheat Sheet

```bash
# View commit history with graph
git log --oneline --graph --all

# View changes in working directory
git status

# View uncommitted changes
git diff

# View changes in staged files
git diff --staged

# Amend last commit (if not pushed)
git add .
git commit --amend

# Interactive rebase (edit last 3 commits)
git rebase -i HEAD~3

# Stash changes temporarily
git stash
git stash pop

# Cherry-pick specific commit
git cherry-pick <commit-hash>

# View who changed what line
git blame <file>

# Search commit messages
git log --grep="JWT"

# Find deleted code
git log -S "deleted code" --source --all
```

---

## 🎯 Quick Reference

### Commit Types Quick Guide

| Scenario | Type | Example |
|----------|------|---------|
| Add login endpoint | `feat` | `feat(auth): add login endpoint` |
| Fix null pointer bug | `fix` | `fix(order): handle null customer` |
| Update README | `docs` | `docs(readme): add setup instructions` |
| Format code | `style` | `style: apply code formatter` |
| Extract method | `refactor` | `refactor(auth): extract JWT util` |
| Add DB index | `perf` | `perf(product): add category index` |
| Add unit tests | `test` | `test(order): add validation tests` |
| Update dependency | `build` | `build: upgrade Spring Boot to 3.3.1` |
| Update CI config | `ci` | `ci: add Docker build step` |
| Update .gitignore | `chore` | `chore: update .gitignore` |

### Branch Name Quick Examples

```
feature/11-password-change
bugfix/20-stock-overselling
hotfix/critical-jwt-vulnerability
refactor/extract-mapper-utility
test/integration-test-suite
docs/api-documentation-swagger
chore/upgrade-postgresql-driver
```

---

## 📚 Additional Resources

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/)
- [How to Write a Git Commit Message](https://chris.beams.io/posts/git-commit/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Semantic Versioning](https://semver.org/)

---

## 🤝 Questions?

If you have questions about these conventions:

1. Check existing commits and PRs for examples
2. Ask in team chat or during code review
3. Suggest improvements via PR to this document

---

<div align="center">

**Consistent conventions make collaboration easier!**

[⬆ Back to Top](#git-conventions--standards)

</div>
