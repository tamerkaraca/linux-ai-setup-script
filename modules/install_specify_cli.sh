#!/bin/bash
set -euo pipefail

UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"

: "${RED:=\033[0;31m}"
: "${GREEN:=\033[0;32m}"
: "${YELLOW:=\033[1;33m}"
: "${BLUE:=\033[0;34m}"
: "${CYAN:=\033[0;36m}"
: "${NC:=\033[0m}"

declare -A SPECIFY_TEXT_EN (
    ["install_title"]="Installing specify-cli (from github/spec-kit)..."
    ["uv_missing"]="'uv' command not found. Please install Python Tools (Main Menu -> 2) first."
    ["installing"]="Installing 'specify-cli' via 'uv tool install' from git..."
    ["install_fail"]="specify-cli installation failed."
    ["command_missing"]="'specify' command not found after installation. Check your PATH (uv's bin path should be sourced)."
    ["version_info"]="specify-cli version: %s"
    ["install_done"]="specify-cli installation completed!"
    ["usage_note"]="You can now use 'specify' to manage your project specs."
)

declare -A SPECIFY_TEXT_TR (
    ["install_title"]="specify-cli (github/spec-kit'ten) kuruluyor..."
    ["uv_missing"]="'uv' komutu bulunamadı. Lütfen önce Python Araçlarını (Ana Menü -> 2) kurun."
    ["installing"]="'specify-cli' git üzerinden 'uv tool install' ile kuruluyor..."
    ["install_fail"]="specify-cli kurulumu başarısız oldu."
    ["command_missing"]="'specify' komutu kurulumdan sonra bulunamadı. PATH ayarlarınızı kontrol edin (uv'nin bin yolu kaynak olarak eklenmelidir)."
    ["version_info"]="specify-cli sürümü: %s"
    ["install_done"]="specify-cli kurulumu tamamlandı!"
    ["usage_note"]="Artık proje spesifikasyonlarınızı yönetmek için 'specify' komutunu kullanabilirsiniz."
)

specify_text() {
    local key="$1"
    local default_value="${SPECIFY_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${SPECIFY_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

install_specify_cli() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(specify_text install_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if ! command -v uv &> /dev/null; then
        echo -e "${RED}${ERROR_TAG}${NC} $(specify_text uv_missing)"
        return 1
    fi

    echo -e "${YELLOW}${INFO_TAG}${NC} $(specify_text installing)"
    if ! uv tool install specify-cli --from git+https://github.com/github/spec-kit.git; then
        echo -e "${RED}${ERROR_TAG}${NC} $(specify_text install_fail)"
        return 1
    fi

    reload_shell_configs silent
    hash -r 2>/dev/null || true

    if ! command -v specify &> /dev/null; then
        echo -e "${RED}${ERROR_TAG}${NC} $(specify_text command_missing)"
        return 1
    fi

    local version_info
    version_info=$(specify --version 2>/dev/null || echo "unknown")
    printf -v version_msg "$(specify_text version_info)" "$version_info"
    echo -e "${GREEN}${SUCCESS_TAG}${NC} $version_msg"
    
    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(specify_text install_done)"
    echo -e "${CYAN}${INFO_TAG}${NC} $(specify_text usage_note)"
}

main() {
    install_specify_cli
}

main "$@"
