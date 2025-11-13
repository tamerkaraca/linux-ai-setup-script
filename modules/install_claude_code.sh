#!/bin/bash
set -euo pipefail

UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"
: "${NPM_LAST_INSTALL_PREFIX:=}"

# Bu modül, Claude Code CLI'ı kurar ve etkileşimli oturum açma için TTY erişimini doğrular.

# Renk değişkenlerini tanımla (set -u altında güvenli)
: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

# Claude CLI'nın TTY gereksinimi için yardımcılar
supporting_tty() {
    if [[ -t 0 || -t 1 || -t 2 ]]; then
        return 0
    fi
    if [ -e /dev/tty ] && [ -r /dev/tty ] && [ -w /dev/tty ]; then
        return 0
    fi
    return 1
}

declare -A CLAUDE_TEXT_EN=(
    ["install_title"]="Starting Claude Code installation..."
    ["require_login_prompt"]="You need to sign in to Claude Code now."
    ["run_claude_login"]="Please run 'claude login' and finish authentication."
    ["press_enter"]="Press Enter to continue..."
    ["skip_auth_all"]="Authentication skipped in 'Install All' mode."
    ["manual_login"]="Please run '${GREEN}claude login${NC}' manually later."
    ["tty_missing"]="No TTY detected; cannot run 'claude login' in-script."
    ["login_hint"]="Tip: run 'claude login' directly in your terminal."
    ["login_error"]="'claude login' failed. Ink-based UIs may require raw terminal mode."
    ["install_done"]="Claude Code installation completed!"
)

declare -A CLAUDE_TEXT_TR=(
    ["install_title"]="Claude Code kurulumu başlatılıyor..."
    ["require_login_prompt"]="Şimdi Claude Code'a giriş yapmanız gerekiyor."
    ["run_claude_login"]="Lütfen 'claude login' komutunu çalıştırın ve oturumu tamamlayın."
    ["press_enter"]="Devam etmek için Enter'a basın..."
    ["skip_auth_all"]="'Tümünü Kur' modunda kimlik doğrulama atlandı."
    ["manual_login"]="Lütfen daha sonra '${GREEN}claude login${NC}' komutunu manuel olarak çalıştırın."
    ["tty_missing"]="TTY bulunamadı; 'claude login' script içinde çalıştırılamıyor."
    ["login_hint"]="İpucu: Terminalinizde doğrudan 'claude login' komutunu çalıştırın."
    ["login_error"]="'claude login' sırasında hata oluştu. Ink arayüzleri ham terminal moduna ihtiyaç duyabilir."
    ["install_done"]="Claude Code kurulumu tamamlandı!"
)

claude_text() {
    local key="$1"
    local default_value="${CLAUDE_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        echo "${CLAUDE_TEXT_TR[$key]:-$default_value}"
    else
        echo "$default_value"
    fi
}

run_claude_login() {
    if ! supporting_tty; then
        echo -e "${YELLOW}${WARN_TAG}${NC} $(claude_text tty_missing)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(claude_text manual_login)"
        return 0
    fi

    if ! claude login </dev/tty >/dev/tty 2>&1; then
        echo -e "${RED}${ERROR_TAG}${NC} $(claude_text login_error)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(claude_text login_hint)"
        return 1
    fi
}

# Claude Code kurulumu
install_claude_code() {
    local interactive_mode=${1:-true}
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(claude_text install_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    require_node_version 20 "Claude Code CLI" || return 1

    if ! command -v npm >/dev/null 2>&1; then
        echo -e "${RED}${ERROR_TAG}${NC} npm bulunamadı. Lütfen önce Node.js/NPM araçlarını kurun (Ana Menü -> 3)."
        return 1
    fi

    if ! npm_install_global_with_fallback "@anthropic-ai/claude-code" "Claude Code CLI"; then
        echo -e "${RED}${ERROR_TAG}${NC} Claude Code npm paketinin kurulumu başarısız oldu."
        return 1
    fi

    if [ -n "${NPM_LAST_INSTALL_PREFIX}" ]; then
        echo -e "${YELLOW}${INFO_TAG}${NC} Kurulum prefix'i: ${NPM_LAST_INSTALL_PREFIX}"
    fi

    echo -e "${GREEN}${SUCCESS_TAG}${NC} Claude Code sürümü: $(claude --version)"
    
    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(claude_text require_login_prompt)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(claude_text run_claude_login)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(claude_text press_enter)\n"

        run_claude_login || true

        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(claude_text press_enter)"
        read -r -p "" </dev/tty
    else
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(claude_text skip_auth_all)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(claude_text manual_login)"
    fi
    
    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(claude_text install_done)"
}

# Ana kurulum akışı
main() {
    install_claude_code "$@"
}

main "$@"
