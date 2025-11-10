#!/bin/bash

# Ortak yardımcı fonksiyonları yükle


# SuperQwen Framework kurulumu (Pipx ile)
install_superqwen() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} SuperQwen Framework (Pipx) kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    


    if ! command -v pipx &> /dev/null; then
        echo -e "${YELLOW}[UYARI]${NC} SuperQwen için önce Pipx kuruluyor..."
        install_pipx
        if ! command -v pipx &> /dev/null; then
            echo -e "${RED}[HATA]${NC} Pipx kurulumu başarısız, SuperQwen kurulamaz."
            return 1
        fi
    fi
    
    reload_shell_configs
    export PATH="$HOME/.local/bin:$PATH"

    echo -e "${YELLOW}[BİLGİ]${NC} SuperQwen indiriliyor ve kuruluyor (pipx)..."
    pipx install SuperQwen
    
    export PATH="$HOME/.local/bin:$PATH"
    
    if ! command -v SuperQwen &> /dev/null; then
        echo -e "${RED}[HATA]${NC} SuperQwen (pipx) kurulumu başarısız!"
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen terminali yeniden başlatıp tekrar deneyin."
        return 1
    fi
    
    echo -e "${GREEN}[BAŞARILI]${NC} SuperQwen (pipx) kurulumu tamamlandı."

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}   SuperQwen Yapılandırması Başlatılıyor...${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    echo -e "${YELLOW}[BİLGİ]${NC} SuperQwen install komutu çalıştırılıyor..."
    echo -e "${YELLOW}[BİLGİ]${NC} Bu aşamada API anahtarlarınız istenebilir. Lütfen ekranı takip edin.${NC}"

    SuperQwen install
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}[HATA]${NC} SuperQwen 'install' komutu başarısız!"
        echo -e "${YELLOW}[BİLGİ]${NC} Gerekli API anahtarlarını daha sonra manuel olarak '${GREEN}SuperQwen install${NC}' komutuyla yapılandırabilirsiniz."
    else
        echo -e "${GREEN}[BAŞARILI]${NC} SuperQwen yapılandırması tamamlandı!"
    fi

    echo -e "\n${CYAN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}   SuperQwen Framework Kullanım İpuçları:${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "  ${GREEN}•${NC} Başlatma: ${GREEN}SuperQwen${NC} (veya ${GREEN}sq${NC})"
    echo -e "  ${GREEN}•${NC} Güncelleme: ${GREEN}pipx upgrade SuperQwen${NC}"
    echo -e "  ${GREEN}•${NC} Kaldırma: ${GREEN}pipx uninstall SuperQwen${NC}"
    echo -e "  ${GREEN}•${NC} Yeniden yapılandırma: ${GREEN}SuperQwen install${NC}"
    echo -e "  ${GREEN}•${NC} Daha fazla bilgi: https://github.com/SuperClaude-Org/SuperQwen_Framework"
}

# Ana kurulum akışı
main() {
    install_superqwen
}

main
