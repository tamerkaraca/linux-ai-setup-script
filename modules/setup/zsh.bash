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
    log_info_detail "$(zsh_text install_title)"
    
    # Check if zsh is already installed
    if command -v zsh >/dev/null 2>&1; then
        local zsh_version
        zsh_version=$(zsh --version 2>/dev/null | head -n1 || echo "unknown")
        log_success_detail "$(zsh_text already_installed)"
        log_info_detail "$(zsh_text version_info "$zsh_version")"
        log_info_detail "$(zsh_text shell_change_info)"
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
        log_error_detail "No supported package manager found. Please install Zsh manually."
        return 1
    fi

    log_info_detail "Installing Zsh using $package_manager..."
    
    # Check if we can use sudo
    if ! sudo -n true 2>/dev/null; then
        log_info_detail "Sudo access required. Please enter your password when prompted."
    fi
    
    case $package_manager in
        apt)
            if ! { sudo apt-get update && sudo apt-get install -y zsh; } 2>/dev/null; then
                log_error_detail "$(zsh_text install_fail)"
                return 1
            fi
            ;;
        yum)
            if ! sudo yum install -y zsh 2>/dev/null; then
                log_error_detail "$(zsh_text install_fail)"
                return 1
            fi
            ;;
        dnf)
            if ! sudo dnf install -y zsh 2>/dev/null; then
                log_error_detail "$(zsh_text install_fail)"
                return 1
            fi
            ;;
        pacman)
            if ! sudo pacman -S --noconfirm zsh 2>/dev/null; then
                log_error_detail "$(zsh_text install_fail)"
                return 1
            fi
            ;;
        zypper)
            if ! sudo zypper install -y zsh 2>/dev/null; then
                log_error_detail "$(zsh_text install_fail)"
                return 1
            fi
            ;;
        brew)
            if ! brew install zsh 2>/dev/null; then
                log_error_detail "$(zsh_text install_fail)"
                return 1
            fi
            ;;
    esac

    # Verify installation
    if command -v zsh >/dev/null 2>&1; then
        local zsh_version
        zsh_version=$(zsh --version 2>/dev/null | head -n1 || echo "unknown")
        log_success_detail "$(zsh_text version_info "$zsh_version")"
        log_info_detail "$(zsh_text shell_change_info)"
        log_success_detail "$(zsh_text install_done)"
    else
        log_error_detail "$(zsh_text install_fail)"
        return 1
    fi
}

main() {
    install_zsh "$@"
}

main "$@"