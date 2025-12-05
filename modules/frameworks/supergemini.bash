#!/bin/bash
set -euo pipefail

# Resolve the directory this script lives in so sources work regardless of CWD
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$script_dir/../utils/utils.bash"
platform_local="$script_dir/../utils/platform_detection.bash"

# Prefer local direct source (relative to this file). If not available, fall back to
# the setup-provided `source_module` helper when running under the main `setup` script.
if [ -f "$utils_local" ]; then
    # shellcheck source=/dev/null
    source "$utils_local"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/utils.bash" "modules/utils/utils.bash"
else
    echo "[ERROR] Unable to load utils.bash (tried $utils_local)" >&2
    exit 1
fi

if [ -f "$platform_local" ]; then
    # shellcheck source=/dev/null
    source "$platform_local"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/platform_detection.bash" "modules/utils/platform_detection.bash"
fi

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

declare -A SUPERGEMINI_TEXT_EN=(
    ["install_title"]="Starting SuperGemini Framework (pipx) installation..."
    ["pipx_required"]="Installing Pipx first because SuperGemini requires it..."
    ["pipx_fail"]="Pipx installation failed; SuperGemini cannot continue."
    ["installing"]="Downloading and installing SuperGemini via pipx..."
    ["install_fail"]="SuperGemini (pipx) installation failed!"
    ["restart_notice"]="Please restart your terminal and try again."
    ["install_done"]="SuperGemini (pipx) installation completed."
    ["profile_select_title"]="Select a SuperGemini configuration profile:"
    ["profile_express"]="Express (Recommended, guided install)"
    ["profile_minimal"]="Minimal (Core only, fastest)"
    ["profile_full"]="Full (Everything enabled)"
    ["profile_choice_prompt"]="Your choice (1/2/3) [Default: 1]: "
    ["profile_minimal_selected"]="Continuing with the Minimal profile..."
    ["profile_full_selected"]="Continuing with the Full profile..."
    ["profile_express_selected"]="Continuing with the Express (recommended) profile..."
    ["running_command"]="Running command: %s"
    ["api_key_prompt"]="API keys may be requested during this phase. Follow the on-screen prompts."
    ["config_fail"]="The 'SuperGemini install' command failed!"
    ["manual_config_note"]="You can rerun '${GREEN}SuperGemini install${NC}' later to supply API keys manually."
    ["config_done"]="SuperGemini configuration completed!"
    ["usage_tips_title"]="SuperGemini Framework usage tips:"
    ["usage_start"]="Start: ${GREEN}SuperGemini${NC} (or ${GREEN}sg${NC})"
    ["usage_update"]="Update: ${GREEN}pipx upgrade SuperGemini${NC}"
    ["usage_remove"]="Remove: ${GREEN}pipx uninstall SuperGemini${NC}"
    ["usage_reconfig"]="Reconfigure: ${GREEN}SuperGemini install${NC}"
    ["usage_more_info"]="More info: https://github.com/SuperClaude-Org/SuperGemini"
    ["api_guide_title"]="API key quick guide:"
    ["api_gemini"]="Gemini API Key: ${CYAN}https://makersuite.google.com/app/apikey${NC}"
    ["api_anthropic"]="Anthropic API Key: ${CYAN}https://console.anthropic.com/${NC}"
    ["api_openai"]="OpenAI API Key: ${CYAN}https://platform.openai.com/api-keys${NC}"
    ["api_install_prompt"]="'SuperGemini install' will prompt for these keys."
)

declare -A SUPERGEMINI_TEXT_TR=(
    ["install_title"]="SuperGemini Framework (Pipx) kurulumu başlatılıyor..."
    ["pipx_required"]="SuperGemini için önce Pipx kuruluyor..."
    ["pipx_fail"]="Pipx kurulumu başarısız, SuperGemini kurulamaz."
    ["installing"]="SuperGemini indiriliyor ve kuruluyor (pipx)..."
    ["install_fail"]="SuperGemini (pipx) kurulumu başarısız!"
    ["restart_notice"]="Lütfen terminali yeniden başlatıp tekrar deneyin."
    ["install_done"]="SuperGemini (pipx) kurulumu tamamlandı."
    ["profile_select_title"]="SuperGemini Yapılandırma Profili Seçin:"
    ["profile_express"]="Express (Önerilen, hızlı kurulum)"
    ["profile_minimal"]="Minimal (Sadece çekirdek, en hızlı)"
    ["profile_full"]="Full (Tüm özellikler)"
    ["profile_choice_prompt"]="Seçiminiz (1/2/3) [Varsayılan: 1]: "
    ["profile_minimal_selected"]="Minimal profil ile kurulum yapılıyor..."
    ["profile_full_selected"]="Full profil ile kurulum yapılıyor..."
    ["profile_express_selected"]="Express (önerilen) profil ile kurulum yapılıyor..."
    ["running_command"]="Komut çalıştırılıyor: %s"
    ["api_key_prompt"]="Bu aşamada API anahtarlarınız istenebilir. Lütfen ekranı takip edin."
    ["config_fail"]="SuperGemini 'install' komutu başarısız!"
    ["manual_config_note"]="Gerekli API anahtarlarını daha sonra manuel olarak '${GREEN}SuperGemini install${NC}' komutuyla yapılandırabilirsiniz."
    ["config_done"]="SuperGemini yapılandırması tamamlandı!"
    ["usage_tips_title"]="SuperGemini Framework Kullanım İpuçları:"
    ["usage_start"]="Başlatma: ${GREEN}SuperGemini${NC} (veya ${GREEN}sg${NC})"
    ["usage_update"]="Güncelleme: ${GREEN}pipx upgrade SuperGemini${NC}"
    ["usage_remove"]="Kaldırma: ${GREEN}pipx uninstall SuperGemini${NC}"
    ["usage_reconfig"]="Yeniden yapılandırma: ${GREEN}SuperGemini install${NC}"
    ["usage_more_info"]="Daha fazla bilgi: https://github.com/SuperClaude-Org/SuperGemini"
    ["api_guide_title"]="API Anahtarı Alma Rehberi:"
    ["api_gemini"]="Gemini API Key: ${CYAN}https://makersuite.google.com/app/apikey${NC}"
    ["api_anthropic"]="Anthropic API Key: ${CYAN}https://console.anthropic.com/${NC}"
    ["api_openai"]="OpenAI API Key: ${CYAN}https://platform.openai.com/api-keys${NC}"
    ["api_install_prompt"]="'SuperGemini install' komutu sizden bu anahtarları isteyecektir."
)

supergemini_text() {
    local key="$1"
    local default_value="${SUPERGEMINI_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${SUPERGEMINI_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

# SuperGemini Framework kurulumu (Pipx ile)
install_supergemini() {
    log_info_detail "$(supergemini_text "install_title")"
    
    if ! command -v pipx &> /dev/null; then
        log_warn_detail "$(supergemini_text "pipx_required")"
        install_pipx
        if ! command -v pipx &> /dev/null; then
            log_error_detail "$(supergemini_text "pipx_fail")"
            return 1
        fi
    fi
    
    install_package "SuperGemini" "pipx" "SuperGemini" "SuperGemini"
    local install_status=$?

    if [ $install_status -ne 0 ]; then
        log_error_detail "$(supergemini_text "install_fail")"
        log_info_detail "$(supergemini_text "restart_notice")"
        return 1
    fi
    
    log_success_detail "$(supergemini_text "install_done")"

    print_heading_panel "$(supergemini_text "profile_select_title")"
    log_info_detail "  1 - $(supergemini_text "profile_express")"
    log_info_detail "  2 - $(supergemini_text "profile_minimal")"
    log_info_detail "  3 - $(supergemini_text "profile_full")"
    read -r -p "$(supergemini_text "profile_choice_prompt")" setup_choice </dev/tty
    
    SETUP_CMD=""
    case $setup_choice in
        2)
            log_info_detail "$(supergemini_text "profile_minimal_selected")"
            SETUP_CMD="SuperGemini install --profile minimal --yes"
            ;; 
        3)
            log_info_detail "$(supergemini_text "profile_full_selected")"
            SETUP_CMD="SuperGemini install --profile full --yes"
            ;; 
        *)
            log_info_detail "$(supergemini_text "profile_express_selected")"
            SETUP_CMD="SuperGemini install --yes"
            ;; 
    esac
    
    log_info_detail "$(supergemini_text "running_command" "$SETUP_CMD")"
    log_info_detail "$(supergemini_text "api_key_prompt")"
    
    local install_success="true"
    if [ "$setup_choice" = "2" ]; then
        if ! SuperGemini install --profile minimal --yes; then
            install_success="false"
        fi
    elif [ "$setup_choice" = "3" ]; then
        if ! SuperGemini install --profile full --yes; then
            install_success="false"
        fi
    else
        if ! SuperGemini install --yes; then
            install_success="false"
        fi
    fi
    
    if [ "$install_success" != "true" ]; then
        log_error_detail "$(supergemini_text "config_fail")"
        log_info_detail "$(supergemini_text "manual_config_note")"
    else
        log_success_detail "$(supergemini_text "config_done")"
    fi

    print_heading_panel "$(supergemini_text "usage_tips_title")"
    log_info_detail "  • $(supergemini_text "usage_start")"
    log_info_detail "  • $(supergemini_text "usage_update")"
    log_info_detail "  • $(supergemini_text "usage_remove")"
    log_info_detail "  • $(supergemini_text "usage_reconfig")"
    log_info_detail "  • $(supergemini_text "usage_more_info")"
    
    print_heading_panel "$(supergemini_text "api_guide_title")"
    log_info_detail "1. $(supergemini_text "api_gemini")"
    log_info_detail "2. $(supergemini_text "api_anthropic")"
    log_info_detail "3. $(supergemini_text "api_openai")"
    log_info_detail "$(supergemini_text "api_install_prompt")"
}

# Ana kurulum akışı
main() {
    install_supergemini
}

main
