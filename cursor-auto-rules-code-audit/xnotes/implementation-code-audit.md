# Security Code Audit Implementation Guide

<on-init>
1. Verify .audit directory structure
2. Locate approved .audit/arch.md and current .audit/task-{number}.audit.md
3. Validate task status and approvals
4. Initialize audit environment
5. Set up security tools and configurations
6. <critical>Do not proceed without approved scope and architecture documents</critical>
</on-init>

<audit-execution>
Each audit task must follow:

1. Pre-Audit Setup
   - Source code verification
   - Version control check
   - Tool preparation
   - Environment setup
   - Security baseline

2. Static Analysis
   - Code pattern review
   - Security rule validation
   - Dependency analysis
   - Configuration check
   - Custom rule execution

3. Dynamic Analysis
   - Runtime behavior
   - API security testing
   - Authentication flows
   - Authorization checks
   - Input validation

4. Manual Review
   - Business logic
   - Security controls
   - Error handling
   - Logging/monitoring
   - Edge cases

5. Evidence Collection
   - Screenshots
   - Log files
   - Tool outputs
   - Test cases
   - Proof of concepts
</audit-execution>

<implementation-rules>
1. Audit Process Rules
   - Follow systematic approach
   - Maintain traceability
   - Document all findings
   - Verify each issue
   - Track progress

2. Evidence Management
   - Structured storage
   - Clear labeling
   - Context preservation
   - Chain of custody
   - Secure handling

3. Vulnerability Handling
   - Immediate reporting
   - Priority assessment
   - Impact analysis
   - Fix verification
   - Documentation

4. Completion Requirements
   - All checks executed
   - Findings validated
   - Documentation complete
   - Evidence preserved
   - User confirmation
</implementation-rules>

<language-specific>
1. Java Security Focus
   ```java
   // Check for
   - Unsafe deserialization
   - XXE vulnerabilities
   - SQL injection
   - Security manager bypass
   ```

2. Python Security Focus
   ```python
   # Check for
   - Pickle vulnerabilities
   - Command injection
   - Path traversal
   - Dependency issues
   ```

3. Go Security Focus
   ```go
   // Check for
   - Memory safety
   - Goroutine leaks
   - TLS configuration
   - Command execution
   ```

4. PHP Security Focus
   ```php
   // Check for
   - File inclusion
   - Object injection
   - Session handling
   - Type juggling
   ```
</language-specific>

<automation>
1. Tool Integration
   ```bash
   # Static Analysis
   semgrep --config=p/security
   
   # Dependency Check
   owasp-dependency-check --scan ./
   
   # Custom Security Scan
   security-scanner --audit-mode
   ```

2. Report Generation
   ```bash
   # Generate Reports
   audit-reporter --format=markdown
   
   # Evidence Collection
   evidence-collector --task=$TASK_ID
   ```

3. Continuous Monitoring
   ```bash
   # File Monitoring
   inotifywait -m -r ./src
   
   # Security Events
   auditd -f
   ```
</automation>

<critical>
Security Requirements:
- Maintain confidentiality
- Follow least privilege
- Document everything
- Verify findings
- Secure evidence
- Protect sensitive data

Process Requirements:
- Complete all checks
- Validate results
- Update documentation
- Get user approval
- Track changes
- Maintain audit trail
</critical>

<templates>
1. Finding Documentation
   ```markdown
   ## Security Finding
   - ID: [VULN-ID]
   - Severity: [Level]
   - Location: [Path]
   - Description: [Details]
   - Impact: [Analysis]
   - Evidence: [Links]
   ```

2. Evidence Collection
   ```markdown
   ## Evidence Record
   - Task: [TASK-ID]
   - Type: [Type]
   - Location: [Path]
   - Context: [Details]
   - Command: [Command]
   - Result: [Output]
   ```

3. Progress Tracking
   ```markdown
   ## Audit Progress
   - Domain: [Domain]
   - Task: [Task]
   - Status: [Status]
   - Findings: [Count]
   - Blockers: [Issues]
   ```
</templates>

<workflow-integration>
1. Version Control
   ```bash
   # Create audit branch
   git checkout -b audit/task-001
   
   # Document finding
   git add .audit/findings/
   git commit -m "audit: document SQL injection"
   ```

2. Issue Tracking
   ```markdown
   - Create security issue
   - Link to evidence
   - Track remediation
   - Update status
   ```

3. Documentation
   ```markdown
   - Update task status
   - Record findings
   - Link evidence
   - Track progress
   ```
</workflow-integration> 