#!/bin/bash

# Ortak yardımcı fonksiyonları yükle


# SuperQwen Framework kurulumu (Pipx ile)
attach_tty_and_run() {
    if [ -e /dev/tty ] && [ -r /dev/tty ]; then
        "$@" </dev/tty
    else
        "$@"
    fi
}

install_superqwen() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} SuperQwen Framework (Pipx) kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    if ! command -v pipx &> /dev/null; then
        echo -e "${YELLOW}${WARN_TAG}${NC} SuperQwen için önce Pipx kuruluyor..."
        install_pipx
        if ! command -v pipx &> /dev/null; then
            echo -e "${RED}${ERROR_TAG}${NC} Pipx kurulumu başarısız, SuperQwen kurulamaz."
            return 1
        fi
    fi
    
    reload_shell_configs
    export PATH="$HOME/.local/bin:$PATH"

    echo -e "${YELLOW}${INFO_TAG}${NC} SuperQwen indiriliyor ve kuruluyor (pipx)..."
    pipx install SuperQwen
    
    export PATH="$HOME/.local/bin:$PATH"
    
    if ! command -v SuperQwen &> /dev/null; then
        echo -e "${RED}${ERROR_TAG}${NC} SuperQwen (pipx) kurulumu başarısız!"
        echo -e "${YELLOW}${INFO_TAG}${NC} Lütfen terminali yeniden başlatıp tekrar deneyin."
        return 1
    fi
    
    echo -e "${GREEN}${SUCCESS_TAG}${NC} SuperQwen (pipx) kurulumu tamamlandı."

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}   SuperQwen Yapılandırması Başlatılıyor...${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    echo -e "${YELLOW}${INFO_TAG}${NC} SuperQwen install komutu çalıştırılıyor..."
    echo -e "${YELLOW}${INFO_TAG}${NC} Bu aşamada API anahtarlarınız istenebilir. Lütfen ekranı takip edin.${NC}"

    if attach_tty_and_run SuperQwen install; then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} SuperQwen yapılandırması tamamlandı!"
    else
        echo -e "${RED}${ERROR_TAG}${NC} SuperQwen 'install' komutu başarısız!"
        echo -e "${YELLOW}${INFO_TAG}${NC} Gerekli API anahtarlarını daha sonra manuel olarak '${GREEN}SuperQwen install${NC}' komutuyla yapılandırabilirsiniz."
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
