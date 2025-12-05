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

: "${GREEN:=$'\033[0;32m'}"
: "${NC:=$'\033[0m'}"

# --- Start: SuperQwen-specific logic ---

declare -A SUPERQWEN_TEXT_EN=(
    ["install_title"]="Starting SuperQwen Framework (pipx) installation..."
    ["pipx_required"]="Installing Pipx first because SuperQwen requires it..."
    ["pipx_fail"]="Pipx installation failed; SuperQwen cannot proceed."
    ["install_fail"]="SuperQwen (pipx) installation failed!"
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
    ["install_fail"]="SuperQwen (pipx) kurulumu başarısız!"
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

attach_tty_and_run() {
    if [ -e /dev/tty ] && [ -r /dev/tty ]; then
        "$@" </dev/tty
    else
        "$@"
    fi
}

# --- End: SuperQwen-specific logic ---

main() {
    log_info_detail "$(superqwen_text install_title)"
    
    if ! command -v pipx &> /dev/null; then
        log_warn_detail "$(superqwen_text pipx_required)"
        install_pipx
        if ! command -v pipx &> /dev/null; then
            log_error_detail "$(superqwen_text pipx_fail)"
            return 1
        fi
    fi
    
    install_package "SuperQwen" "pipx" "SuperQwen" "SuperQwen"
    local install_status=$?

    if [ $install_status -ne 0 ]; then
        log_error_detail "$(superqwen_text install_fail)"
        return 1
    fi
    
    log_success_detail "$(superqwen_text install_done)"

    log_info_detail "$(superqwen_text config_title)"
    log_info_detail "$(superqwen_text running_install)"
    log_info_detail "$(superqwen_text api_key_prompt)"

    if attach_tty_and_run SuperQwen install; then
        log_success_detail "$(superqwen_text config_done)"
    else
        log_error_detail "$(superqwen_text config_fail)"
        log_info_detail "$(superqwen_text manual_config_note)"
    fi

    log_info_detail "$(superqwen_text usage_tips_title)"
    log_info_detail "  $(superqwen_text usage_start)"
    log_info_detail "  $(superqwen_text usage_update)"
    log_info_detail "  $(superqwen_text usage_remove)"
    log_info_detail "  $(superqwen_text usage_reconfig)"
    log_info_detail "  $(superqwen_text usage_more_info)"
}

main "$@"