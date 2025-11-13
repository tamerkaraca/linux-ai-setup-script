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

declare -A OPCODE_TEXT_EN=(
    ["install_title"]="Starting OpenCode CLI installation..."
    ["npm_missing"]="npm command not found. Please run the Node.js module first."
    ["install_fail"]="OpenCode CLI npm installation failed."
    ["prefix_notice"]="Install prefix: %s"
    ["version_info"]="OpenCode CLI version: %s"
    ["shim_warning"]="OpenCode binary could not be generated; please check your npm prefix."
    ["command_missing"]="'opencode' command is missing. Restart your terminal or update PATH."
    ["interactive_intro"]="You need to sign in to OpenCode CLI now."
    ["interactive_command"]="Run 'opencode login' and finish authentication."
    ["interactive_wait"]="Press Enter once login completes."
    ["manual_skip"]="Authentication skipped in 'Install All' mode."
    ["manual_reminder"]="Please run '${GREEN}opencode login${NC}' manually later."
    ["manual_hint"]="Manual login may be required."
    ["install_done"]="OpenCode CLI installation completed!"
    ["auth_prompt"]="Press Enter to continue..."
)

declare -A OPCODE_TEXT_TR=(
    ["install_title"]="OpenCode CLI kurulumu başlatılıyor..."
    ["npm_missing"]="npm komutu bulunamadı. Lütfen önce Node.js modülünü çalıştırın."
    ["install_fail"]="OpenCode CLI npm paketinin kurulumu başarısız oldu."
    ["prefix_notice"]="Kurulum prefix'i: %s"
    ["version_info"]="OpenCode CLI sürümü: %s"
    ["shim_warning"]="OpenCode binary dosyası oluşturulamadı; npm prefixinizi kontrol edin."
    ["command_missing"]="'opencode' komutu bulunamadı. Terminalinizi yeniden başlatın veya PATH ayarlarınızı kontrol edin."
    ["interactive_intro"]="Şimdi OpenCode CLI'ya giriş yapmanız gerekiyor."
    ["interactive_command"]="Lütfen 'opencode login' komutunu çalıştırın."
    ["interactive_wait"]="Oturum açma tamamlandığında Enter'a basın."
    ["manual_skip"]="'Tümünü Kur' modunda kimlik doğrulama atlandı."
    ["manual_reminder"]="Lütfen daha sonra '${GREEN}opencode login${NC}' komutunu manuel olarak çalıştırın."
    ["manual_hint"]="Manuel oturum açma gerekebilir."
    ["install_done"]="OpenCode CLI kurulumu tamamlandı!"
    ["auth_prompt"]="Devam etmek için Enter'a basın..."
)

opencode_text() {
    local key="$1"
    local default_value="${OPCODE_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${OPCODE_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

ensure_npm_ready() {
    if ! command -v npm >/dev/null 2>&1; then
        echo -e "${RED}${ERROR_TAG}${NC} $(opencode_text npm_missing)"
        return 1
    fi
    return 0
}

ensure_opencode_binary() {
    local prefix="$1"
    local bin_path="${prefix}/bin/opencode"
    if [ -x "$bin_path" ]; then
        return 0
    fi

    local pkg_root="${prefix}/lib/node_modules/opencode-ai"
    local js_entry="${pkg_root}/bin/opencode.js"
    if [ -f "$js_entry" ]; then
        cat > "$bin_path" <<EOF
#!/bin/bash
NODE_BIN="\${NODE_BIN:-node}"
exec "\$NODE_BIN" "$js_entry" "\$@"
EOF
        chmod +x "$bin_path"
        ensure_path_contains_dir "${prefix}/bin" "OpenCode CLI shim"
        return 0
    fi

    return 1
}

install_opencode_cli() {
    local interactive_mode=${1:-true}
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(opencode_text install_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    require_node_version 20 "OpenCode CLI" || return 1
    ensure_npm_ready || return 1

    if ! npm_install_global_with_fallback "opencode-ai" "OpenCode CLI" true; then
        echo -e "${RED}${ERROR_TAG}${NC} $(opencode_text install_fail)"
        return 1
    fi

    local install_prefix="${NPM_LAST_INSTALL_PREFIX:-$(npm_prepare_user_prefix)}"
    ensure_opencode_binary "$install_prefix" || echo -e "${YELLOW}${WARN_TAG}${NC} $(opencode_text shim_warning)"

    if ! command -v opencode >/dev/null 2>&1 && [ -x "${install_prefix}/bin/opencode" ]; then
        ensure_path_contains_dir "${install_prefix}/bin" "OpenCode CLI"
    fi

    if command -v opencode >/dev/null 2>&1; then
        local opcode_version_fmt
        opcode_version_fmt="$(opencode_text version_info)"
        # shellcheck disable=SC2059
        printf -v opcode_version_msg "$opcode_version_fmt" "$(opencode --version)"
        echo -e "${GREEN}${SUCCESS_TAG}${NC} ${opcode_version_msg}"
    else
        echo -e "${RED}${ERROR_TAG}${NC} $(opencode_text command_missing)"
        return 1
    fi

    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(opencode_text interactive_intro)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(opencode_text interactive_command)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(opencode_text interactive_wait)\n"

        opencode login </dev/tty >/dev/tty 2>&1 || echo -e "${YELLOW}${INFO_TAG}${NC} $(opencode_text manual_hint)"

        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(opencode_text auth_prompt)"
        read -r -p "" </dev/tty
    else
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(opencode_text manual_skip)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(opencode_text manual_reminder)"
    fi

    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(opencode_text install_done)"
}

main() {
    install_opencode_cli "$@"
}

main "$@"
