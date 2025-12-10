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
    echo "[HATA/ERROR] utils.bash yüklenemedi / Unable to load utils.bash (tried $utils_local)" >&2
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
    log_info_detail "$(superclaude_text "install_title")"

    if ! command -v pipx &> /dev/null; then
        log_warn_detail "$(superclaude_text "pipx_required")"
        install_pipx
        if ! command -v pipx &> /dev/null; then
            log_error_detail "$(superclaude_text "pipx_fail")"
            return 1
        fi
    fi

    install_package "SuperClaude" "pipx" "superclaude" "SuperClaude"
    local install_status=$?

    if [ $install_status -ne 0 ]; then
        log_error_detail "$(superclaude_text "install_fail")"
        return 1
    fi

    log_success_detail "$(superclaude_text "install_done")"

    log_info_detail "$(superclaude_text "config_title")"
    log_info_detail "$(superclaude_text "running_install")"
    log_info_detail "$(superclaude_text "api_key_prompt")"

    if attach_tty_and_run superclaude install; then
        log_success_detail "$(superclaude_text "config_done")"
    else
        log_error_detail "$(superclaude_text "config_fail")"
        log_info_detail "$(superclaude_text "manual_config_note")"
    fi

    print_heading_panel "$(superclaude_text "usage_tips_title")"
    log_info_detail "  $(superclaude_text "usage_start")"
    log_info_detail "  $(superclaude_text "usage_update")"
    log_info_detail "  $(superclaude_text "usage_remove")"
    log_info_detail "  $(superclaude_text "usage_reconfig")"
    log_info_detail "  $(superclaude_text "usage_more_info")"
}

# Ana kurulum akışı
main() {
    install_superclaude
}

main
