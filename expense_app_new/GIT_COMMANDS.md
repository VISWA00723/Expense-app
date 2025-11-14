# Git Commands Guide

## Initial Setup

```bash
# Initialize git repository (if not already done)
git init

# Configure git user
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Add remote repository
git remote add origin https://github.com/yourusername/expense-tracker.git
```

## Daily Workflow

### 1. Check Status
```bash
# See what files have changed
git status

# See detailed changes
git diff
```

### 2. Stage Changes
```bash
# Stage all changes
git add .

# Stage specific file
git add lib/screens/dashboard_screen.dart

# Stage specific folder
git add lib/services/
```

### 3. Commit Changes
```bash
# Commit with message
git commit -m "Add feature description"

# Commit with detailed message
git commit -m "Add feature title" -m "Detailed description of changes"
```

## Commit Message Examples

### Feature Additions
```bash
git commit -m "feat: Add AI expense parsing via natural language"
git commit -m "feat: Implement adaptive refresh rate support (60, 90, 120, 144 Hz)"
git commit -m "feat: Add scrollable legend with View All button"
git commit -m "feat: Implement session persistence and auto-login"
```

### Bug Fixes
```bash
git commit -m "fix: Fix pie chart overflow by reducing padding"
git commit -m "fix: Fix RenderFlex overflow in expense list"
git commit -m "fix: Fix import conflict between drift and flutter Column"
git commit -m "fix: Fix missing setCurrentUser method in AuthService"
```

### Performance Improvements
```bash
git commit -m "perf: Optimize animations with delayed start"
git commit -m "perf: Add RepaintBoundary to reduce repaints"
git commit -m "perf: Optimize dashboard rendering for low-end devices"
```

### Design Updates
```bash
git commit -m "style: Update theme with modern color palette"
git commit -m "style: Add gradient animations to salary card"
git commit -m "style: Improve Material 3 design consistency"
```

### Documentation
```bash
git commit -m "docs: Add performance optimization guide"
git commit -m "docs: Update README with new features"
git commit -m "docs: Add AI expense parsing documentation"
```

## Push to Remote

```bash
# Push to main branch
git push origin main

# Push to specific branch
git push origin feature-branch

# Push all branches
git push origin --all

# Force push (use with caution!)
git push origin main --force
```

## Branching

```bash
# Create new branch
git branch feature/ai-expenses
git checkout feature/ai-expenses

# Or create and switch in one command
git checkout -b feature/ai-expenses

# List all branches
git branch -a

# Delete branch
git branch -d feature/ai-expenses

# Merge branch to main
git checkout main
git merge feature/ai-expenses
```

## View History

```bash
# View commit history
git log

# View last 5 commits
git log -5

# View commits with changes
git log -p

# View commits in one line
git log --oneline

# View commits by author
git log --author="Your Name"
```

## Undo Changes

```bash
# Undo changes in working directory
git checkout -- filename

# Undo staged changes
git reset HEAD filename

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1
```

## Today's Commits

### Session 1: Performance & Design
```bash
git add .
git commit -m "feat: Add modern color palette and adaptive refresh rate support"
git commit -m "feat: Implement animated cards with fade and scale effects"
git commit -m "perf: Optimize animations with delayed start and RepaintBoundary"
git commit -m "fix: Fix pie chart layout overflow issues"
```

### Session 2: AI Enhancement
```bash
git add .
git commit -m "feat: Add AI expense parsing via natural language input"
git commit -m "feat: Implement expense detection and automatic category assignment"
git commit -m "feat: Add dashboard refresh on new expense addition"
```

### Session 3: Session Management
```bash
git add .
git commit -m "feat: Implement session persistence and auto-login"
git commit -m "fix: Fix session restoration on app startup"
git commit -m "feat: Add logout functionality with session clearing"
```

### Session 4: Bug Fixes
```bash
git add .
git commit -m "fix: Fix import conflicts and build errors"
git commit -m "fix: Fix expense list layout overflow"
git commit -m "fix: Fix missing AuthService methods"
```

## Recommended Commit Workflow for Today

```bash
# 1. Check what changed
git status

# 2. Add all changes
git add .

# 3. Commit with descriptive message
git commit -m "feat: Complete expense tracker redesign with AI, animations, and performance optimization"

# 4. View the commit
git log -1

# 5. Push to remote
git push origin main
```

## Useful Aliases

Add these to your git config for faster commands:

```bash
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.visual 'log --graph --oneline --all'
```

Then use:
```bash
git st          # instead of git status
git co main     # instead of git checkout main
git ci -m "msg" # instead of git commit -m "msg"
```

## Push Current Session

```bash
# Stage all changes
git add .

# Commit all changes
git commit -m "feat: Complete expense tracker v3.0 with AI, animations, and performance optimization

- Add AI-powered expense parsing via natural language
- Implement adaptive refresh rate (60, 90, 120, 144 Hz)
- Add modern color palette with gradients
- Implement smooth animations (fade, scale, slide)
- Fix layout overflow issues
- Implement session persistence and auto-login
- Optimize performance for low-end devices
- Add RepaintBoundary for efficient rendering"

# Push to remote
git push origin main
```

## Status Check

```bash
# Before committing
git status

# After committing
git log --oneline -5
```
