#!/bin/bash

# Ortak yardımcı fonksiyonları yükle


translate_sc() {
    local en="$1"
    local tr="$2"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "$tr"
    else
        printf "%s" "$en"
    fi
}

# SuperClaude Framework kurulumu (Pipx ile)
attach_tty_and_run() {
    if [ -e /dev/tty ] && [ -r /dev/tty ]; then
        "$@" </dev/tty
    else
        "$@"
    fi
}

install_superclaude() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(translate_sc "Starting SuperClaude Framework (pipx) installation..." "SuperClaude Framework (Pipx) kurulumu başlatılıyor...")"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    if ! command -v pipx &> /dev/null; then
        echo -e "${YELLOW}${WARN_TAG}${NC} $(translate_sc "Installing pipx because SuperClaude requires it..." "SuperClaude için önce Pipx kuruluyor...")"
        install_pipx
        if ! command -v pipx &> /dev/null; then
            echo -e "${RED}${ERROR_TAG}${NC} $(translate_sc "Pipx installation failed; SuperClaude cannot proceed." "Pipx kurulumu başarısız, SuperClaude kurulamaz.")"
            return 1
        fi
    fi
    
    reload_shell_configs
    export PATH="$HOME/.local/bin:$PATH"

    echo -e "${YELLOW}${INFO_TAG}${NC} $(translate_sc "Downloading and installing SuperClaude via pipx..." "SuperClaude indiriliyor ve kuruluyor (pipx)...")"
    pipx install SuperClaude
    
    export PATH="$HOME/.local/bin:$PATH"
    
    if ! command -v SuperClaude &> /dev/null; then
        echo -e "${RED}${ERROR_TAG}${NC} $(translate_sc "SuperClaude (pipx) installation failed!" "SuperClaude (pipx) kurulumu başarısız!")"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(translate_sc "Please restart your terminal and try again." "Lütfen terminali yeniden başlatıp tekrar deneyin.")"
        return 1
    fi
    
    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(translate_sc "SuperClaude (pipx) installation completed." "SuperClaude (pipx) kurulumu tamamlandı.")"

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}   $(translate_sc "Starting SuperClaude configuration..." "SuperClaude Yapılandırması Başlatılıyor...")${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    echo -e "${YELLOW}${INFO_TAG}${NC} $(translate_sc "Running 'SuperClaude install'..." "SuperClaude install komutu çalıştırılıyor...")"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(translate_sc "API keys may be requested; follow the on-screen prompts." "Bu aşamada API anahtarlarınız istenebilir. Lütfen ekranı takip edin.")${NC}"

    if attach_tty_and_run SuperClaude install; then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(translate_sc "SuperClaude configuration completed!" "SuperClaude yapılandırması tamamlandı!")"
    else
        echo -e "${RED}${ERROR_TAG}${NC} $(translate_sc "SuperClaude 'install' command failed!" "SuperClaude 'install' komutu başarısız!")"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(translate_sc "You can rerun '${GREEN}SuperClaude install${NC}' manually after setting the required API keys." "Gerekli API anahtarlarını daha sonra manuel olarak '${GREEN}SuperClaude install${NC}' komutuyla yapılandırabilirsiniz.")"
    fi

    echo -e "\n${CYAN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}   $(translate_sc "SuperClaude Framework Usage Tips:" "SuperClaude Framework Kullanım İpuçları:")${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "  ${GREEN}•${NC} $(translate_sc "Start: ${GREEN}SuperClaude${NC} (or ${GREEN}sc${NC})" "Başlatma: ${GREEN}SuperClaude${NC} (veya ${GREEN}sc${NC})")"
    echo -e "  ${GREEN}•${NC} $(translate_sc "Update: ${GREEN}pipx upgrade SuperClaude${NC}" "Güncelleme: ${GREEN}pipx upgrade SuperClaude${NC}")"
    echo -e "  ${GREEN}•${NC} $(translate_sc "Remove: ${GREEN}pipx uninstall SuperClaude${NC}" "Kaldırma: ${GREEN}pipx uninstall SuperClaude${NC}")"
    echo -e "  ${GREEN}•${NC} $(translate_sc "Reconfigure: ${GREEN}SuperClaude install${NC}" "Yeniden yapılandırma: ${GREEN}SuperClaude install${NC}")"
    echo -e "  ${GREEN}•${NC} $(translate_sc "More info: https://github.com/SuperClaude-Org/SuperClaude_Framework" "Daha fazla bilgi: https://github.com/SuperClaude-Org/SuperClaude_Framework")"

    echo -e "\n${YELLOW}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}   $(translate_sc "API Key Guide:" "API Anahtarı Alma Rehberi:")${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}1.${NC} $(translate_sc "Gemini API Key: ${CYAN}https://makersuite.google.com/app/apikey${NC}" "Gemini API Key: ${CYAN}https://makersuite.google.com/app/apikey${NC}")"
    echo -e "${GREEN}2.${NC} $(translate_sc "Anthropic API Key: ${CYAN}https://console.anthropic.com/${NC}" "Anthropic API Key: ${CYAN}https://console.anthropic.com/${NC}")"
    echo -e "${GREEN}3.${NC} $(translate_sc "OpenAI API Key: ${CYAN}https://platform.openai.com/api-keys${NC}" "OpenAI API Key: ${CYAN}https://platform.openai.com/api-keys${NC}")"
    echo -e "\n${YELLOW}${INFO_TAG}${NC} $(translate_sc "'SuperClaude install' will prompt you for these keys." "'SuperClaude install' komutu sizden bu anahtarları isteyecektir.")"
}

# Ana kurulum akışı
main() {
    install_superclaude
}

main
