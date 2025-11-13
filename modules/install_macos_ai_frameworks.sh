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

# AI Frameworks for macOS using pipx (same as Linux but with Homebrew dependencies)
install_pipx_macos() {
    log_info "Installing pipx for macOS..."
    
    # First ensure Python 3 is installed via Homebrew
    if ! command -v python3 &> /dev/null; then
        log_info "Installing Python 3 via Homebrew..."
        if ! brew install python; then
            log_error "Failed to install Python 3"
            return 1
        fi
    fi
    
    # Install pipx
    if command -v pipx &> /dev/null; then
        log_info "pipx is already installed: $(pipx --version)"
        return 0
    fi
    
    # Try installing pipx via pip3 first
    if python3 -m pip install --user pipx; then
        python3 -m pipx ensurepath
        log_success "pipx installed successfully"
        
        # Add pipx to PATH for current session
        export PATH="$HOME/.local/bin:$PATH"
        
        # Add to shell configuration files
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bash_profile
        
        return 0
    else
        log_error "Failed to install pipx"
        return 1
    fi
}

install_super_gemini_macos() {
    log_info "Installing SuperGemini on macOS..."
    
    if ! command -v pipx &> /dev/null; then
        log_error "pipx is not installed. Installing pipx first..."
        install_pipx_macos
    fi
    
    if pipx install supergemini; then
        log_success "SuperGemini installed successfully"
        log_info "Run 'supergemini login' to authenticate"
        return 0
    else
        log_error "Failed to install SuperGemini"
        return 1
    fi
}

install_super_qwen_macos() {
    log_info "Installing SuperQwen on macOS..."
    
    if ! command -v pipx &> /dev/null; then
        log_error "pipx is not installed. Installing pipx first..."
        install_pipx_macos
    fi
    
    if pipx install superqwen; then
        log_success "SuperQwen installed successfully"
        log_info "Run 'superqwen login' to authenticate"
        return 0
    else
        log_error "Failed to install SuperQwen"
        return 1
    fi
}

install_super_claude_macos() {
    log_info "Installing SuperClaude on macOS..."
    
    if ! command -v pipx &> /dev/null; then
        log_error "pipx is not installed. Installing pipx first..."
        install_pipx_macos
    fi
    
    if pipx install superclaude; then
        log_success "SuperClaude installed successfully"
        log_info "Run 'superclaude login' to authenticate"
        return 0
    else
        log_error "Failed to install SuperClaude"
        return 1
    fi
}

show_macos_framework_menu() {
    while true; do
        clear
        render_setup_banner "$SCRIPT_VERSION" "https://github.com/tamerkaraca/linux-ai-setup-script"
        
        echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
        printf "${BLUE}║%*s║${NC}\n" -63 " macOS AI Frameworks Installation Menu "
        echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}\n"
        
        echo -e "  ${GREEN}1${NC} - Install SuperGemini"
        echo -e "  ${GREEN}2${NC} - Install SuperQwen"
        echo -e "  ${GREEN}3${NC} - Install SuperClaude"
        echo -e "  ${GREEN}4${NC} - Install All Frameworks"
        echo -e "  ${RED}0${NC} - Return to Main Menu"
        echo -e "\n${YELLOW}Note: These frameworks use pipx and require Python 3.${NC}"
        echo
        
        read -r -p "${YELLOW}Your choice:${NC} " choice_input </dev/tty
        
        if [ -z "$(echo "$choice_input" | tr -d '[:space:]')" ]; then
            echo -e "${YELLOW}No selection made. Please try again.${NC}"
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
                    echo -e "${RED}Invalid choice: $raw_choice${NC}"
                    ;;
            esac
        done
        
        echo -e "\n${YELLOW}Press Enter to continue...${NC}"
        read -r </dev/tty
    done
}

# Main execution
if is_macos; then
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew is not installed. Please install Homebrew first."
        echo -e "${YELLOW}Would you like to install Homebrew now? (y/n)${NC}"
        read -r install_brew_choice </dev/tty
        if [[ "$install_brew_choice" =~ ^[Yy]$ ]]; then
            if ! bash -c "$(curl -fsSL https://raw.githubusercontent.com/tamerkaraca/linux-ai-setup-script/main/modules/install_homebrew.sh)"; then
                log_error "Homebrew installation failed. Cannot proceed with AI frameworks installation."
                exit 1
            fi
        else
            log_info "Homebrew installation skipped. Cannot proceed with AI frameworks installation."
            exit 0
        fi
    fi
    
    show_macos_framework_menu
else
    log_error "This module is designed for macOS only"
    exit 1
fi