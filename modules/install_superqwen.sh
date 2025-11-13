#!/bin/bash
set -euo pipefail

# Ortak yardımcı fonksiyonları yükle
UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

declare -A SUPERQWEN_TEXT_EN=(
    ["install_title"]="Starting SuperQwen Framework (pipx) installation..."
    ["pipx_required"]="Installing pipx first because SuperQwen requires it..."
    ["pipx_fail"]="Pipx installation failed; SuperQwen cannot proceed."
    ["installing"]="Downloading and installing SuperQwen via pipx..."
    ["install_fail"]="SuperQwen (pipx) installation failed!"
    ["restart_notice"]="Please restart your terminal and try again."
    ["install_done"]="SuperQwen (pipx) installation completed."
    ["config_title"]="Starting SuperQwen configuration..."
    ["running_install"]="Running 'SuperQwen install'..."
    ["api_key_prompt"]="API keys may be requested; follow the on-screen prompts."
    ["config_done"]="SuperQwen configuration completed!"
    ["config_fail"]="SuperQwen 'install' command failed!"
    ["manual_config_note"]="You can rerun '${GREEN}SuperQwen install${NC}' manually after setting the required API keys."
    ["usage_tips_title"]="SuperQwen Framework Usage Tips:"
    ["usage_start"]="Start: ${GREEN}SuperQwen${NC} (or ${GREEN}sq${NC})"
    ["usage_update"]="Update: ${GREEN}pipx upgrade SuperQwen${NC}"
    ["usage_remove"]="Remove: ${GREEN}pipx uninstall SuperQwen${NC}"
    ["usage_reconfig"]="Reconfigure: ${GREEN}SuperQwen install${NC}"
    ["usage_more_info"]="More info: https://github.com/SuperClaude-Org/SuperQwen_Framework"
)

declare -A SUPERQWEN_TEXT_TR=(
    ["install_title"]="SuperQwen Framework (Pipx) kurulumu başlatılıyor..."
    ["pipx_required"]="SuperQwen için önce Pipx kuruluyor..."
    ["pipx_fail"]="Pipx kurulumu başarısız, SuperQwen kurulamaz."
    ["installing"]="SuperQwen indiriliyor ve kuruluyor (pipx)..."
    ["install_fail"]="SuperQwen (pipx) kurulumu başarısız!"
    ["restart_notice"]="Lütfen terminali yeniden başlatıp tekrar deneyin."
    ["install_done"]="SuperQwen (pipx) kurulumu tamamlandı."
    ["config_title"]="SuperQwen Yapılandırması Başlatılıyor..."
    ["running_install"]="SuperQwen install komutu çalıştırılıyor..."
    ["api_key_prompt"]="Bu aşamada API anahtarlarınız istenebilir. Lütfen ekranı takip edin."
    ["config_done"]="SuperQwen yapılandırması tamamlandı!"
    ["config_fail"]="SuperQwen 'install' komutu başarısız!"
    ["manual_config_note"]="Gerekli API anahtarlarını daha sonra manuel olarak '${GREEN}SuperQwen install${NC}' komutuyla yapılandırabilirsiniz."
    ["usage_tips_title"]="SuperQwen Framework Kullanım İpuçları:"
    ["usage_start"]="Başlatma: ${GREEN}SuperQwen${NC} (veya ${GREEN}sq${NC})"
    ["usage_update"]="Güncelleme: ${GREEN}pipx upgrade SuperQwen${NC}"
    ["usage_remove"]="Kaldırma: ${GREEN}pipx uninstall SuperQwen${NC}"
    ["usage_reconfig"]="Yeniden yapılandırma: ${GREEN}SuperQwen install${NC}"
    ["usage_more_info"]="Daha fazla bilgi: https://github.com/SuperClaude-Org/SuperQwen_Framework"
)

superqwen_text() {
    local key="$1"
    local default_value="${SUPERQWEN_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${SUPERQWEN_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

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
    echo -e "${YELLOW}${INFO_TAG}${NC} $(superqwen_text install_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    if ! command -v pipx &> /dev/null; then
        echo -e "${YELLOW}${WARN_TAG}${NC} $(superqwen_text pipx_required)"
        install_pipx
        if ! command -v pipx &> /dev/null; then
            echo -e "${RED}${ERROR_TAG}${NC} $(superqwen_text pipx_fail)"
            return 1
        fi
    fi
    
    reload_shell_configs
    export PATH="$HOME/.local/bin:$PATH"

    echo -e "${YELLOW}${INFO_TAG}${NC} $(superqwen_text installing)"
    pipx install SuperQwen
    
    export PATH="$HOME/.local/bin:$PATH"
    
    if ! command -v SuperQwen &> /dev/null; then
        echo -e "${RED}${ERROR_TAG}${NC} $(superqwen_text install_fail)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(superqwen_text restart_notice)"
        return 1
    fi
    
    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(superqwen_text install_done)"

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}   $(superqwen_text config_title)${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    echo -e "${YELLOW}${INFO_TAG}${NC} $(superqwen_text running_install)"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(superqwen_text api_key_prompt)${NC}"

    if attach_tty_and_run SuperQwen install; then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(superqwen_text config_done)"
    else
        echo -e "${RED}${ERROR_TAG}${NC} $(superqwen_text config_fail)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(superqwen_text manual_config_note)"
    fi

    echo -e "\n${CYAN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}   $(superqwen_text usage_tips_title)${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "  ${GREEN}•${NC} $(superqwen_text usage_start)"
    echo -e "  ${GREEN}•${NC} $(superqwen_text usage_update)"
    echo -e "  ${GREEN}•${NC} $(superqwen_text usage_remove)"
    echo -e "  ${GREEN}•${NC} $(superqwen_text usage_reconfig)"
    echo -e "  ${GREEN}•${NC} $(superqwen_text usage_more_info)"
}

# Ana kurulum akışı
main() {
    install_superqwen
}

main
