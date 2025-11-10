#!/bin/bash

# Ortak yardımcı fonksiyonları yükle
# shellcheck source=/dev/null
source "./modules/utils.sh"

# SuperClaude Framework kurulumu (Pipx ile)
install_superclaude() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} SuperClaude Framework (Pipx) kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    detect_package_manager # Ensure PKG_MANAGER, INSTALL_CMD are set

    if ! command -v pipx &> /dev/null; then
        echo -e "${YELLOW}[UYARI]${NC} SuperClaude için önce Pipx kuruluyor..."
        install_pipx
        if ! command -v pipx &> /dev/null; then
            echo -e "${RED}[HATA]${NC} Pipx kurulumu başarısız, SuperClaude kurulamaz."
            return 1
        fi
    fi
    
    reload_shell_configs
    export PATH="$HOME/.local/bin:$PATH"

    echo -e "${YELLOW}[BİLGİ]${NC} SuperClaude indiriliyor ve kuruluyor (pipx)..."
    pipx install SuperClaude
    
    export PATH="$HOME/.local/bin:$PATH"
    
    if ! command -v SuperClaude &> /dev/null; then
        echo -e "${RED}[HATA]${NC} SuperClaude (pipx) kurulumu başarısız!"
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen terminali yeniden başlatıp tekrar deneyin."
        return 1
    fi
    
    echo -e "${GREEN}[BAŞARILI]${NC} SuperClaude (pipx) kurulumu tamamlandı."

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}   SuperClaude Yapılandırması Başlatılıyor...${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    echo -e "${YELLOW}[BİLGİ]${NC} SuperClaude install komutu çalıştırılıyor..."
    echo -e "${YELLOW}[BİLGİ]${NC} Bu aşamada API anahtarlarınız istenebilir. Lütfen ekranı takip edin.${NC}"

    SuperClaude install
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}[HATA]${NC} SuperClaude 'install' komutu başarısız!"
        echo -e "${YELLOW}[BİLGİ]${NC} Gerekli API anahtarlarını daha sonra manuel olarak '${GREEN}SuperClaude install${NC}' komutuyla yapılandırabilirsiniz."
    else
        echo -e "${GREEN}[BAŞARILI]${NC} SuperClaude yapılandırması tamamlandı!"
    fi

    echo -e "\n${CYAN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}   SuperClaude Framework Kullanım İpuçları:${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "  ${GREEN}•${NC} Başlatma: ${GREEN}SuperClaude${NC} (veya ${GREEN}sc${NC})"
    echo -e "  ${GREEN}•${NC} Güncelleme: ${GREEN}pipx upgrade SuperClaude${NC}"
    echo -e "  ${GREEN}•${NC} Kaldırma: ${GREEN}pipx uninstall SuperClaude${NC}"
    echo -e "  ${GREEN}•${NC} Yeniden yapılandırma: ${GREEN}SuperClaude install${NC}"
    echo -e "  ${GREEN}•${NC} Daha fazla bilgi: https://github.com/SuperClaude-Org/SuperClaude_Framework"
}

# Ana kurulum akışı
main() {
    install_superclaude
}

main
