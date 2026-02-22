# Git Setup Guide

Quick setup guide for configuring Git to use Vendora's conventions.

## 📝 Configure Commit Message Template

To automatically load the commit message template when you commit:

### Global Configuration (All Repositories)

```bash
git config --global commit.template ~/.gitmessage
cp .gitmessage ~/.gitmessage
```

### Local Configuration (This Repository Only)

```bash
git config commit.template .gitmessage
```

Now when you run `git commit`, the template will automatically appear in your editor!

## ✅ Verify Configuration

```bash
# Check if template is configured
git config commit.template

# Should output: .gitmessage (or full path if global)
```

## 🎨 Editor Configuration

### VS Code

```bash
# Set VS Code as default Git editor
git config --global core.editor "code --wait"
```

### Other Editors

```bash
# Vim
git config --global core.editor "vim"

# Nano
git config --global core.editor "nano"

# Sublime Text
git config --global core.editor "subl -n -w"

# Notepad++ (Windows)
git config --global core.editor "'C:/Program Files/Notepad++/notepad++.exe' -multiInst -notabbar -nosession -noPlugin"
```

## 🔧 Useful Git Aliases

Add these aliases to make your Git workflow faster:

```bash
# Add to ~/.gitconfig or run these commands:

# Shorter status
git config --global alias.st "status -sb"

# Pretty log
git config --global alias.lg "log --oneline --graph --all --decorate"

# Last commit
git config --global alias.last "log -1 HEAD --stat"

# Amend without editing message
git config --global alias.amend "commit --amend --no-edit"

# Show branches with last commit
git config --global alias.br "branch -v"

# Unstage files
git config --global alias.unstage "reset HEAD --"

# Show what's in the stash
git config --global alias.stash-show "stash show -p"
```

### Using Aliases

```bash
git st                    # Instead of: git status -sb
git lg                    # Instead of: git log --oneline --graph --all
git last                  # Show last commit
git amend                 # Amend without changing message
git br                    # List branches with info
git unstage filename      # Unstage a file
```

## 🎯 Commit Workflow Example

```bash
# 1. Create feature branch
git checkout -b feature/11-jwt-refresh-rotation

# 2. Make changes to code
# ... edit files ...

# 3. Stage changes
git add src/main/java/com/vendora/modules/auth/

# 4. Commit (template will appear)
git commit

# Template appears in editor:
# <type>(<scope>): <subject>
#
# [Body]
#
# [Footer]

# 5. Fill in commit message following template:
feat(auth): add JWT refresh token rotation

Implement automatic refresh token rotation for enhanced security.
Old refresh tokens are revoked when new ones are issued.

Closes #10

# 6. Save and close editor

# 7. Push to remote
git push origin feature/11-jwt-refresh-rotation
```

## 🚀 Quick Start Checklist

- [ ] Configure commit template: `git config commit.template .gitmessage`
- [ ] Set your preferred editor: `git config --global core.editor "code --wait"`
- [ ] Add useful aliases (see above)
- [ ] Read [GIT_CONVENTIONS.md](GIT_CONVENTIONS.md)
- [ ] Test with a commit: `git commit` (should show template)

## 📚 Additional Resources

- [GIT_CONVENTIONS.md](GIT_CONVENTIONS.md) - Full Git conventions guide
- [README.md](README.md) - Project documentation
- [Conventional Commits](https://www.conventionalcommits.org/) - Commit specification

---

**Happy Coding! 🎉**
