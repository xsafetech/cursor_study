# Code Audit Workflow Rules

This document outlines the workflow rules and procedures for conducting security code audits using Cursor AI.

## Core Principles

1. **Systematic Approach**
   - Follow structured audit methodology
   - Maintain consistent documentation
   - Track findings and evidence
   - Ensure reproducible results

2. **Security First**
   - Prioritize security over efficiency
   - Maintain confidentiality of findings
   - Complete evidence chain required
   - Verify all conclusions

3. **Documentation Standards**
   - Use standardized templates
   - Include all required sections
   - Maintain proper hierarchy
   - Keep clear audit trail

## Workflow Phases

### 1. Planning Phase
- Create and approve scope document
- Define audit boundaries
- Identify critical components
- Set security objectives

### 2. Execution Phase
- Follow audit checklist
- Document all findings
- Collect evidence
- Validate vulnerabilities

### 3. Reporting Phase
- Document vulnerabilities
- Provide remediation guidance
- Create final report
- Present findings

## Directory Structure

```
project-root/
├── .audit/                    # Audit documentation
│   ├── scope.md              # Audit scope
│   ├── domain-1/             # Audit domains
│   │   ├── task-1.audit.md   # Audit tasks
│   │   └── vuln-1.vuln.md    # Vulnerabilities
│   └── arch.md               # Architecture notes
├── docs/                     # Project documentation
└── xnotes/                  # Workflow templates
```

## Task Organization

1. **Domains**
   - Logical grouping of components
   - One active domain at a time
   - Clear progression path
   - Defined completion criteria

2. **Tasks**
   - Specific audit objectives
   - Detailed test cases
   - Evidence requirements
   - Validation steps

3. **Findings**
   - Unique vulnerability IDs
   - Severity classification
   - Impact assessment
   - Reproduction steps

## Language-Specific Guidelines

### Java
- Spring security mechanisms
- JVM vulnerabilities
- Deserialization issues
- Memory safety

### PHP
- Taint analysis
- PHP-FPM/CGI issues
- Framework security
- Input validation

### Python
- Django/Flask security
- C extension modules
- Package dependencies
- Runtime security

### Go/Rust
- Memory safety
- Concurrency issues
- FFI boundaries
- Third-party risks

## Critical Requirements

1. **Before Starting**
   - Environment check complete
   - Tools verified
   - Access confirmed
   - Scope approved

2. **During Audit**
   - Follow checklist
   - Document evidence
   - Validate findings
   - Track progress

3. **Completion Criteria**
   - All checks performed
   - Findings verified
   - Documentation complete
   - User confirmation received

## Best Practices

1. **Evidence Collection**
   - Screenshot key findings
   - Save relevant logs
   - Document commands
   - Maintain context

2. **Vulnerability Validation**
   - Create proof of concept
   - Test in isolation
   - Verify impact
   - Document steps

3. **Documentation**
   - Use clear language
   - Include all details
   - Maintain structure
   - Keep it current

## Automation Rules

1. **Tool Integration**
   - Semgrep configuration
   - SonarQube setup
   - OWASP dependency check
   - Custom security tools

2. **Triggers**
   - On project open
   - On file change
   - On scan complete
   - On vulnerability found

3. **Reporting**
   - Automatic report generation
   - Finding categorization
   - Evidence collection
   - Notification dispatch

## Compliance Requirements

1. **Standards**
   - OWASP Top 10
   - CWE Top 25
   - SANS Top 25
   - ISO 27001

2. **Regulations**
   - GDPR
   - HIPAA
   - PCI DSS
   - SOC 2

3. **Documentation**
   - Audit trail
   - Evidence chain
   - Finding verification
   - Remediation tracking 