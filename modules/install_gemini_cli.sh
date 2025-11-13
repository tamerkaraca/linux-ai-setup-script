#!/bin/bash
set -euo pipefail

UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"
: "${NPM_LAST_INSTALL_PREFIX:=}"

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

declare -A GEMINI_TEXT_EN=(
    ["install_title"]="Starting Gemini CLI installation..."
    ["npm_missing"]="The npm command was not found. Please install Node.js first."
    ["install_fail"]="Gemini CLI npm installation failed."
    ["prefix_notice"]="Install prefix: %s"
    ["version_info"]="Gemini CLI version: %s"
    ["interactive_intro"]="You need to sign in to Gemini CLI now."
    ["interactive_command"]="Please run 'gemini auth' and complete the flow."
    ["interactive_wait"]="Press Enter once authentication is complete."
    ["manual_skip"]="Authentication skipped in 'Install All' mode."
    ["manual_reminder"]="Please run '${GREEN}gemini auth${NC}' manually later."
    ["manual_hint"]="Manual authentication may be required."
    ["install_done"]="Gemini CLI installation completed!"
    ["auth_prompt"]="Press Enter to continue..."
)

declare -A GEMINI_TEXT_TR=(
    ["install_title"]="Gemini CLI kurulumu başlatılıyor..."
    ["npm_missing"]="npm komutu bulunamadı. Lütfen önce Node.js kurun."
    ["install_fail"]="Gemini CLI npm paketinin kurulumu başarısız oldu."
    ["prefix_notice"]="Kurulum prefix'i: %s"
    ["version_info"]="Gemini CLI sürümü: %s"
    ["interactive_intro"]="Şimdi Gemini CLI'ya giriş yapmanız gerekiyor."
    ["interactive_command"]="Lütfen 'gemini auth' komutunu çalıştırıp oturumu tamamlayın."
    ["interactive_wait"]="Kimlik doğrulama tamamlanınca Enter'a basın."
    ["manual_skip"]="'Tümünü Kur' modunda kimlik doğrulama atlandı."
    ["manual_reminder"]="Lütfen daha sonra '${GREEN}gemini auth${NC}' komutunu manuel olarak çalıştırın."
    ["manual_hint"]="Manuel oturum açma gerekebilir."
    ["install_done"]="Gemini CLI kurulumu tamamlandı!"
    ["auth_prompt"]="Devam etmek için Enter'a basın..."
)

gemini_text() {
    local key="$1"
    local default_value="${GEMINI_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${GEMINI_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

# Gemini CLI kurulumu
install_gemini_cli() {
    local interactive_mode=${1:-true}
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(gemini_text install_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    require_node_version 20 "Gemini CLI" || return 1

    if ! command -v npm >/dev/null 2>&1; then
        echo -e "${RED}${ERROR_TAG}${NC} $(gemini_text npm_missing)"
        return 1
    fi

    if ! npm_install_global_with_fallback "@google/gemini-cli" "Gemini CLI"; then
        echo -e "${RED}${ERROR_TAG}${NC} $(gemini_text install_fail)"
        return 1
    fi

    if [ -n "${NPM_LAST_INSTALL_PREFIX}" ]; then
        local gemini_prefix_fmt
        gemini_prefix_fmt="$(gemini_text prefix_notice)"
        # shellcheck disable=SC2059
        printf -v gemini_prefix_msg "$gemini_prefix_fmt" "${NPM_LAST_INSTALL_PREFIX}"
        echo -e "${YELLOW}${INFO_TAG}${NC} ${gemini_prefix_msg}"
    fi

    local gemini_version_fmt
    gemini_version_fmt="$(gemini_text version_info)"
    # shellcheck disable=SC2059
    printf -v gemini_version_msg "$gemini_version_fmt" "$(gemini --version)"
    echo -e "${GREEN}${SUCCESS_TAG}${NC} ${gemini_version_msg}"
    
    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(gemini_text interactive_intro)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(gemini_text interactive_command)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(gemini_text interactive_wait)\n"
        
        gemini auth </dev/tty >/dev/tty 2>&1 || echo -e "${YELLOW}${INFO_TAG}${NC} $(gemini_text manual_hint)"
        
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(gemini_text auth_prompt)"
        read -r -p "" </dev/tty
    else
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(gemini_text manual_skip)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(gemini_text manual_reminder)"
    fi

    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(gemini_text install_done)"
}

# Ana kurulum akışı
main() {
    install_gemini_cli "$@"
}

main "$@"
