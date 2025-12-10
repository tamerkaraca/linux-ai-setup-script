#!/bin/bash
set -euo pipefail

# Resolve the directory this script lives in so sources work regardless of CWD
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$script_dir/../utils/utils.bash"
platform_local="$script_dir/../utils/platform_detection.bash"

# Prefer local direct source (relative to this file). If not available, fall back to
# the setup-provided `source_module` helper when running under the main `setup` script.
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

# AI Frameworks for macOS using pipx (same as Linux but with Homebrew dependencies)
install_pipx_macos() {
    log_info_detail "Installing pipx for macOS..."
    
    # First ensure Python 3 is installed via Homebrew
    if ! command -v python3 &> /dev/null; then
        log_info_detail "Installing Python 3 via Homebrew..."
        if ! brew install python; then
            log_error_detail "Failed to install Python 3"
            return 1
        fi
    fi
    
    # Install pipx
    if command -v pipx &> /dev/null; then
        log_info_detail "pipx is already installed: $(pipx --version)"
        return 0
    fi
    
    # Try installing pipx via pip3 first
    if python3 -m pip install --user pipx; then
        python3 -m pipx ensurepath
        log_success_detail "pipx installed successfully"
        
        # Add pipx to PATH for current session
        export PATH="$HOME/.local/bin:$PATH"
        
        # Add to shell configuration files
        # shellcheck disable=SC2016
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
        # shellcheck disable=SC2016
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bash_profile
        
        return 0
    else
        log_error_detail "Failed to install pipx"
        return 1
    fi
}

install_super_gemini_macos() {
    log_info_detail "Installing SuperGemini on macOS..."
    
    if ! command -v pipx &> /dev/null; then
        log_error_detail "pipx is not installed. Installing pipx first..."
        install_pipx_macos
    fi
    
    if pipx install supergemini; then
        log_success_detail "SuperGemini installed successfully"
        log_info_detail "Run 'supergemini login' to authenticate"
        return 0
    else
        log_error_detail "Failed to install SuperGemini"
        return 1
    fi
}

install_super_qwen_macos() {
    log_info_detail "Installing SuperQwen on macOS..."
    
    if ! command -v pipx &> /dev/null; then
        log_error_detail "pipx is not installed. Installing pipx first..."
        install_pipx_macos
    fi
    
    if pipx install superqwen; then
        log_success_detail "SuperQwen installed successfully"
        log_info_detail "Run 'superqwen login' to authenticate"
        return 0
    else
        log_error_detail "Failed to install SuperQwen"
        return 1
    fi
}

install_super_claude_macos() {
    log_info_detail "Installing SuperClaude on macOS..."
    
    if ! command -v pipx &> /dev/null; then
        log_error_detail "pipx is not installed. Installing pipx first..."
        install_pipx_macos
    fi
    
    if pipx install superclaude; then
        log_success_detail "SuperClaude installed successfully"
        log_info_detail "Run 'superclaude login' to authenticate"
        return 0
    else
        log_error_detail "Failed to install SuperClaude"
        return 1
    fi
}

show_macos_framework_menu() {
    while true; do
        clear
        render_setup_banner "$SCRIPT_VERSION" "https://github.com/tamerkaraca/linux-ai-setup-script"
        
        log_info_detail "macOS AI Frameworks Installation Menu"
        
        log_info_detail "  1 - Install SuperGemini"
        log_info_detail "  2 - Install SuperQwen"
        log_info_detail "  3 - Install SuperClaude"
        log_info_detail "  4 - Install All Frameworks"
        log_info_detail "  0 - Return to Main Menu"
        log_info_detail "Note: These frameworks use pipx and require Python 3."
        
        read -r -p "Your choice: " choice_input </dev/tty
        
        if [ -z "$(echo "$choice_input" | tr -d '[:space:]')" ]; then
            log_warn_detail "No selection made. Please try again."
            sleep 1
            continue
        fi
        
        IFS=',' read -ra USER_CHOICES <<< "$choice_input"
        
        for raw_choice in "${USER_CHOICES[@]}"; do
            choice=$(echo "$raw_choice" | tr -d '[:space:]')
            [ -z "$choice" ] && continue
            choice=$(echo "$choice" | tr '[:lower:]' '[:upper:]')
            
            case "$choice" in
                1) install_super_gemini_macos ;;
                2) install_super_qwen_macos ;;
                3) install_super_claude_macos ;;
                4)
                    install_super_gemini_macos
                    install_super_qwen_macos
                    install_super_claude_macos
                    ;;
                0)
                    return 0
                    ;;
                *)
                    log_error_detail "Invalid choice: $raw_choice"
                    ;;
            esac
        done
        
        read -r -p "Press Enter to continue..." </dev/tty
    done
}

# Main execution
if is_macos; then
    if ! command -v brew &> /dev/null; then
        log_error_detail "Homebrew is not installed. Please install Homebrew first."
        read -r -p "Would you like to install Homebrew now? (y/n)" install_brew_choice </dev/tty
        if [[ "$install_brew_choice" =~ ^[Yy]$ ]]; then
            if ! bash -c "$(curl -fsSL https://raw.githubusercontent.com/tamerkaraca/linux-ai-setup-script/main/modules/install_homebrew.sh)"; then
                log_error_detail "Homebrew installation failed. Cannot proceed with AI frameworks installation."
                exit 1
            fi
        else
            log_info_detail "Homebrew installation skipped. Cannot proceed with AI frameworks installation."
            exit 0
        fi
    fi
    
    show_macos_framework_menu
else
    log_error_detail "This module is designed for macOS only"
    exit 1
fi