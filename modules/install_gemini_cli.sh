#!/bin/bash

# Ortak yardımcı fonksiyonları yükle


# Gemini CLI kurulumu
install_gemini_cli() {
    local interactive_mode=${1:-true}
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Gemini CLI kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    # Node.js sürümünü kontrol et; Gemini CLI ve bağımlılıkları genellikle Node >=20 gerektirir
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

    ensure_node_version || return 1

    npm install -g @google/gemini-cli
    
    echo -e "${GREEN}[BAŞARILI]${NC} Gemini CLI sürümü: $(gemini --version)"
    
    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}[BİLGİ]${NC} Şimdi Gemini CLI'ya giriş yapmanız gerekiyor."
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen 'gemini auth' veya ilgili oturum açma komutunu çalıştırın."
        echo -e "${YELLOW}[BİLGİ]${NC} Oturum açma tamamlandığında buraya dönün ve Enter'a basın.\n"
        
        gemini auth 2>/dev/null || echo -e "${YELLOW}[BİLGİ]${NC} Manuel oturum açma gerekebilir."
        
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

main
