#!/bin/bash
set -euo pipefail

# Load utils
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$script_dir/utils.bash"
if [ -f "$utils_local" ]; then
    # shellcheck source=/dev/null
    source "$utils_local"
else
    echo "[ERROR] Unable to load utils.bash" >&2
    exit 1
fi

log_info_detail "Starting the cleanup process..."

# Uninstall NPM packages
NPM_PACKAGES=(
    "@google/generative-ai-cli"
    "opencode-cli"
    "@qoder-ai/qodercli"
    "qwen-cli"
    "codex"
    "cline"
    "@cline/cli"
    "cline-cli"
    "@github/copilot-cli"
    "@kilocode/cli"
    "auggie"
    "@auggie/cli"
    "jules-cli"
    "@julep/cli"
    "@continuedev/cli"
)

log_info_detail "Uninstalling NPM packages..."
if command -v npm &> /dev/null; then
    for pkg in "${NPM_PACKAGES[@]}"; do
        if npm list -g --depth=0 | grep -q "$pkg"; then
            log_info_detail "Uninstalling $pkg..."
            npm uninstall -g "$pkg" || log_warn_detail "Failed to uninstall $pkg, it might not be installed."
        fi
    done
else
    log_warn_detail "npm not found, skipping npm package uninstallation."
fi

# Uninstall pipx packages
PIPX_PACKAGES=(
    "claude-cli"
    "anthropic-cli"
    "aider-chat"
    "droid-factory"
    "superclaude"
    "supergemini"
    "superqwen"
)

log_info_detail "Uninstalling pipx packages..."
if command -v pipx &> /dev/null; then
    for pkg in "${PIPX_PACKAGES[@]}"; do
        if pipx list | grep -q "$pkg"; then
            log_info_detail "Uninstalling $pkg..."
            pipx uninstall "$pkg" || log_warn_detail "Failed to uninstall $pkg."
        fi
    done
else
    log_warn_detail "pipx not found, skipping pipx package uninstallation."
fi

# Uninstall curl-installed packages
if [ -f "/usr/local/bin/cursor-agent" ]; then
    log_info_detail "Removing cursor-agent..."
    rm -f "/usr/local/bin/cursor-agent"
    log_success_detail "cursor-agent removed."
fi

# Clean up shell configuration files
log_info_detail "Cleaning shell configuration files..."
for rc_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if [ -f "$rc_file" ]; then
        # Create a backup
        cp "$rc_file" "${rc_file}.bak.cleanup"
        # Remove lines added by the script
        sed -i '/# Added by linux-ai-setup-script/d' "$rc_file"
        log_success_detail "Cleaned $rc_file."
    fi
done

# Remove Oh My Zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
    log_info_detail "Removing Oh My Zsh..."
    rm -rf "$HOME/.oh-my-zsh"
    if [ -f "$HOME/.zshrc.pre-oh-my-zsh" ]; then
        mv "$HOME/.zshrc.pre-oh-my-zsh" "$HOME/.zshrc"
    fi
    log_success_detail "Oh My Zsh removed."
fi

# Remove NVM
if [ -d "$HOME/.nvm" ]; then
    log_info_detail "Removing NVM..."
    rm -rf "$HOME/.nvm"
    log_success_detail "NVM removed."
fi


log_success_detail "Cleanup process completed."
log_warn_detail "You may need to restart your shell for all changes to take effect."

