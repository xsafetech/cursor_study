# AI Agent Rules for Security Audits

## Core Principles

1. **Security First**
   - Prioritize security over efficiency
   - Follow secure coding practices
   - Maintain confidentiality
   - Document all findings

2. **Systematic Approach**
   - Follow established workflow
   - Use standardized templates
   - Maintain audit trail
   - Verify all findings

3. **Clear Communication**
   - Use precise terminology
   - Document assumptions
   - Explain technical details
   - Provide context

## Workflow Rules

### 1. Environment Setup
- Check system requirements
- Verify tool availability
- Validate workspace
- Document configuration

### 2. Documentation
- Use approved templates
- Follow naming conventions
- Include all required sections
- Maintain version control

### 3. Audit Execution
- Follow audit checklist
- Document evidence
- Validate findings
- Track progress

### 4. Security Practices
- Handle sensitive data carefully
- Use secure communication
- Follow least privilege
- Maintain confidentiality

## Automation Guidelines

### 1. File Operations
```bash
# Directory Structure
mkdir -p .audit/{domain-1,evidence,reports}
chmod 700 .audit/evidence

# File Templates
cp templates/audit.md .audit/domain-1/task-001.audit.md
cp templates/vuln.md .audit/domain-1/vuln-001.vuln.md
```

### 2. Security Tools
```bash
# Static Analysis
semgrep --config p/security --json > .audit/evidence/semgrep-results.json

# Dependency Check
owasp-dependency-check --scan ./ --format JSON --out .audit/evidence/

# Custom Security Scan
security-scanner --audit-mode --output .audit/evidence/scan-results.json
```

### 3. Monitoring
```bash
# File Changes
inotifywait -m -r ./src -e modify,create,delete |
while read path action file; do
    echo "[$(date)] $action $path$file" >> .audit/evidence/file-changes.log
done

# Security Events
auditd -f -l .audit/evidence/audit.log
```

## Response Templates

### 1. Security Finding
```markdown
## Security Finding [ID]
Severity: [Critical/High/Medium/Low]
Category: [Category]
Component: [Component]

### Description
[Clear explanation of the issue]

### Technical Details
- Location: [File:Line]
- Pattern: [Code Pattern]
- Tool: [Detection Tool]

### Impact
[Security implications]

### Evidence
```code
[Relevant code or output]
```

### Remediation
1. Short term: [Immediate fix]
2. Long term: [Strategic solution]
```

### 2. Audit Task
```markdown
## Audit Task [ID]
Domain: [Domain]
Priority: [Priority]
Status: [Status]

### Objective
[Clear description of task goal]

### Technical Scope
- Components: [List]
- Entry Points: [List]
- Dependencies: [List]

### Security Checks
1. [ ] Static Analysis
2. [ ] Dynamic Testing
3. [ ] Manual Review
4. [ ] Configuration Check

### Evidence Required
- [ ] Tool Output
- [ ] Test Cases
- [ ] Screenshots
- [ ] Logs
```

## Automation Rules

### 1. Event Triggers
```yaml
on_file_change:
  - run: semgrep
  - update: audit_log
  - check: security_rules

on_task_complete:
  - generate: report
  - update: status
  - notify: team

on_finding:
  - create: vuln_report
  - collect: evidence
  - assess: severity
```

### 2. Tool Integration
```yaml
tools:
  semgrep:
    config: security_rules
    output: json
    severity_map:
      error: critical
      warning: high
      info: medium

  dependency_check:
    scan_mode: full
    formats:
      - JSON
      - HTML
    suppress_file: suppress.xml
```

### 3. Report Generation
```yaml
reports:
  findings:
    template: finding_template.md
    variables:
      - severity
      - location
      - evidence
    
  summary:
    template: summary_template.md
    sections:
      - overview
      - findings
      - metrics
```

## Critical Rules

<critical>
1. Security Requirements
   - Never expose credentials
   - Protect sensitive data
   - Verify all findings
   - Document evidence
   - Follow secure practices

2. Process Requirements
   - Follow workflow
   - Use templates
   - Track progress
   - Maintain logs
   - Update status

3. Communication Rules
   - Clear language
   - Technical accuracy
   - Complete context
   - Proper formatting
   - Regular updates
</critical>

## Integration Guidelines

### 1. Version Control
```bash
# Branch naming
git checkout -b audit/task-001
git checkout -b vuln/XSS-001

# Commit messages
git commit -m "audit: complete authentication review"
git commit -m "security: document SQL injection finding"
```

### 2. Issue Tracking
```yaml
issue:
  title: "[Security] SQL Injection in Login Form"
  type: vulnerability
  severity: critical
  status: open
  assignee: security-team
  labels:
    - security
    - audit
    - sql-injection
```

### 3. Documentation
```markdown
## Documentation Update
- Task Status: [Status]
- Findings: [Count]
- Evidence: [Location]
- Next Steps: [Actions]
```

## Quality Assurance

### 1. Finding Verification
- Reproduce issue
- Validate impact
- Check evidence
- Review solution

### 2. Report Quality
- Complete information
- Clear description
- Technical accuracy
- Actionable fixes

### 3. Process Compliance
- Follow workflow
- Use templates
- Track changes
- Maintain logs 
```

#!/bin/bash

setup_automation() {
    # 设置文件监控
    mkdir -p .cursor/hooks
    
    # 创建文件变更钩子
    cat > .cursor/hooks/on_file_change.sh << 'EOL'
#!/bin/bash
FILE=$1
EVENT=$2

case "${FILE##*.}" in
    java|py|js|php)
        echo "触发安全扫描: $FILE"
        semgrep --config=.semgrep.yml "$FILE"
        ;;
esac
EOL
    
    chmod +x .cursor/hooks/on_file_change.sh
} 