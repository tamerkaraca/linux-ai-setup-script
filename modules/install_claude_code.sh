#!/bin/bash
set -euo pipefail

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

# Node.js sürümünü kontrol et ve gerekli talimatları göster
ensure_node_version() {
    if command -v node >/dev/null 2>&1; then
        node_major=$(node -v | sed -E 's/^v([0-9]+).*/\1/')
        if [ "${node_major:-0}" -lt 20 ]; then
            echo -e "${YELLOW}[UYARI]${NC} Node.js v20 veya daha yeni bir sürüm gerekli. Mevcut: $(node -v)"
            echo -e "${YELLOW}[BİLGİ]${NC} Önerilen çözüm: nvm kullanarak Node 20+ yükleyin. Örnek:
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
  source ~/.bashrc
  nvm install 20
  nvm use 20
"
            return 1
        fi
    else
        echo -e "${YELLOW}[UYARI]${NC} Node.js yüklü değil. Lütfen Node.js v20+ yükleyin (örn. nvm)."
        return 1
    fi
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
    
    # Hızlı kontrol: Node.js sürümü uygun mu?
    ensure_node_version || return 1

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
