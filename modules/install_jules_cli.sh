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

declare -A JULES_TEXT_EN=(
    ["install_title"]="Starting Jules CLI installation..."
    ["npm_missing"]="The npm command was not found. Please install Node.js first."
    ["install_fail"]="Jules CLI npm installation failed."
    ["prefix_notice"]="Install prefix: %s"
    ["version_info"]="Jules CLI version: %s"
    ["interactive_intro"]="You need to sign in to Jules CLI now."
    ["interactive_command"]="Please run 'jules login' and complete the flow."
    ["interactive_wait"]="Press Enter once authentication is complete."
    ["manual_skip"]="Authentication skipped in 'Install All' mode."
    ["manual_reminder"]="Please run '${GREEN}jules login${NC}' manually later."
    ["manual_hint"]="Manual authentication may be required."
    ["install_done"]="Jules CLI installation completed!"
    ["auth_prompt"]="Press Enter to continue..."
)

declare -A JULES_TEXT_TR=(
    ["install_title"]="Jules CLI kurulumu başlatılıyor..."
    ["npm_missing"]="npm komutu bulunamadı. Lütfen önce Node.js kurun."
    ["install_fail"]="Jules CLI npm paketinin kurulumu başarısız oldu."
    ["prefix_notice"]="Kurulum prefix'i: %s"
    ["version_info"]="Jules CLI sürümü: %s"
    ["interactive_intro"]="Şimdi Jules CLI'ya giriş yapmanız gerekiyor."
    ["interactive_command"]="Lütfen 'jules login' komutunu çalıştırıp oturumu tamamlayın."
    ["interactive_wait"]="Kimlik doğrulama tamamlanınca Enter'a basın."
    ["manual_skip"]="'Tümünü Kur' modunda kimlik doğrulama atlandı."
    ["manual_reminder"]="Lütfen daha sonra '${GREEN}jules login${NC}' komutunu manuel olarak çalıştırın."
    ["manual_hint"]="Manuel oturum açma gerekebilir."
    ["install_done"]="Jules CLI kurulumu tamamlandı!"
    ["auth_prompt"]="Devam etmek için Enter'a basın..."
)

jules_text() {
    local key="$1"
    local default_value="${JULES_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${JULES_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

# Jules CLI kurulumu
install_jules_cli() {
    local interactive_mode=${1:-true}
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(jules_text install_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    require_node_version 18 "Jules CLI" || return 1

    if ! command -v npm >/dev/null 2>&1; then
        echo -e "${RED}${ERROR_TAG}${NC} $(jules_text npm_missing)"
        return 1
    fi

    if ! npm_install_global_with_fallback "@google/jules" "Jules CLI"; then
        echo -e "${RED}${ERROR_TAG}${NC} $(jules_text install_fail)"
        return 1
    fi

    if [ -n "${NPM_LAST_INSTALL_PREFIX}" ]; then
        local jules_prefix_fmt
        jules_prefix_fmt="$(jules_text prefix_notice)"
        # shellcheck disable=SC2059
        printf -v jules_prefix_msg "%s" "${NPM_LAST_INSTALL_PREFIX}"
        echo -e "${YELLOW}${INFO_TAG}${NC} ${jules_prefix_msg}"
    fi

    local jules_version_fmt
    jules_version_fmt="$(jules_text version_info)"
    # shellcheck disable=SC2059
    printf -v jules_version_msg "%s" "$(jules --version)"
    echo -e "${GREEN}${SUCCESS_TAG}${NC} ${jules_version_msg}"
    
    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(jules_text interactive_intro)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(jules_text interactive_command)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(jules_text interactive_wait)\n"
        
        jules login </dev/tty >/dev/tty 2>&1 || echo -e "${YELLOW}${INFO_TAG}${NC} $(jules_text manual_hint)"
        
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(jules_text auth_prompt)"
        read -r -p "" </dev/tty
    else
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(jules_text manual_skip)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(jules_text manual_reminder)"
    fi

    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(jules_text install_done)"
}

# Ana kurulum akışı
main() {
    install_jules_cli "$@"
}

main "$@"
