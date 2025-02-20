# Git Push Command Template for Security Audits

## Pre-Push Security Checks

1. Environment Verification
   ```bash
   # Verify workspace
   pwd
   git status
   
   # Check branch
   git branch
   ```

2. Security Review
   ```bash
   # Check for sensitive files
   git diff --cached --name-only | grep -i 'secret\|password\|key\|token\|credential'
   
   # Check for large files
   git diff --cached --stat
   
   # Check file permissions
   git diff --cached --summary
   ```

3. Content Validation
   ```bash
   # Review changes
   git diff --cached
   
   # Check commit messages
   git log -p HEAD^..HEAD
   ```

## Security-Focused Push Commands

```bash
# Standard Push Format
git push <remote> <branch>

# Security Branch Examples
git push origin security/auth-audit
git push origin audit/domain-1
git push origin fix/vuln-001
```

## Audit Workflow Scenarios

### 1. New Audit Task
```bash
# Create audit task branch
git checkout -b audit/task-001
git add .audit/domain-1/task-001.audit.md
git commit -m "audit: initialize authentication review task"
git push -u origin audit/task-001
```

### 2. Vulnerability Documentation
```bash
# Document new finding
git checkout -b vuln/XSS-001
git add .audit/domain-1/vuln-001.vuln.md
git commit -m "security: document XSS vulnerability in login form"
git push -u origin vuln/XSS-001
```

### 3. Evidence Collection
```bash
# Add evidence files
git checkout -b evidence/AUDIT-001
git add .audit/evidence/task-001/*
git commit -m "audit: add authentication bypass evidence"
git push -u origin evidence/AUDIT-001
```

## Security Guidelines

1. Branch Naming Convention
   - `audit/*` - Audit tasks and documentation
   - `vuln/*` - Vulnerability documentation
   - `evidence/*` - Evidence collection
   - `fix/*` - Security fixes

2. Commit Message Format
   ```
   type(scope): subject

   Types:
   - audit: Audit-related changes
   - security: Security-related changes
   - vuln: Vulnerability documentation
   - evidence: Evidence collection
   - fix: Security fixes
   ```

3. Security Best Practices
   - Never commit sensitive data
   - Use .gitignore for security
   - Review changes carefully
   - Maintain audit trail

## Pre-Push Security Checklist

- [ ] Environment verified
- [ ] No sensitive data exposed
- [ ] Evidence properly documented
- [ ] Commit messages follow convention
- [ ] Branch naming correct
- [ ] Changes reviewed
- [ ] Security implications considered

<critical>
Security Rules:
- Never push sensitive information
- Always review for exposed credentials
- Follow secure branch naming
- Maintain evidence integrity
- Document all security changes
- Protect audit findings
</critical>

## Error Recovery

### 1. Remove Sensitive Data
```bash
# Remove from last commit
git reset --soft HEAD^
# Remove from history
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch PATH_TO_FILE" \
  --prune-empty --tag-name-filter cat -- --all
```

### 2. Fix Wrong Branch
```bash
# Move changes to correct branch
git stash
git checkout correct-branch
git stash pop
```

### 3. Update Security Documentation
```bash
# Amend last commit
git commit --amend
git push --force-with-lease origin branch-name
``` 