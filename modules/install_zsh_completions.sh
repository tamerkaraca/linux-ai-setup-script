#!/bin/bash
set -euo pipefail

UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

declare -A ZSH_COMPLETIONS_TEXT_EN=(
    ["install_title"]="Starting Zsh Completions installation..."
    ["zsh_missing"]="Zsh is not installed. Please install Zsh first."
    ["already_installed"]="Zsh Completions is already installed."
    ["install_fail"]="Zsh Completions installation failed."
    ["install_success"]="Zsh Completions installed successfully!"
    ["config_info"]="Plugin configured in ~/.zshrc"
    ["reload_info"]="Run 'source ~/.zshrc' or restart terminal to apply changes"
    ["install_done"]="Zsh Completions installation completed!"
)

declare -A ZSH_COMPLETIONS_TEXT_TR=(
    ["install_title"]="Zsh Tamamlamaları kurulumu başlatılıyor..."
    ["zsh_missing"]="Zsh kurulu değil. Lütfen önce Zsh kurun."
    ["already_installed"]="Zsh Tamamlamaları zaten kurulu."
    ["install_fail"]="Zsh Tamamlamaları kurulumu başarısız oldu."
    ["install_success"]="Zsh Tamamlamaları başarıyla kuruldu!"
    ["config_info"]="Eklenti ~/.zshrc dosyasında yapılandırıldı"
    ["reload_info"]="Değişiklikleri uygulamak için 'source ~/.zshrc' çalıştırın veya terminali yeniden başlatın"
    ["install_done"]="Zsh Tamamlamaları kurulumu tamamlandı!"
)

zsh_completions_text() {
    local key="$1"
    local default_value="${ZSH_COMPLETIONS_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${ZSH_COMPLETIONS_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

install_zsh_completions() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(zsh_completions_text install_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    # Check if zsh is installed
    if ! command -v zsh >/dev/null 2>&1; then
        echo -e "${RED}${ERROR_TAG}${NC} $(zsh_completions_text zsh_missing)"
        return 1
    fi

    # Check if already installed
    local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions"
    if [ -d "$plugin_dir" ]; then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(zsh_completions_text already_installed)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(zsh_completions_text config_info)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(zsh_completions_text reload_info)"
        return 0
    fi

    # Create custom plugins directory if it doesn't exist
    local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    mkdir -p "$custom_dir"

    # Clone the repository
    echo -e "${YELLOW}${INFO_TAG}${NC} Cloning Zsh Completions repository..."
    if ! git clone https://github.com/zsh-users/zsh-completions.git "$plugin_dir"; then
        echo -e "${RED}${ERROR_TAG}${NC} $(zsh_completions_text install_fail)"
        return 1
    fi

    # Add plugin to .zshrc if not already present
    local zshrc_file="$HOME/.zshrc"
    if [ -f "$zshrc_file" ]; then
        # Check if plugin is already in the plugins list
        if ! grep -q "zsh-completions" "$zshrc_file"; then
            echo -e "${YELLOW}${INFO_TAG}${NC} Adding plugin to ~/.zshrc..."
            
            # Find plugins line and add zsh-completions
            if grep -q "^plugins=(" "$zshrc_file"; then
                # Add to existing plugins list
                sed -i '/^plugins=(/ s/)/ zsh-completions)/' "$zshrc_file"
            else
                # Add plugins line if it doesn't exist
                echo -e "\n# Zsh Completions plugin\nplugins=(zsh-completions)" >> "$zshrc_file"
            fi
        fi

        # Add compinit configuration if not already present
        if ! grep -q "autoload -U compinit" "$zshrc_file"; then
            echo -e "${YELLOW}${INFO_TAG}${NC} Adding compinit configuration to ~/.zshrc..."
            cat >> "$zshrc_file" << 'EOF'

# Zsh Completions configuration
autoload -U compinit
compinit -i
EOF
        fi
    else
        # Create .zshrc with plugin
        echo -e "${YELLOW}${INFO_TAG}${NC} Creating ~/.zshrc with plugin configuration..."
        cat > "$zshrc_file" << 'EOF'
# Zsh Completions plugin
plugins=(zsh-completions)

# Zsh Completions configuration
autoload -U compinit
compinit -i

# Source Oh My Zsh if it exists
if [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    source "$HOME/.oh-my-zsh/oh-my-zsh.sh"
fi
EOF
    fi

    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(zsh_completions_text install_success)"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(zsh_completions_text config_info)"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(zsh_completions_text reload_info)"
    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(zsh_completions_text install_done)"
}

main() {
    install_zsh_completions "$@"
}

main "$@"