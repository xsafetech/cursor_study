#!/bin/bash
# apply-rules.sh

# Check if target directory is provided
if [ $# -eq 0 ]; then
    echo "Error: Please provide the target project directory"
    echo "Usage: ./apply-rules.sh <target-project-directory>"
    exit 1
fi

TARGET_DIR="$1"

# Create necessary directories
setup_directories() {
    echo "Setting up directory structure..."
    mkdir -p "$TARGET_DIR/.cursor/rules"
    mkdir -p "$TARGET_DIR/.cursor/hooks"
    mkdir -p "$TARGET_DIR/.audit/reports"
    mkdir -p "$TARGET_DIR/.audit/evidence"
    mkdir -p "$TARGET_DIR/docs"
}

# Setup automation hooks
setup_automation() {
    echo "Setting up automation hooks..."
    
    # File change hook
    cat > "$TARGET_DIR/.cursor/hooks/on_file_change.sh" << 'EOL'
#!/bin/bash
FILE=$1
EVENT=$2

# Get file extension
EXT="${FILE##*.}"

# Run appropriate security checks based on file type
case "$EXT" in
    java|py|js|ts|php|go|rs)
        echo "Triggering security scan for: $FILE"
        # Run Semgrep
        semgrep --config=.semgrep.yml "$FILE"
        # Run additional security checks
        run_security_checks "$FILE"
        ;;
esac

# Generate report if needed
if [ "$EVENT" = "save" ]; then
    generate_report
fi
EOL
    
    chmod +x "$TARGET_DIR/.cursor/hooks/on_file_change.sh"
    
    # Project open hook
    cat > "$TARGET_DIR/.cursor/hooks/on_project_open.sh" << 'EOL'
#!/bin/bash

# Check environment
check_environment() {
    echo "Checking security tools..."
    
    # Check required tools
    tools=("semgrep" "sonar-scanner" "git" "docker")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo "Warning: $tool is not installed"
        fi
    done
    
    # Check language support
    echo "Checking language support..."
    languages=("java" "python3" "node" "php" "go" "rustc")
    for lang in "${languages[@]}"; do
        if command -v "$lang" &> /dev/null; then
            echo "✓ $lang installed"
        fi
    done
}

# Run initial security scan
initial_scan() {
    echo "Running initial security scan..."
    semgrep --config=.semgrep.yml .
    generate_report
}

check_environment
initial_scan
EOL
    
    chmod +x "$TARGET_DIR/.cursor/hooks/on_project_open.sh"
}

# Copy rule files
copy_rules() {
    echo "Copying rule files..."
    cp .cursor/rules/*.mdc "$TARGET_DIR/.cursor/rules/"
}

# Setup git ignore
setup_gitignore() {
    echo "Configuring .gitignore..."
    cat > "$TARGET_DIR/.gitignore" << 'EOL'
# Security audit files
.audit/
.cursor/rules/_*.mdc
.cursor/hooks/

# Reports
reports/
evidence/

# Tool specific
.semgrep/
.sonarqube/
EOL
}

# Setup cursor ignore
setup_cursorignore() {
    echo "Configuring .cursorignore..."
    cat > "$TARGET_DIR/.cursorignore" << 'EOL'
.audit/
reports/
evidence/
.git/
node_modules/
EOL
}

# Main execution
echo "Setting up automated security audit workflow..."
setup_directories
setup_automation
copy_rules
setup_gitignore
setup_cursorignore

echo "✅ Setup complete!"
echo "📁 Rules directory: $TARGET_DIR/.cursor/rules/"
echo "🔄 Automation hooks: $TARGET_DIR/.cursor/hooks/"
echo "📊 Reports directory: $TARGET_DIR/.audit/reports/"
echo ""
echo "Next steps:"
echo "1. Review the rules in .cursor/rules/"
echo "2. Customize security checks as needed"
echo "3. Configure integration points"
echo "4. Start using Cursor with automated security audits"