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

declare -A SUPERCLAUDE_TEXT_EN=(
    ["install_title"]="Starting SuperClaude Framework (pipx) installation..."
    ["pipx_required"]="Installing pipx because SuperClaude requires it..."
    ["pipx_fail"]="Pipx installation failed; SuperClaude cannot proceed."
    ["installing"]="Downloading and installing SuperClaude via pipx..."
    ["install_fail"]="SuperClaude (pipx) installation failed!"
    ["restart_notice"]="Please restart your terminal and try again."
    ["install_done"]="SuperClaude (pipx) installation completed."
    ["config_title"]="Starting SuperClaude configuration..."
    ["running_install"]="Running 'SuperClaude install'..."
    ["api_key_prompt"]="API keys may be requested; follow the on-screen prompts."
    ["config_done"]="SuperClaude configuration completed!"
    ["config_fail"]="SuperClaude 'install' command failed!"
    ["manual_config_note"]="You can rerun '${GREEN}SuperClaude install${NC}' manually after setting the required API keys."
    ["usage_tips_title"]="SuperClaude Framework Usage Tips:"
    ["usage_start"]="Start: ${GREEN}SuperClaude${NC} (or ${GREEN}sc${NC})"
    ["usage_update"]="Update: ${GREEN}pipx upgrade SuperClaude${NC}"
    ["usage_remove"]="Remove: ${GREEN}pipx uninstall SuperClaude${NC}"
    ["usage_reconfig"]="Reconfigure: ${GREEN}SuperClaude install${NC}"
    ["usage_more_info"]="More info: https://github.com/SuperClaude-Org/SuperClaude_Framework"
    ["api_guide_title"]="API Key Guide:"
    ["api_gemini"]="Gemini API Key: ${CYAN}https://makersuite.google.com/app/apikey${NC}"
    ["api_anthropic"]="Anthropic API Key: ${CYAN}https://console.anthropic.com/${NC}"
    ["api_openai"]="OpenAI API Key: ${CYAN}https://platform.openai.com/api-keys${NC}"
    ["api_install_prompt"]="'SuperClaude install' will prompt you for these keys."
)

declare -A SUPERCLAUDE_TEXT_TR=(
    ["install_title"]="SuperClaude Framework (Pipx) kurulumu başlatılıyor..."
    ["pipx_required"]="SuperClaude için önce Pipx kuruluyor..."
    ["pipx_fail"]="Pipx kurulumu başarısız, SuperClaude kurulamaz."
    ["installing"]="SuperClaude indiriliyor ve kuruluyor (pipx)..."
    ["install_fail"]="SuperClaude (pipx) kurulumu başarısız!"
    ["restart_notice"]="Lütfen terminali yeniden başlatıp tekrar deneyin."
    ["install_done"]="SuperClaude (pipx) kurulumu tamamlandı."
    ["config_title"]="SuperClaude Yapılandırması Başlatılıyor..."
    ["running_install"]="SuperClaude install komutu çalıştırılıyor..."
    ["api_key_prompt"]="Bu aşamada API anahtarlarınız istenebilir. Lütfen ekranı takip edin."
    ["config_done"]="SuperClaude yapılandırması tamamlandı!"
    ["config_fail"]="SuperClaude 'install' komutu başarısız!"
    ["manual_config_note"]="Gerekli API anahtarlarını daha sonra manuel olarak '${GREEN}SuperClaude install${NC}' komutuyla yapılandırabilirsiniz."
    ["usage_tips_title"]="SuperClaude Framework Kullanım İpuçları:"
    ["usage_start"]="Başlatma: ${GREEN}SuperClaude${NC} (veya ${GREEN}sc${NC})"
    ["usage_update"]="Güncelleme: ${GREEN}pipx upgrade SuperClaude${NC}"
    ["usage_remove"]="Kaldırma: ${GREEN}pipx uninstall SuperClaude${NC}"
    ["usage_reconfig"]="Yeniden yapılandırma: ${GREEN}SuperClaude install${NC}"
    ["usage_more_info"]="Daha fazla bilgi: https://github.com/SuperClaude-Org/SuperClaude_Framework"
    ["api_guide_title"]="API Anahtarı Alma Rehberi:"
    ["api_gemini"]="Gemini API Key: ${CYAN}https://makersuite.google.com/app/apikey${NC}"
    ["api_anthropic"]="Anthropic API Key: ${CYAN}https://console.anthropic.com/${NC}"
    ["api_openai"]="OpenAI API Key: ${CYAN}https://platform.openai.com/api-keys${NC}"
    ["api_install_prompt"]="'SuperClaude install' komutu sizden bu anahtarları isteyecektir."
)

superclaude_text() {
    local key="$1"
    local default_value="${SUPERCLAUDE_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${SUPERCLAUDE_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
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
    echo -e "${YELLOW}${INFO_TAG}${NC} $(superclaude_text "install_title")"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    # Following official documentation from https://github.com/SuperClaude-Org/SuperClaude_Framework/blob/master/docs/getting-started/installation.md
    
    # Step 1: Install pipx
    echo -e "\n${CYAN}--- Step 1: Installing/updating pipx...${NC}"
    if ! python3 -m pip install --user --break-system-packages pipx; then
        echo -e "${RED}${ERROR_TAG}${NC} Failed to install pipx using 'python3 -m pip'."
        return 1
    fi

    # Step 2: Ensure pipx path is in system PATH
    echo -e "\n${CYAN}--- Step 2: Ensuring pipx path is configured...${NC}"
    if ! python3 -m pipx ensurepath; then
        echo -e "${YELLOW}${WARN_TAG}${NC} 'pipx ensurepath' command reported an issue. This is often safe to ignore. Continuing..."
    fi

    # Update PATH for the current script session and clear command cache
    export PATH="$HOME/.local/bin:$PATH"
    hash -r 2>/dev/null || true

    # Step 3: Install SuperClaude using pipx
    echo -e "\n${CYAN}--- Step 3: Installing SuperClaude framework...${NC}"
    # Using --force to ensure we either install fresh or overwrite/upgrade an existing installation.
    if ! pipx install SuperClaude --force; then
        echo -e "${RED}${ERROR_TAG}${NC} $(superclaude_text "install_fail")"
        return 1
    fi

    # Clear command cache again after installation
    hash -r 2>/dev/null || true
    
    # Verify installation
    if ! command -v superclaude &> /dev/null; then
        echo -e "${RED}${ERROR_TAG}${NC} SuperClaude command not found after installation."
        echo -e "${YELLOW}${INFO_TAG}${NC} $(superclaude_text "restart_notice")"
        return 1
    fi
    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(superclaude_text "install_done")"

    # Step 4: Run initial setup/configuration for SuperClaude
    echo -e "\n${CYAN}--- Step 4: Running initial SuperClaude configuration...${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(superclaude_text "running_install")"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(superclaude_text "api_key_prompt")${NC}"

    if attach_tty_and_run superclaude install; then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(superclaude_text "config_done")"
    else
        echo -e "${RED}${ERROR_TAG}${NC} $(superclaude_text "config_fail")"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(superclaude_text "manual_config_note")"
    fi

    # Final usage tips
    echo -e "\n${CYAN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}   $(superclaude_text "usage_tips_title")${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "  ${GREEN}•${NC} $(superclaude_text "usage_start")"
    echo -e "  ${GREEN}•${NC} $(superclaude_text "usage_update")"
    echo -e "  ${GREEN}•${NC} $(superclaude_text "usage_remove")"
    echo -e "  ${GREEN}•${NC} $(superclaude_text "usage_reconfig")"
    echo -e "  ${GREEN}•${NC} $(superclaude_text "usage_more_info")"
}

# Ana kurulum akışı
main() {
    install_superclaude
}

main
