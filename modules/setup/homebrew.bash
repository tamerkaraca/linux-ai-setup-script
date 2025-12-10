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

install_homebrew() {
    if ! is_macos; then
        log_error_detail "Homebrew installation is only supported on macOS"
        return 1
    fi
    
    if command -v brew &> /dev/null; then
        log_info_detail "Homebrew is already installed: $(brew --version | head -n1)"
        log_info_detail "Updating Homebrew..."
        if brew update; then
            log_success_detail "Homebrew updated successfully"
        else
            log_warn_detail "Homebrew update failed, but installation may continue"
        fi
        return 0
    fi
    
    log_info_detail "Installing Homebrew..."
    
    # Check for Xcode Command Line Tools
    if ! xcode-select -p &> /dev/null; then
        log_info_detail "Installing Xcode Command Line Tools..."
        xcode-select --install
        log_warn_detail "Please wait for Xcode Command Line Tools installation to complete, then run this script again"
        return 1
    fi
    
    # Install Homebrew
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        log_success_detail "Homebrew installed successfully"
        
        # Add Homebrew to PATH for current session
        if [[ -x "/opt/homebrew/bin/brew" ]]; then
            # Apple Silicon Mac
            export PATH="/opt/homebrew/bin:$PATH"
            # shellcheck disable=SC2016
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
            # shellcheck disable=SC2016
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.bash_profile
        elif [[ -x "/usr/local/bin/brew" ]]; then
            # Intel Mac
            export PATH="/usr/local/bin:$PATH"
            # shellcheck disable=SC2016
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zshrc
            # shellcheck disable=SC2016
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.bash_profile
        fi
        
        # Source the shell environment
        if [[ -f ~/.zshrc ]]; then
            # shellcheck disable=SC1090
            source ~/.zshrc
        elif [[ -f ~/.bash_profile ]]; then
            # shellcheck disable=SC1090
            source ~/.bash_profile
        fi
        
        log_info_detail "Homebrew added to PATH"
        return 0
    else
        log_error_detail "Homebrew installation failed"
        return 1
    fi
}

install_homebrew_cask() {
    if ! is_macos; then
        log_error_detail "Homebrew Cask is only available on macOS"
        return 1
    fi
    
    if ! command -v brew &> /dev/null; then
        log_error_detail "Homebrew is not installed. Please install Homebrew first."
        return 1
    fi
    
    log_info_detail "Ensuring Homebrew Cask is available..."
    # Cask is now integrated into Homebrew by default
    if brew --version | grep -q "Homebrew"; then
        log_success_detail "Homebrew Cask is available"
        return 0
    else
        log_error_detail "Homebrew Cask setup failed"
        return 1
    fi
}

# Main execution
if is_macos; then
    install_homebrew
    install_homebrew_cask
else
    log_error_detail "This module is designed for macOS only"
    exit 1
fi