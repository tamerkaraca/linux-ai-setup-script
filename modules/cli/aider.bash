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

: "${GREEN:=$'\033[0;32m'}"
: "${NC:=$'\033[0m'}"

# --- Start: Aider-specific logic ---

declare -A AIDER_TEXT_EN=(
    ["install_title"]="Starting Aider CLI installation using the official installer..."
    ["downloading"]="Downloading the official Aider installer script from aider.chat..."
    ["download_fail"]="Failed to download the installer script."
    ["running_installer"]="Running the official Aider installer... This may take a few minutes."
    ["install_fail"]="Aider CLI installation failed. Please check the output above for errors."
    ["command_missing"]="'aider' command not found after installation. You may need to restart your terminal or check your PATH."
    ["version_info"]="Aider CLI version: %s"
    ["interactive_intro"]="Aider requires API keys to function (e.g., OPENAI_API_KEY)."
    ["batch_skip"]="API key setup skipped in batch mode."
    ["batch_note"]="Before running '%s', please export the necessary API keys (e.g., OPENAI_API_KEY)."
    ["install_done"]="Aider CLI installation completed successfully!"
    ["already_installed"]="Aider CLI is already installed:"
)

declare -A AIDER_TEXT_TR=(
    ["install_title"]="Aider CLI resmi yükleyici ile kuruluyor..."
    ["downloading"]="Resmi Aider yükleyici betiği (aider.chat) indiriliyor..."
    ["download_fail"]="Yükleyici betiği indirilemedi."
    ["running_installer"]="Resmi Aider yükleyici çalıştırılıyor... Bu işlem birkaç dakika sürebilir."
    ["install_fail"]="Aider CLI kurulumu başarısız oldu. Hatalar için lütfen yukarıdaki çıktıları kontrol edin."
    ["command_missing"]="'aider' komutu kurulumdan sonra bulunamadı. Terminalinizi yeniden başlatmanız veya PATH'inizi kontrol etmeniz gerekebilir."
    ["version_info"]="Aider CLI sürümü: %s"
    ["interactive_intro"]="Aider'ın çalışması için API anahtarları gereklidir (örn. OPENAI_API_KEY)."
    ["batch_skip"]="Toplu kurulum modunda API anahtarı kurulumu atlandı."
    ["batch_note"]="'%s' komutunu çalıştırmadan önce, lütfen gerekli API anahtarlarını (örn. OPENAI_API_KEY) export edin."
    ["install_done"]="Aider CLI kurulumu başarıyla tamamlandı!"
    ["already_installed"]="Aider CLI zaten kurulu:"
)

aider_text() {
    local key="$1"
    local default_value="${AIDER_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${AIDER_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

# --- End: Aider-specific logic ---

main() {
    local interactive_mode="true"
    [[ $# -gt 0 && "$1" != --* ]] && interactive_mode="$1"

    log_info_detail "$(aider_text install_title)"
    
    if command -v aider &>/dev/null; then
        log_success_detail "$(aider_text already_installed) $(aider --version 2>/dev/null || echo 'unknown')"
    else
        local installer_script
        installer_script=$(mktemp)
        
        log_info_detail "$(aider_text downloading)"
        if ! retry_command "curl -sSf \"https://aider.chat/install.sh\" -o \"$installer_script\""; then
            log_error_detail "$(aider_text download_fail)"
            rm -f "$installer_script"
            return 1
        fi

        log_info_detail "$(aider_text running_installer)"
        
        # The official installer handles Python and dependencies.
        if ! bash "$installer_script"; then
            log_error_detail "$(aider_text install_fail)"
            rm -f "$installer_script"
            return 1
        fi
        rm -f "$installer_script"

        # The installer should add the correct path to the shell profile, but we ensure it here.
        ensure_path_contains_dir "$HOME/.local/bin" "aider"
        reload_shell_configs silent
        hash -r 2>/dev/null || true

        if ! command -v aider >/dev/null 2>&1; then
            log_error_detail "$(aider_text command_missing)"
            return 1
        fi
        log_success_detail "$(aider_text version_info "$(aider --version 2>/dev/null || echo 'unknown')")"
    fi

    if [ "$interactive_mode" = true ]; then
        echo
        log_info_detail "$(aider_text interactive_intro)"
    else
        echo
        log_info_detail "$(aider_text batch_skip)"
        log_info_detail "$(aider_text batch_note "${GREEN}aider${NC}")"
    fi

    log_success_detail "$(aider_text install_done)"
}

main "$@"
