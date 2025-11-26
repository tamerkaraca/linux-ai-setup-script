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

declare -A OHMYZSH_TEXT_EN=(
    ["install_title"]="Starting Oh My Zsh installation..."
    ["zsh_missing"]="Zsh is not installed. Please install Zsh first."
    ["already_installed"]="Oh My Zsh is already installed."
    ["install_fail"]="Oh My Zsh installation failed."
    ["install_success"]="Oh My Zsh installed successfully!"
    ["backup_info"]="Existing .zshrc backed up to .zshrc.backup"
    ["config_info"]="Oh My Zsh configuration files are in ~/.oh-my-zsh"
    ["theme_info"]="You can change themes by editing ~/.zshrc"
    ["install_done"]="Oh My Zsh installation completed!"
)

declare -A OHMYZSH_TEXT_TR=(
    ["install_title"]="Oh My Zsh kurulumu başlatılıyor..."
    ["zsh_missing"]="Zsh kurulu değil. Lütfen önce Zsh kurun."
    ["already_installed"]="Oh My Zsh zaten kurulu."
    ["install_fail"]="Oh My Zsh kurulumu başarısız oldu."
    ["install_success"]="Oh My Zsh başarıyla kuruldu!"
    ["backup_info"]="Mevcut .zshrc dosyası .zshrc.backup olarak yedeklendi"
    ["config_info"]="Oh My Zsh yapılandırma dosyaları ~/.oh-my-zsh içinde"
    ["theme_info"]="Temaları değiştirmek için ~/.zshrc dosyasını düzenleyin"
    ["install_done"]="Oh My Zsh kurulumu tamamlandı!"
)

ohmyzsh_text() {
    local key="$1"
    local default_value="${OHMYZSH_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${OHMYZSH_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

install_oh_my_zsh() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(ohmyzsh_text install_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    # Check if zsh is installed
    if ! command -v zsh >/dev/null 2>&1; then
        echo -e "${RED}${ERROR_TAG}${NC} $(ohmyzsh_text zsh_missing)"
        return 1
    fi

    # Check if oh-my-zsh is already installed
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(ohmyzsh_text already_installed)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(ohmyzsh_text config_info)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(ohmyzsh_text theme_info)"
        return 0
    fi

    # Backup existing .zshrc if it exists
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(ohmyzsh_text backup_info)"
    fi

    # Install Oh My Zsh using the official installation script
    echo -e "${YELLOW}${INFO_TAG}${NC} Downloading Oh My Zsh installation script..."
    
    local install_script_url="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
    local temp_script="/tmp/ohmyzsh_install.sh"
    
    # Download the installation script
    if command -v curl >/dev/null 2>&1; then
        if ! curl -fsSL "$install_script_url" -o "$temp_script"; then
            echo -e "${RED}${ERROR_TAG}${NC} Failed to download Oh My Zsh installation script"
            return 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -qO "$temp_script" "$install_script_url"; then
            echo -e "${RED}${ERROR_TAG}${NC} Failed to download Oh My Zsh installation script"
            return 1
        fi
    else
        echo -e "${RED}${ERROR_TAG}${NC} Neither curl nor wget is available. Please install one of them."
        return 1
    fi

    # Make the script executable
    chmod +x "$temp_script"

    # Run the installation script with unattended mode
    echo -e "${YELLOW}${INFO_TAG}${NC} Installing Oh My Zsh..."
    if RUNZSH=no sh "$temp_script" --unattended; then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(ohmyzsh_text install_success)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(ohmyzsh_text config_info)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(ohmyzsh_text theme_info)"
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(ohmyzsh_text install_done)"
    else
        echo -e "${RED}${ERROR_TAG}${NC} $(ohmyzsh_text install_fail)"
        rm -f "$temp_script"
        return 1
    fi

    # Clean up
    rm -f "$temp_script"

    # Verify installation
    if [ -d "$HOME/.oh-my-zsh" ] && [ -f "$HOME/.zshrc" ]; then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} Oh My Zsh installation verified successfully!"
    else
        echo -e "${RED}${ERROR_TAG}${NC} Oh My Zsh installation verification failed"
        return 1
    fi
}

main() {
    install_oh_my_zsh "$@"
}

main "$@"