#!/bin/bash

# Ortak yardımcı fonksiyonları yükle
# shellcheck source=/dev/null
source "./modules/utils.sh"

# Qwen CLI kurulumu
install_qwen_cli() {
    local interactive_mode=${1:-true}
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Qwen CLI kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    detect_package_manager # Ensure PKG_MANAGER, INSTALL_CMD are set

    npm install -g @qwen-code/qwen-code@latest
    
    echo -e "${GREEN}[BAŞARILI]${NC} Qwen CLI sürümü: $(qwen --version)"
    
    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}[BİLGİ]${NC} Şimdi Qwen CLI'ya giriş yapmanız gerekiyor."
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen 'qwen login' veya ilgili oturum açma komutunu çalıştırın."
        echo -e "${YELLOW}[BİLGİ]${NC} Oturum açma tamamlandığında buraya dönün ve Enter'a basın.\n"
        
        qwen login 2>/dev/null || echo -e "${YELLOW}[BİLGİ]${NC} Manuel oturum açma gerekebilir."
        
        read -r -p "Devam etmek için Enter'a basın..."
    else
        echo -e "\n${YELLOW}[BİLGİ]${NC} 'Tümünü Kur' modunda kimlik doğrulama atlandı."
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen daha sonra manuel olarak '${GREEN}qwen login${NC}' komutunu çalıştırın."
    fi
    
    echo -e "${GREEN}[BAŞARILI]${NC} Qwen CLI kurulumu tamamlandı!"
}

# Ana kurulum akışı
main() {
    install_qwen_cli "$@"
}

main
