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

# AI CLI Tools for macOS using Homebrew
declare -A MACOS_AI_TOOLS=(
    ["claude-code"]="cask"
    ["codex"]="cask"
    ["gemini"]="cask"
    ["cursor-cli"]="cask"
    ["droid"]="cask"
    ["opencode"]="formula"
    ["qwen-code"]="formula"
    ["aider"]="formula"
    ["copilot"]="formula"
    ["node"]="formula"
    ["github"]="cask"
)

install_tool_homebrew() {
    local tool="$1"
    local type="${MACOS_AI_TOOLS[$tool]}"
    
    log_info "Installing $tool via Homebrew ($type)..."
    
    case "$type" in
        "cask")
            if brew install --cask "$tool"; then
                log_success "$tool installed successfully"
                return 0
            else
                log_error "Failed to install $tool"
                return 1
            fi
            ;;
        "formula")
            if brew install "$tool"; then
                log_success "$tool installed successfully"
                return 0
            else
                log_error "Failed to install $tool"
                return 1
            fi
            ;;
        *)
            log_error "Unknown installation type for $tool: $type"
            return 1
            ;;
    esac
}

install_bun_manually() {
    log_info "Installing Bun runtime manually..."
    if curl -fsSL https://bun.com/install | bash; then
        log_success "Bun installed successfully"
        
        # Add Bun to PATH
        # shellcheck disable=SC2016
        echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.zshrc
        # shellcheck disable=SC2016
        echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.bash_profile
        
        # Source for current session
        export PATH="$HOME/.bun/bin:$PATH"
        
        log_info "Bun added to PATH"
        return 0
    else
        log_error "Failed to install Bun"
        return 1
    fi
}

show_macos_ai_menu() {
    while true; do
        clear
        render_setup_banner "$SCRIPT_VERSION" "https://github.com/tamerkaraca/linux-ai-setup-script"
        
        echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
        printf "${BLUE}║%*s║${NC}\n" -63 " macOS AI CLI Tools Installation Menu "
        echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}\n"
        
        echo -e "  ${GREEN}1${NC} - Claude Code (Cask)"
        echo -e "  ${GREEN}2${NC} - Codex CLI (Cask)"
        echo -e "  ${GREEN}3${NC} - Gemini CLI (Cask)"
        echo -e "  ${GREEN}4${NC} - Cursor CLI (Cask)"
        echo -e "  ${GREEN}5${NC} - Droid CLI (Cask)"
        echo -e "  ${GREEN}6${NC} - OpenCode CLI (Formula)"
        echo -e "  ${GREEN}7${NC} - QwenCode CLI (Formula)"
        echo -e "  ${GREEN}8${NC} - Aider CLI (Formula)"
        echo -e "  ${GREEN}9${NC} - GitHub Copilot CLI (Formula)"
        echo -e "  ${GREEN}10${NC} - Node.js (Formula)"
        echo -e "  ${GREEN}11${NC} - GitHub CLI (Cask)"
        echo -e "  ${GREEN}12${NC} - Bun Runtime (Manual Install)"
        echo -e "  ${GREEN}A${NC} - Install All Tools"
        echo -e "  ${RED}0${NC} - Return to Main Menu"
        echo -e "\n${YELLOW}You can make multiple selections with commas (e.g., 1,3,7).${NC}"
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
                1) install_tool_homebrew "claude-code" ;;
                2) install_tool_homebrew "codex" ;;
                3) install_tool_homebrew "gemini" ;;
                4) install_tool_homebrew "cursor-cli" ;;
                5) install_tool_homebrew "droid" ;;
                6) install_tool_homebrew "opencode" ;;
                7) install_tool_homebrew "qwen-code" ;;
                8) install_tool_homebrew "aider" ;;
                9) install_tool_homebrew "copilot" ;;
                10) install_tool_homebrew "node" ;;
                11) install_tool_homebrew "github" ;;
                12) install_bun_manually ;;
                A)
                    install_tool_homebrew "claude-code"
                    install_tool_homebrew "codex"
                    install_tool_homebrew "gemini"
                    install_tool_homebrew "cursor-cli"
                    install_tool_homebrew "droid"
                    install_tool_homebrew "opencode"
                    install_tool_homebrew "qwen-code"
                    install_tool_homebrew "aider"
                    install_tool_homebrew "copilot"
                    install_tool_homebrew "node"
                    install_tool_homebrew "github"
                    install_bun_manually
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
                log_error "Homebrew installation failed. Cannot proceed with AI tools installation."
                exit 1
            fi
        else
            log_info "Homebrew installation skipped. Cannot proceed with AI tools installation."
            exit 0
        fi
    fi
    
    show_macos_ai_menu
else
    log_error "This module is designed for macOS only"
    exit 1
fi