#!/bin/bash
set -euo pipefail

: "${OPEN_SPEC_REPO:=https://github.com/Fission-AI/OpenSpec.git}"

UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"

declare -A OPENSPEC_TEXT_EN=(
    ["install_title"]="Starting OpenSpec CLI installation..."
    ["npm_missing"]="npm command not found. Please install Node.js (menu option 3)."
    ["npm_version_fail"]="Unable to read npm version."
    ["npm_upgrade"]="Updating npm (current: %s, target: %s+)."
    ["npm_upgrade_success"]="npm upgraded to %s"
    ["npm_upgrade_fail"]="npm upgrade failed."
    ["install_success"]="OpenSpec CLI installed: %s"
    ["install_fail"]="OpenSpec CLI installation failed."
)

declare -A OPENSPEC_TEXT_TR=(
    ["install_title"]="OpenSpec CLI kurulumu başlatılıyor..."
    ["npm_missing"]="npm komutu bulunamadı. Lütfen menüdeki 3. seçenekle Node.js kurulumunu tamamlayın."
    ["npm_version_fail"]="npm sürümü okunamadı."
    ["npm_upgrade"]="npm sürümü güncelleniyor (mevcut: %s, hedef: %s+)."
    ["npm_upgrade_success"]="npm güncellendi: %s"
    ["npm_upgrade_fail"]="npm güncellemesi başarısız oldu."
    ["install_success"]="OpenSpec CLI kuruldu: %s"
    ["install_fail"]="OpenSpec CLI kurulumu başarısız oldu."
)

openspec_text() {
    local key="$1"
    local default_value="${OPENSPEC_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${OPENSPEC_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

openspec_printf() {
    local __out="$1"
    local __key="$2"
    shift 2
    local __fmt
    __fmt="$(openspec_text "$__key")"
    # shellcheck disable=SC2059
    printf -v "$__out" "$__fmt" "$@"
}

ensure_npm_available_local() {
    if command -v npm >/dev/null 2>&1; then
        return 0
    fi
    if bootstrap_node_runtime; then
        return 0
    fi
    echo -e "${RED}${ERROR_TAG}${NC} $(openspec_text npm_missing)"
    return 1
}

ensure_modern_npm_local() {
    local min_version="9.0.0"
    local current_version
    current_version=$(npm -v 2>/dev/null | tr -d '[:space:]')
    if [ -z "$current_version" ]; then
        echo -e "${RED}${ERROR_TAG}${NC} $(openspec_text npm_version_fail)"
        return 1
    fi
    if [ "$(printf '%s\n%s\n' "$current_version" "$min_version" | sort -V | head -n1)" = "$min_version" ]; then
        return 0
    fi
    local upgrade_msg
    openspec_printf upgrade_msg npm_upgrade "$current_version" "$min_version"
    echo -e "${YELLOW}${INFO_TAG}${NC} ${upgrade_msg}"
    if npm install -g npm@latest >/dev/null 2>&1; then
        local upgrade_done
        openspec_printf upgrade_done npm_upgrade_success "$(npm -v 2>/dev/null)"
        echo -e "${GREEN}${INFO_TAG}${NC} ${upgrade_done}"
        return 0
    fi
    echo -e "${RED}${ERROR_TAG}${NC} $(openspec_text npm_upgrade_fail)"
    return 1
}

install_openspec_cli() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(openspec_text install_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    require_node_version 18 || return 1
    ensure_npm_available_local || return 1
    ensure_modern_npm_local || return 1

    if npm_install_global_with_fallback "@fission-ai/openspec" "OpenSpec CLI"; then
        local openspec_version
        openspec_printf openspec_version install_success "$(openspec --version 2>/dev/null)"
        echo -e "${GREEN}${SUCCESS_TAG}${NC} ${openspec_version}"
    else
        echo -e "${RED}${ERROR_TAG}${NC} $(openspec_text install_fail)"
        return 1
    fi
}

main() {
    install_openspec_cli "$@"
}

main "$@"
