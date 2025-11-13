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

run_claude_login() {
    if ! supporting_tty; then
        echo -e "${YELLOW}${WARN_TAG}${NC} Geçerli oturumda TTY bulunamadı; 'claude login' CLI içinde çalıştırılamıyor."
        echo -e "${YELLOW}${INFO_TAG}${NC} Lütfen kurulumdan sonra manuel olarak 'claude login' komutunu çalıştırın."
        return 0
    fi

    # CLI'nin ham moda geçebilmesi için giriş/çıkışı doğrudan terminale yönlendir
    if ! claude login </dev/tty >/dev/tty 2>&1; then
        echo -e "${RED}${ERROR_TAG}${NC} 'claude login' çalıştırılırken bir hata oluştu."
        echo -e "${YELLOW}${INFO_TAG}${NC} Yukarıdaki hata, Ink tabanlı arayüzlerin ham moda ihtiyaç duymasından kaynaklanabilir."
        echo -e "${YELLOW}[İPUCU]${NC} Terminalinizde doğrudan 'claude login' komutunu çalıştırarak tekrar deneyin."
        return 1
    fi
}

# Claude Code kurulumu
install_claude_code() {
    local interactive_mode=${1:-true}
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} Claude Code kurulumu başlatılıyor..."
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
        echo -e "\n${YELLOW}${INFO_TAG}${NC} Şimdi Claude Code'a giriş yapmanız gerekiyor."
        echo -e "${YELLOW}${INFO_TAG}${NC} Lütfen 'claude login' komutunu çalıştırın ve oturum açın."
        echo -e "${YELLOW}${INFO_TAG}${NC} Oturum açma tamamlandığında buraya dönün ve Enter'a basın.\n"

        run_claude_login || true

        echo -e "\n${YELLOW}${INFO_TAG}${NC} Oturum açma işlemi tamamlandı mı? (Enter'a basarak devam edin)"
        read -r -p "Devam etmek için Enter'a basın..." </dev/tty
    else
        echo -e "\n${YELLOW}${INFO_TAG}${NC} 'Tümünü Kur' modunda kimlik doğrulama atlandı."
        echo -e "${YELLOW}${INFO_TAG}${NC} Lütfen daha sonra manuel olarak '${GREEN}claude login${NC}' komutunu çalıştırın."
    fi
    
    echo -e "${GREEN}${SUCCESS_TAG}${NC} Claude Code kurulumu tamamlandı!"
}

# Ana kurulum akışı
main() {
    install_claude_code "$@"
}

main "$@"
