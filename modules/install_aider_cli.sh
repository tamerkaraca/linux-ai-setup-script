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

declare -A AIDER_TEXT_EN=(
    ["install_title"]="Starting Aider CLI installation using the official installer..."
    ["downloading"]="Downloading the official Aider installer script..."
    ["download_fail"]="Failed to download the installer script from aider.chat."
    ["running_installer"]="Running the official Aider installer... This may take a few minutes."
    ["install_fail"]="Aider CLI installation failed. Please check the output above for errors."
    ["command_missing"]="'aider' command not found after installation. You may need to restart your terminal or check your PATH."
    ["version_info"]="Aider CLI version: %s"
    ["interactive_intro"]="Aider requires API keys to function (e.g., OPENAI_API_KEY)."
    ["batch_skip"]="API key setup skipped in batch mode."
    ["batch_note"]="Before running '%s', please export the necessary API keys (e.g., OPENAI_API_KEY)."
    ["install_done"]="Aider CLI installation completed successfully!"
)

declare -A AIDER_TEXT_TR=(
    ["install_title"]="Aider CLI resmi yükleyici ile kuruluyor..."
    ["downloading"]="Resmi Aider yükleyici betiği indiriliyor..."
    ["download_fail"]="aider.chat adresinden yükleyici betiği indirilemedi."
    ["running_installer"]="Resmi Aider yükleyici çalıştırılıyor... Bu işlem birkaç dakika sürebilir."
    ["install_fail"]="Aider CLI kurulumu başarısız oldu. Hatalar için lütfen yukarıdaki çıktıları kontrol edin."
    ["command_missing"]="'aider' komutu kurulumdan sonra bulunamadı. Terminalinizi yeniden başlatmanız veya PATH'inizi kontrol etmeniz gerekebilir."
    ["version_info"]="Aider CLI sürümü: %s"
    ["interactive_intro"]="Aider'ın çalışması için API anahtarları gereklidir (örn. OPENAI_API_KEY)."
    ["batch_skip"]="Toplu kurulum modunda API anahtarı kurulumu atlandı."
    ["batch_note"]="'%s' komutunu çalıştırmadan önce, lütfen gerekli API anahtarlarını (örn. OPENAI_API_KEY) export edin."
    ["install_done"]="Aider CLI kurulumu başarıyla tamamlandı!"
)

aider_text() {
    local key="$1"
    local default_value="${AIDER_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${AIDER_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

aider_printf() {
    local __out="$1"
    local __key="$2"
    shift 2
    local __fmt
    __fmt="$(aider_text "$__key")"
    # shellcheck disable=SC2059
    printf -v "$__out" "$__fmt" "$@"
}

install_aider_cli() {
    local interactive_mode="true"
    [[ $# -gt 0 && "$1" != --* ]] && interactive_mode="$1"

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(aider_text install_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    local installer_script
    installer_script=$(mktemp)
    
    echo -e "${YELLOW}${INFO_TAG}${NC} $(aider_text downloading)"
    if ! curl -sSf "https://aider.chat/install.sh" -o "$installer_script"; then
        echo -e "${RED}${ERROR_TAG}${NC} $(aider_text download_fail)"
        rm -f "$installer_script"
        return 1
    fi

    echo -e "${YELLOW}${INFO_TAG}${NC} $(aider_text running_installer)"
    
    # The official installer handles Python and dependencies.
    # We run it with bash.
    if ! bash "$installer_script"; then
        echo -e "${RED}${ERROR_TAG}${NC} $(aider_text install_fail)"
        rm -f "$installer_script"
        return 1
    fi
    rm -f "$installer_script"

    # The installer should add the correct path to the shell profile.
    # We need to source it to make the 'aider' command available now.
    reload_shell_configs silent
    hash -r 2>/dev/null || true

    if ! command -v aider >/dev/null 2>&1; then
        # Sometimes the path is in .bashrc but not .profile, try sourcing it.
        # shellcheck source=/dev/null
        [ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"
        hash -r 2>/dev/null || true
        if ! command -v aider >/dev/null 2>&1; then
            echo -e "${RED}${ERROR_TAG}${NC} $(aider_text command_missing)"
            return 1
        fi
    fi

    local aider_version_msg
    aider_printf aider_version_msg version_info "$(aider --version 2>/dev/null || echo 'unknown')"
    echo -e "${GREEN}${SUCCESS_TAG}${NC} ${aider_version_msg}"

    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(aider_text interactive_intro)"
    else
        local batch_msg
        aider_printf batch_msg batch_note "${GREEN}aider${NC}"
        echo -e "\n${YELLOW}${INFO_TAG}${NC} ${batch_msg}"
    fi

    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(aider_text install_done)"
}

main() {
    install_aider_cli "$@"
}

main "$@"