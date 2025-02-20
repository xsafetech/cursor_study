# Security Audit Project Template

Use this template to initialize a new security audit project with the AI agent.

## Project Overview

```markdown
I need to conduct a security audit for [Project Name], which is a [brief description].

Technical Stack:
- Language: [Language & Version]
- Framework: [Framework & Version]
- Database: [Database & Version]
- Infrastructure: [Infrastructure Details]

Security Requirements:
1. [Requirement 1]
2. [Requirement 2]
3. [Requirement 3]

Compliance Requirements:
1. [Standard 1]
2. [Standard 2]
3. [Standard 3]

Please help set up the security audit project structure and documentation.
```

## Example Request

```markdown
I need to conduct a security audit for AuthService, which is a microservice handling user authentication and authorization.

Technical Stack:
- Language: Java 17
- Framework: Spring Boot 3.0
- Database: PostgreSQL 15
- Infrastructure: Kubernetes on AWS

Security Requirements:
1. Zero Trust Architecture
2. Multi-factor Authentication
3. Secure Session Management
4. Audit Logging
5. Secrets Management

Compliance Requirements:
1. OWASP Top 10 2021
2. GDPR Article 32
3. SOC 2 Type II
4. PCI DSS v4.0

Please help set up the security audit project structure and documentation.
```

## Project Structure

The AI will create:
```
project-root/
├── .audit/
│   ├── scope.md           # Audit scope definition
│   ├── arch.md           # Architecture analysis
│   ├── domain-1/         # Audit domains
│   │   ├── task-1.audit.md
│   │   └── vuln-1.vuln.md
│   └── evidence/         # Audit evidence
├── .cursor/
│   └── rules/            # Audit rules
├── docs/
│   └── workflow-rules.md # Process documentation
└── xnotes/
    └── templates/        # Work templates
```

## Required Documentation

1. Scope Document (.audit/scope.md)
   - Project boundaries
   - Security objectives
   - Risk assessment
   - Timeline and milestones
   - Team and responsibilities

2. Architecture Document (.audit/arch.md)
   - System components
   - Trust boundaries
   - Data flows
   - Security controls
   - Technology stack

3. Workflow Rules (docs/workflow-rules.md)
   - Audit methodology
   - Tool configuration
   - Evidence collection
   - Reporting standards
   - Quality criteria

4. Security Templates (xnotes/templates/)
   - Finding templates
   - Evidence templates
   - Report templates
   - Review checklists

## Security Controls

1. Access Management
   - Authentication methods
   - Authorization model
   - Session handling
   - Token management

2. Data Protection
   - Encryption standards
   - Key management
   - Data classification
   - Privacy controls

3. Infrastructure Security
   - Network segmentation
   - Cloud security
   - Container security
   - Monitoring setup

4. Application Security
   - Input validation
   - Output encoding
   - Error handling
   - Logging standards

## Audit Domains

1. Authentication Domain
   - Login mechanisms
   - Password policies
   - MFA implementation
   - Session management

2. Authorization Domain
   - Access control
   - Role management
   - Permission model
   - Policy enforcement

3. Data Security Domain
   - Data encryption
   - Data storage
   - Data transmission
   - Data deletion

4. Infrastructure Domain
   - Network security
   - Cloud configuration
   - Container security
   - Service mesh

## Security Considerations

<critical>
1. Data Handling
   - No production credentials
   - No sensitive data
   - No PII exposure
   - No security bypass

2. Access Control
   - Minimal privileges
   - Secure environments
   - Controlled access
   - Audit logging

3. Documentation
   - Clear objectives
   - Detailed findings
   - Evidence tracking
   - Progress monitoring
</critical>

## Next Steps

After AI Response:
1. Review project structure
2. Validate documentation
3. Configure security tools
4. Begin audit planning
5. Set up monitoring
6. Initialize reporting 