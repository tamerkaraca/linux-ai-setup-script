#!/bin/bash
set -euo pipefail

source_module() {
    local local_path="$1"
    local remote_rel_path="$2"
    if [ -f "$local_path" ]; then
        # shellcheck source=/dev/null
        source "$local_path"
    else
        if ! command -v curl &> /dev/null; then
            echo "${ERROR_TAG} curl command not found; cannot load module '$remote_rel_path'."
            exit 1
        fi
        local remote_url="${SCRIPT_BASE_URL:-https://raw.githubusercontent.com/tamerkaraca/linux-ai-setup-script/main}/${remote_rel_path}"
        # shellcheck disable=SC1090
        source <(curl -fsSL "$remote_url") || {
            echo "${ERROR_TAG} Failed to load module from $remote_url"
            exit 1
        }
    fi
}

# Load required modules
source_module "./modules/utils.sh" "modules/utils.sh"
source_module "./modules/platform_detection.sh" "modules/platform_detection.sh"

install_homebrew() {
    if ! is_macos; then
        log_error "Homebrew installation is only supported on macOS"
        return 1
    fi
    
    if command -v brew &> /dev/null; then
        log_info "Homebrew is already installed: $(brew --version | head -n1)"
        log_info "Updating Homebrew..."
        if brew update; then
            log_success "Homebrew updated successfully"
        else
            log_warning "Homebrew update failed, but installation may continue"
        fi
        return 0
    fi
    
    log_info "Installing Homebrew..."
    
    # Check for Xcode Command Line Tools
    if ! xcode-select -p &> /dev/null; then
        log_info "Installing Xcode Command Line Tools..."
        xcode-select --install
        log_warning "Please wait for Xcode Command Line Tools installation to complete, then run this script again"
        return 1
    fi
    
    # Install Homebrew
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        log_success "Homebrew installed successfully"
        
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
        
        log_info "Homebrew added to PATH"
        return 0
    else
        log_error "Homebrew installation failed"
        return 1
    fi
}

install_homebrew_cask() {
    if ! is_macos; then
        log_error "Homebrew Cask is only available on macOS"
        return 1
    fi
    
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew is not installed. Please install Homebrew first."
        return 1
    fi
    
    log_info "Ensuring Homebrew Cask is available..."
    # Cask is now integrated into Homebrew by default
    if brew --version | grep -q "Homebrew"; then
        log_success "Homebrew Cask is available"
        return 0
    else
        log_error "Homebrew Cask setup failed"
        return 1
    fi
}

# Main execution
if is_macos; then
    install_homebrew
    install_homebrew_cask
else
    log_error "This module is designed for macOS only"
    exit 1
fi