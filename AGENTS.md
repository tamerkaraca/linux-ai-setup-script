# Agent Guidelines for Linux AI Setup Script

This document provides essential information for AI agents working with the Linux AI Setup Script codebase.

## Project Overview

The Linux AI Setup Script is a modular Bash-based bootstrapper for preparing AI development workstations on Linux/WSL and macOS. It provides interactive menus to install AI CLI tools, frameworks, development environments, and auxiliary tools with bilingual support (English and Turkish).

### Architecture

- **Main Entry Point**: `setup` - Single script that orchestrates all functionality
- **Module System**: Located in `modules/` directory, organized by purpose
- **Remote Execution**: Supports `bash -c "$(curl ...)"` pattern with automatic module downloading
- **Self-Healing**: Auto-detects and fixes Windows CRLF line endings
- **Platform Detection**: Auto-detects Linux/WSL vs macOS and appropriate package managers

### Directory Structure

```
modules/
├── utils/           # Core utilities and helpers (always loaded first)
│   ├── utils.bash           # Logging, package management, i18n
│   ├── banner.bash          # ASCII banner rendering
│   └── platform_detection.bash  # OS/platform detection
├── cli/             # Individual CLI tool installers
├── menus/           # Interactive menu definitions
├── setup/           # System configuration scripts
├── auxiliary/        # Helper tools (conductor, openspec, etc.)
├── frameworks/       # AI framework installers (SuperGemini, SuperClaude, etc.)
└── utils/           # Utility functions (cleanup, nodejs tools, etc.)
conductor/             # Project management and development guidelines
```

## Essential Commands

### Validation (REQUIRED before commits)
```bash
# Syntax check all scripts
bash -n modules/**/*.bash

# Static analysis for best practices
shellcheck modules/**/*.bash

# Validate all 54 scripts (as per README)
find modules -name "*.bash" -exec bash -n {} \; -exec shellcheck {} \;
```

### Running the Setup Script
```bash
# Local execution
./setup

# Remote execution (one-liner)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/tamerkaraca/linux-ai-setup-script/main/setup)"

# With specific branch
SETUP_BRANCH=feature-branch bash -c "$(curl ...)"
```

### Testing Individual Modules
```bash
# Run a specific module directly
bash modules/cli/claude_code.bash

# Test with language override
LANGUAGE=tr bash modules/cli/claude_code.bash
```

### Git Workflow
```bash
# Follow conventional commits (per conductor/workflow.md)
git commit -m "feat(cli): Add support for new tool"
git commit -m "fix(php): Resolve polkitd installation error"

# Attach task summaries using git notes
git notes add -m "Task summary..." <commit_hash>

# Check script validation status
# Currently: 54 scripts validated (53 modules + setup)
```

## Code Patterns and Conventions

### Module Header Pattern
All modules MUST follow this exact structure:

```bash
#!/bin/bash
set -euo pipefail

# Resolve directory this script lives in so sources work regardless of CWD
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$script_dir/../utils/utils.bash"
platform_local="$script_dir/../utils/platform_detection.bash"

# Prefer local direct source (relative to this file). If not available, fall back to
# setup-provided `source_module` helper when running under main `setup` script.
if [ -f "$utils_local" ]; then
    # shellcheck source=/dev/null
    source "$utils_local"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/utils.bash" "modules/utils/utils.bash"
else
    echo "[HATA/ERROR] utils.bash yüklenemedi / Unable to load utils.bash (tried $utils_local)" >&2
    exit 1
fi

if [ -f "$platform_local" ]; then
    # shellcheck source=/dev/null
    source "$platform_local"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/platform_detection.bash" "modules/utils/platform_detection.bash"
fi

# Color definitions (fallback to ensure colors are set)
: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"
```

### Internationalization (i18n) Pattern

All user-facing text MUST be bilingual (English and Turkish):

```bash
declare -A MODULE_TEXT_EN=(
    ["installing"]="Installing tool..."
    ["install_done"]="Installation completed"
    ["error"]="Error occurred"
)

declare -A MODULE_TEXT_TR=(
    ["installing"]="Araç kuruluyor..."
    ["install_done"]="Kurulum tamamlandı"
    ["error"]="Hata oluştu"
)

module_text() {
    local key="$1"
    local default_value="${MODULE_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${MODULE_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

# Usage:
log_info "$(module_text installing)"
```

### Logging Functions
Use these standardized logging functions from `utils.bash`:

```bash
log_info_detail "Message"      # Cyan [INFO] tag
log_warn_detail "Message"      # Yellow [WARNING] tag
log_error_detail "Message"     # Red [ERROR] tag
log_success_detail "Message"   # Green [SUCCESS] tag
```

### Color Scheme
- **Cyan**: Informational messages, `[INFO]` tag
- **Green**: Success/completion, `[SUCCESS]` tag
- **Yellow**: Warnings, `[WARNING]` tag
- **Red**: Errors, `[ERROR]` tag
- **Blue**: Section headers, optional
- **No Color (NC)**: Reset to default

### Package Installation Pattern

Use the universal `install_package` function from utils.bash:

```bash
# Install from npm
install_package "Tool Name" "npm" "command_name" "package1" "package2"

# Install from pipx
install_package "Tool Name" "pipx" "command_name" "package"

# Install from uv
install_package "Tool Name" "uv" "command_name" "package"

# The function handles:
# - Checking if already installed
# - Prerequisites (e.g., Node.js version)
# - Multiple package name attempts
# - PATH verification
```

### TTY Handling for Interactive Prompts

When scripts need interactive input (especially during remote execution):

```bash
attach_tty_and_run() {
    if [ -e /dev/tty ] && [ -r /dev/tty ] && [ -w /dev/tty ]; then
        "$@" </dev/tty
    else
        "$@"
    fi
}

# Example: Login flow
attach_tty_and_run claude login
```

### Node.js Version Requirements

Use `require_node_version` before npm installations:

```bash
require_node_version 20 "Tool Name" || return 1
npm install -g package
```

## Important Gotchas

### 1. Remote Execution Context
When running via `bash -c "$(curl ...)"`:
- Modules are downloaded to `~/.linux-ai-setup-script/remote_modules_$$/`
- Environment variables (`PKG_MANAGER`, `LANGUAGE`, etc.) are passed to sub-processes
- The `source_module` function handles remote downloading
- Always use absolute paths when referencing local resources

### 2. Windows CRLF Handling
The main `setup` script auto-detects and fixes CRLF line endings:
- If detected, it fixes and restarts itself
- Agents editing files should use LF (Unix) line endings
- Set your editor to use LF for Bash scripts

### 3. Associative Arrays Cannot Be Exported
i18n associative arrays (`declare -A`) are NOT exported:
- Each module must define its own text arrays
- The `setup_text` function is defined in `setup` script (not exported)
- For modules, use inline bilingual text or local text functions

### 4. shellcheck Directives
Use `# shellcheck` directives to suppress legitimate warnings:
```bash
# shellcheck source=/dev/null
source "$utils_local"

# Disable specific rule with reason
# shellcheck disable=SC2154
```

### 5. Platform-Specific Behavior
Linux and macOS have different menu layouts and tool availability:
- Linux: Native package managers (apt, dnf, yum, pacman)
- macOS: Homebrew for almost everything
- Always check `is_macos` or `is_linux` platform detection functions

### 6. WSL Considerations
- WSL may have `/mnt/` paths in PATH (cleaned automatically)
- Browser integration requires `wslu` package
- Some CLI tools need special handling for WSL2 vs WSL1

### 7. PATH Management
Always use `ensure_path_contains_dir()` from utils.bash:
```bash
ensure_path_contains_dir "$HOME/.local/bin" "tool_name"
reload_shell_configs silent
```
This adds to:
- `~/.bashrc`
- `~/.zshrc`
- `~/.profile`

### 8. Interactive vs Batch Mode
Menu modules accept two modes:
- **Interactive** (`true`): Pauses for user input, shows login prompts
- **Batch** (`false`): Skips interactive prompts, prints summary

Example:
```bash
main() {
    local interactive_mode="${1:-true}"

    # Installation logic...

    if [ "$interactive_mode" = true ]; then
        read -r -p "Continue? (y/n): " choice </dev/tty
    fi
}
```

## Testing and Validation Requirements

### Pre-Commit Checklist (from conductor/product-guidelines.md)
- [ ] All modified scripts pass `bash -n` syntax check
- [ ] All modified scripts pass `shellcheck` validation
- [ ] Code follows existing style (variable naming, function structure)
- [ ] Both English and Turkish translations provided
- [ ] Works on Linux/WSL
- [ ] Works on macOS (if applicable)
- [ ] Both local and remote execution tested

### Quality Gates
Before marking work complete, verify:
- No shellcheck errors (or justified suppressions)
- No syntax errors
- No hardcoded secrets or API keys
- All user-facing messages are bilingual
- Error messages are helpful and actionable

### Commit Message Format
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Examples:
```
feat(cli): Add support for new AI tool
fix(php): Resolve polkitd installation error on Debian
docs(readme): Update installation instructions
```

## Project-Specific Context

### Conductor System
The `conductor/` directory contains project management files:
- `product.md`: Product definition and vision
- `product-guidelines.md`: Communication, visual identity, and contribution standards
- `workflow.md`: Task lifecycle, TDD process, quality gates
- `tracks/`: Active development tracks with metadata

**CRITICAL**: When making changes, update relevant conductor documents if:
- Adding new features (update `product.md`)
- Changing workflows (update `workflow.md`)
- Modifying standards (update `product-guidelines.md`)

### MCP Servers Configuration
`.mcp.json` contains MCP server configurations (template file, not actively used by setup script).

### Language Detection
Language auto-detection:
- Checks `LC_ALL` then `LANG` environment variables
- Matches locale starting with `tr` for Turkish
- Default is English if no match
- User can toggle via `L` menu option

### Package Manager Variables
Auto-detected and exported:
- `PKG_MANAGER`: `apt`, `dnf`, `yum`, `pacman`, or `brew`
- `UPDATE_CMD`: System update command for detected manager
- `INSTALL_CMD`: Package install command for detected manager
- These are passed to all sub-modules via environment

## Common Module Types

### CLI Installer Modules (in `modules/cli/`)
Purpose: Install individual AI CLI tools (Claude Code, Gemini, etc.)
Pattern:
1. Check prerequisites (Node.js version)
2. Use `install_package` for installation
3. Handle interactive login (TTY-aware)
4. Print success and usage tips
5. Accept `true`/`false` for interactive mode

### Menu Modules (in `modules/menus/`)
Purpose: Provide interactive menus for grouped tools
Pattern:
1. Define bilingual text arrays
2. Create menu display function
3. Handle comma-separated selections (`1,3,5`)
4. Call individual CLI modules via `run_module`
5. Handle "Install All" batch mode
6. Display summary after batch installs

### Framework Installer Modules (in `modules/frameworks/`)
Purpose: Install AI frameworks (SuperClaude, SuperGemini, etc.)
Pattern:
1. Ensure pipx is installed
2. Install framework via pipx
3. Run framework's install command (TTY-aware)
4. Print usage tips and configuration guidance
5. Handle API key prompts gracefully

### Setup Modules (in `modules/setup/`)
Purpose: System configuration (Git, Zsh, etc.)
Pattern:
1. Detect current state
2. Prompt for configuration values
3. Apply configuration to appropriate files
4. Provide clear success/error feedback
5. Offer reconfiguration options

## Security Considerations

### API Key Handling
- Never log or print API keys in plain text
- Use `mask_secret` utility (from `utils.bash`) for display
- Store keys in appropriate config directories (`~/.claude/`, `~/.gemini/`, etc.)
- Allow users to keep existing values by providing empty input

### Input Validation
- Validate user input before executing commands
- Sanitize file paths and environment variables
- Use `set -euo pipefail` for error propagation
- Check command existence before use (`command -v`)

### Permissions
- Use `sudo` only when necessary (system package installs)
- Document when sudo is required
- Prefer user-space installations (npm global, pipx, homebrew)

## Debugging Tips

### Enable Verbose Mode
```bash
# Run setup with bash debugging
bash -x ./setup

# Run module with debugging
bash -x modules/cli/claude_code.bash
```

### Check Module Loading
```bash
# Verify utils are loaded
grep "log_info" modules/cli/claude_code.bash

# Test module sourcing
bash -c 'source modules/utils/utils.bash && command -v log_info'
```

### Test Remote Execution
```bash
# Simulate remote download
SCRIPT_BASE_URL="file://$(pwd)" bash -c "$(cat setup)"

# Test module downloading from specific branch
SETUP_BRANCH=test-branch bash -c "$(curl ...)"
```

## Resources

- **README.md**: Complete user documentation with menu references
- **conductor/product-guidelines.md**: Contribution and code quality standards
- **conductor/workflow.md**: TDD workflow and task lifecycle
- **conductor/code_styleguides/****: Language-specific style guides
- **GitHub Repository**: https://github.com/tamerkaraca/linux-ai-setup-script

## Key Takeaways for Agents

1. **ALWAYS read files before editing** - Check exact whitespace and indentation
2. **Follow existing patterns** - Don't reinvent module structure
3. **Provide bilingual translations** - All user-facing text needs EN/TR versions
4. **Test both execution modes** - Local clone AND remote `curl | bash`
5. **Validate before committing** - Run `bash -n` and `shellcheck`
6. **Use standard functions** - Prefer `install_package`, `log_info_detail`, etc.
7. **Handle TTY gracefully** - Scripts must work in both interactive and remote contexts
8. **Update documentation** - README and conductor files must stay in sync with code
