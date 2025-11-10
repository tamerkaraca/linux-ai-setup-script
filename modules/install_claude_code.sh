#!/bin/bash

# Ortak yardımcı fonksiyonları yükle
# shellcheck source=/dev/null
source "./modules/utils.sh"

# Claude Code kurulumu
install_claude_code() {
    local interactive_mode=${1:-true}
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Claude Code kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    detect_package_manager # Ensure PKG_MANAGER, INSTALL_CMD are set

    npm install -g @anthropic-ai/claude-code
    
    echo -e "${GREEN}[BAŞARILI]${NC} Claude Code sürümü: $(claude --version)"
    
    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}[BİLGİ]${NC} Şimdi Claude Code'a giriş yapmanız gerekiyor."
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen 'claude login' komutunu çalıştırın ve oturum açın."
        echo -e "${YELLOW}[BİLGİ]${NC} Oturum açma tamamlandığında buraya dönün ve Enter'a basın.\n"
        
                claude login
        
                echo -e "\n${YELLOW}[BİLGİ]${NC} Oturum açma işlemi tamamlandı mı? (Enter'a basarak devam edin)"
                read -r -p "Devam etmek için Enter'a basın..."    else
        echo -e "\n${YELLOW}[BİLGİ]${NC} 'Tümünü Kur' modunda kimlik doğrulama atlandı."
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen daha sonra manuel olarak '${GREEN}claude login${NC}' komutunu çalıştırın."
    fi
    
    echo -e "${GREEN}[BAŞARILI]${NC} Claude Code kurulumu tamamlandı!"
}

# Ana kurulum akışı
main() {
    install_claude_code "$@"
}

main
