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

# Gemini CLI kurulumu
install_gemini_cli() {
    local interactive_mode=${1:-true}
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Gemini CLI kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    require_node_version 20 "Gemini CLI" || return 1

    if ! command -v npm >/dev/null 2>&1; then
        echo -e "${RED}[HATA]${NC} npm komutu bulunamadı. Lütfen Node.js kurulumu sonrası 'npm' erişilebilir olsun."
        return 1
    fi

    if ! npm_install_global_with_fallback "@google/gemini-cli" "Gemini CLI"; then
        echo -e "${RED}[HATA]${NC} Gemini CLI npm paketinin kurulumu başarısız oldu."
        return 1
    fi

    if [ -n "${NPM_LAST_INSTALL_PREFIX}" ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} Kurulum prefix'i: ${NPM_LAST_INSTALL_PREFIX}"
    fi

    echo -e "${GREEN}[BAŞARILI]${NC} Gemini CLI sürümü: $(gemini --version)"
    
    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}[BİLGİ]${NC} Şimdi Gemini CLI'ya giriş yapmanız gerekiyor."
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen 'gemini auth' veya ilgili oturum açma komutunu çalıştırın."
        echo -e "${YELLOW}[BİLGİ]${NC} Oturum açma tamamlandığında buraya dönün ve Enter'a basın.\n"
        
        gemini auth </dev/tty >/dev/tty 2>&1 || echo -e "${YELLOW}[BİLGİ]${NC} Manuel oturum açma gerekebilir."
        
        echo -e "\n${YELLOW}[BİLGİ]${NC} Oturum açma işlemi tamamlandı mı? (Enter'a basarak devam edin)"
        read -r -p "Devam etmek için Enter'a basın..." </dev/tty
    else
        echo -e "\n${YELLOW}[BİLGİ]${NC} 'Tümünü Kur' modunda kimlik doğrulama atlandı."
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen daha sonra manuel olarak '${GREEN}gemini auth${NC}' komutunu çalıştırın."
    fi

    echo -e "${GREEN}[BAŞARILI]${NC} Gemini CLI kurulumu tamamlandı!"
}

# Ana kurulum akışı
main() {
    install_gemini_cli "$@"
}

main "$@"
