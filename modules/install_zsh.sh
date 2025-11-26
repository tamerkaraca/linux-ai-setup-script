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

declare -A ZSH_TEXT_EN=(
    ["install_title"]="Starting Zsh installation..."
    ["already_installed"]="Zsh is already installed."
    ["install_fail"]="Zsh installation failed."
    ["version_info"]="Zsh version: %s"
    ["shell_change_info"]="To make Zsh your default shell, run: chsh -s $(which zsh)"
    ["install_done"]="Zsh installation completed!"
)

declare -A ZSH_TEXT_TR=(
    ["install_title"]="Zsh kurulumu başlatılıyor..."
    ["already_installed"]="Zsh zaten kurulu."
    ["install_fail"]="Zsh kurulumu başarısız oldu."
    ["version_info"]="Zsh sürümü: %s"
    ["shell_change_info"]="Zsh'i varsayılan shell yapmak için: chsh -s $(which zsh)"
    ["install_done"]="Zsh kurulumu tamamlandı!"
)

zsh_text() {
    local key="$1"
    local default_value="${ZSH_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${ZSH_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

install_zsh() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(zsh_text install_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    # Check if zsh is already installed
    if command -v zsh >/dev/null 2>&1; then
        local zsh_version
        zsh_version=$(zsh --version 2>/dev/null | head -n1 || echo "unknown")
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(zsh_text already_installed)"
        local version_fmt
        version_fmt="$(zsh_text version_info)"
        printf -v version_msg "%s" "$zsh_version"
        echo -e "${GREEN}${INFO_TAG}${NC} ${version_msg}"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(zsh_text shell_change_info)"
        return 0
    fi

    # Detect package manager and install zsh
    local package_manager=""
    if command -v apt-get >/dev/null 2>&1; then
        package_manager="apt"
    elif command -v yum >/dev/null 2>&1; then
        package_manager="yum"
    elif command -v dnf >/dev/null 2>&1; then
        package_manager="dnf"
    elif command -v pacman >/dev/null 2>&1; then
        package_manager="pacman"
    elif command -v zypper >/dev/null 2>&1; then
        package_manager="zypper"
    elif command -v brew >/dev/null 2>&1; then
        package_manager="brew"
    else
        echo -e "${RED}${ERROR_TAG}${NC} No supported package manager found. Please install Zsh manually."
        return 1
    fi

    echo -e "${YELLOW}${INFO_TAG}${NC} Installing Zsh using $package_manager..."
    
    # Check if we can use sudo
    if ! sudo -n true 2>/dev/null; then
        echo -e "${YELLOW}${INFO_TAG}${NC} Sudo access required. Please enter your password when prompted."
    fi
    
    case $package_manager in
        apt)
            if ! { sudo apt-get update && sudo apt-get install -y zsh; } 2>/dev/null; then
                echo -e "${RED}${ERROR_TAG}${NC} $(zsh_text install_fail)"
                return 1
            fi
            ;;
        yum)
            if ! sudo yum install -y zsh 2>/dev/null; then
                echo -e "${RED}${ERROR_TAG}${NC} $(zsh_text install_fail)"
                return 1
            fi
            ;;
        dnf)
            if ! sudo dnf install -y zsh 2>/dev/null; then
                echo -e "${RED}${ERROR_TAG}${NC} $(zsh_text install_fail)"
                return 1
            fi
            ;;
        pacman)
            if ! sudo pacman -S --noconfirm zsh 2>/dev/null; then
                echo -e "${RED}${ERROR_TAG}${NC} $(zsh_text install_fail)"
                return 1
            fi
            ;;
        zypper)
            if ! sudo zypper install -y zsh 2>/dev/null; then
                echo -e "${RED}${ERROR_TAG}${NC} $(zsh_text install_fail)"
                return 1
            fi
            ;;
        brew)
            if ! brew install zsh 2>/dev/null; then
                echo -e "${RED}${ERROR_TAG}${NC} $(zsh_text install_fail)"
                return 1
            fi
            ;;
    esac

    # Verify installation
    if command -v zsh >/dev/null 2>&1; then
        local zsh_version
        zsh_version=$(zsh --version 2>/dev/null | head -n1 || echo "unknown")
        local version_fmt
        version_fmt="$(zsh_text version_info)"
        printf -v version_msg "%s" "$zsh_version"
        echo -e "${GREEN}${SUCCESS_TAG}${NC} ${version_msg}"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(zsh_text shell_change_info)"
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(zsh_text install_done)"
    else
        echo -e "${RED}${ERROR_TAG}${NC} $(zsh_text install_fail)"
        return 1
    fi
}

main() {
    install_zsh "$@"
}

main "$@"