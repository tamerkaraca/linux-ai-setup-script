#!/bin/bash
set -euo pipefail

# Bu modül, Claude Code CLI'ı kurar ve etkileşimli oturum açma için TTY erişimini doğrular.

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
        echo -e "${YELLOW}[UYARI]${NC} Geçerli oturumda TTY bulunamadı; 'claude login' CLI içinde çalıştırılamıyor."
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen kurulumdan sonra manuel olarak 'claude login' komutunu çalıştırın."
        return 0
    fi

    # CLI'nin ham moda geçebilmesi için giriş/çıkışı doğrudan terminale yönlendir
    if ! claude login </dev/tty >/dev/tty 2>&1; then
        echo -e "${RED}[HATA]${NC} 'claude login' çalıştırılırken bir hata oluştu."
        echo -e "${YELLOW}[BİLGİ]${NC} Yukarıdaki hata, Ink tabanlı arayüzlerin ham moda ihtiyaç duymasından kaynaklanabilir."
        echo -e "${YELLOW}[İPUCU]${NC} Terminalinizde doğrudan 'claude login' komutunu çalıştırarak tekrar deneyin."
        return 1
    fi
}

# Claude Code kurulumu
install_claude_code() {
    local interactive_mode=${1:-true}
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Claude Code kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    npm install -g @anthropic-ai/claude-code
    
    echo -e "${GREEN}[BAŞARILI]${NC} Claude Code sürümü: $(claude --version)"
    
    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}[BİLGİ]${NC} Şimdi Claude Code'a giriş yapmanız gerekiyor."
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen 'claude login' komutunu çalıştırın ve oturum açın."
        echo -e "${YELLOW}[BİLGİ]${NC} Oturum açma tamamlandığında buraya dönün ve Enter'a basın.\n"

        run_claude_login || true

        echo -e "\n${YELLOW}[BİLGİ]${NC} Oturum açma işlemi tamamlandı mı? (Enter'a basarak devam edin)"
        read -r -p "Devam etmek için Enter'a basın..." </dev/tty
    else
        echo -e "\n${YELLOW}[BİLGİ]${NC} 'Tümünü Kur' modunda kimlik doğrulama atlandı."
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen daha sonra manuel olarak '${GREEN}claude login${NC}' komutunu çalıştırın."
    fi
    
    echo -e "${GREEN}[BAŞARILI]${NC} Claude Code kurulumu tamamlandı!"
}

# Ana kurulum akışı
main() {
    install_claude_code "$@"
}

main "$@"
