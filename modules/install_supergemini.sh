#!/bin/bash

# Ortak yardımcı fonksiyonları yükle


# SuperGemini Framework kurulumu (Pipx ile)
install_supergemini() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} SuperGemini Framework (Pipx) kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    

    
    if ! command -v pipx &> /dev/null; then
        echo -e "${YELLOW}[UYARI]${NC} SuperGemini için önce Pipx kuruluyor..."
        install_pipx
        if ! command -v pipx &> /dev/null; then
            echo -e "${RED}[HATA]${NC} Pipx kurulumu başarısız, SuperGemini kurulamaz."
            return 1
        fi
    fi
    
    reload_shell_configs
    export PATH="$HOME/.local/bin:$PATH"

    echo -e "${YELLOW}[BİLGİ]${NC} SuperGemini indiriliyor ve kuruluyor (pipx)..."
    pipx install SuperGemini
    
    export PATH="$HOME/.local/bin:$PATH"
    
    if ! command -v SuperGemini &> /dev/null; then
        echo -e "${RED}[HATA]${NC} SuperGemini (pipx) kurulumu başarısız!"
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen terminali yeniden başlatıp tekrar deneyin."
        return 1
    fi
    
    echo -e "${GREEN}[BAŞARILI]${NC} SuperGemini (pipx) kurulumu tamamlandı."

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}   SuperGemini Yapılandırma Profili Seçin:${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "  ${GREEN}1${NC} - Express (Önerilen, hızlı kurulum)"
    echo -e "  ${GREEN}2${NC} - Minimal (Sadece çekirdek, en hızlı)"
    echo -e "  ${GREEN}3${NC} - Full (Tüm özellikler)"
    read -r -p "Seçiminiz (1/2/3) [Varsayılan: 1]: " setup_choice </dev/tty
    
    SETUP_CMD=""
    case $setup_choice in
        2)
            echo -e "${YELLOW}[BİLGİ]${NC} Minimal profil ile kurulum yapılıyor..."
            SETUP_CMD="SuperGemini install --profile minimal --yes"
            ;; 
        3)
            echo -e "${YELLOW}[BİLGİ]${NC} Full profil ile kurulum yapılıyor..."
            SETUP_CMD="SuperGemini install --profile full --yes"
            ;; 
        *)
            echo -e "${YELLOW}[BİLGİ]${NC} Express (önerilen) profil ile kurulum yapılıyor..."
            SETUP_CMD="SuperGemini install --yes"
            ;; 
    esac
    
    echo -e "${YELLOW}[BİLGİ]${NC} $SETUP_CMD komutu çalıştırılıyor..."
    echo -e "${YELLOW}[BİLGİ]${NC} Bu aşamada API anahtarlarınız istenebilir. Lütfen ekranı takip edin.${NC}"
    
    if [ "$setup_choice" = "2" ]; then
        SuperGemini install --profile minimal --yes
    elif [ "$setup_choice" = "3" ]; then
        SuperGemini install --profile full --yes
    else
        SuperGemini install --yes
    fi
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}[HATA]${NC} SuperGemini 'install' komutu başarısız!"
        echo -e "${YELLOW}[BİLGİ]${NC} Gerekli API anahtarlarını daha sonra manuel olarak '${GREEN}SuperGemini install${NC}' komutuyla yapılandırabilirsiniz."
    else
        echo -e "${GREEN}[BAŞARILI]${NC} SuperGemini yapılandırması tamamlandı!"
    fi

    echo -e "\n${CYAN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}   SuperGemini Framework Kullanım İpuçları:${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "  ${GREEN}•${NC} Başlatma: ${GREEN}SuperGemini${NC} (veya ${GREEN}sg${NC})"
    echo -e "  ${GREEN}•${NC} Güncelleme: ${GREEN}pipx upgrade SuperGemini${NC}"
    echo -e "  ${GREEN}•${NC} Kaldırma: ${GREEN}pipx uninstall SuperGemini${NC}"
    echo -e "  ${GREEN}•${NC} Yeniden yapılandırma: ${GREEN}SuperGemini install${NC}"
    echo -e "  ${GREEN}•${NC} Daha fazla bilgi: https://github.com/SuperClaude-Org/SuperGemini"
    
    echo -e "\n${YELLOW}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}   API Anahtarı Alma Rehberi:${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}1.${NC} Gemini API Key: ${CYAN}https://makersuite.google.com/app/apikey${NC}"
    echo -e "${GREEN}2.${NC} Anthropic API Key: ${CYAN}https://console.anthropic.com/${NC}"
    echo -e "${GREEN}3.${NC} OpenAI API Key: ${CYAN}https://platform.openai.com/api-keys${NC}"
    echo -e "\n${YELLOW}[BİLGİ]${NC} 'SuperGemini install' komutu sizden bu anahtarları isteyecektir."
}

# Ana kurulum akışı
main() {
    install_supergemini
}

main
