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

# Bu modül, Gemini CLI'ı kurar ve etkileşimli oturum açma işlemi için kullanıcıyı yönlendirir.
# utils.sh'deki evrensel 'install_package' fonksiyonunu ve ardından
# bu scripte özel TTY/login mantığını kullanır.

# --- Start: Gemini-specific post-install logic ---

declare -A GEMINI_TEXT_EN=(
    ["interactive_intro"]="You need to sign in to Gemini CLI now."
    ["interactive_command"]="Please run 'gemini auth' and complete the flow."
    ["interactive_wait"]="Press Enter once authentication is complete."
    ["manual_skip"]="Authentication skipped in 'Install All' mode."
    ["manual_reminder"]="Please run 'gemini auth' manually later."
    ["manual_hint"]="Manual authentication may be required."
    ["install_done"]="Gemini CLI installation and configuration finished!"
    ["auth_prompt"]="Press Enter to continue..."
    ["install_failed"]="Gemini CLI installation failed. Aborting post-install steps."
    ["cmd_not_found"]="Gemini command not found after installation. Aborting post-install steps."
)

declare -A GEMINI_TEXT_TR=(
    ["interactive_intro"]="Şimdi Gemini CLI'ya giriş yapmanız gerekiyor."
    ["interactive_command"]="Lütfen 'gemini auth' komutunu çalıştırıp oturumu tamamlayın."
    ["interactive_wait"]="Kimlik doğrulama tamamlanınca Enter'a basın."
    ["manual_skip"]="'Tümünü Kur' modunda kimlik doğrulama atlandı."
    ["manual_reminder"]="Lütfen daha sonra 'gemini auth' komutunu manuel olarak çalıştırın."
    ["manual_hint"]="Manuel oturum açma gerekebilir."
    ["install_done"]="Gemini CLI kurulumu ve yapılandırması tamamlandı!"
    ["auth_prompt"]="Devam etmek için Enter'a basın..."
    ["install_failed"]="Gemini CLI kurulumu başarısız. Kurulum sonrası adımlar iptal ediliyor."
    ["cmd_not_found"]="Gemini komutu kurulumdan sonra bulunamadı. Kurulum sonrası adımlar iptal ediliyor."
)

gemini_text() {
    local key="$1"
    local default_value="${GEMINI_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${GEMINI_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

# --- End: Gemini-specific post-install logic ---


main() {
    local interactive_mode=${1:-true}

    # Prerequisite check
    require_node_version 20 "Gemini CLI" || return 1

    # Use the universal installer from utils.sh
    install_package "Gemini CLI" "npm" "gemini" "@google/gemini-cli"
    local install_status=$?

    # If installation failed, exit
    if [ $install_status -ne 0 ]; then
        log_error_detail "$(gemini_text install_failed)"
        return 1
    fi
    
    # If the command is still not found after successful install (e.g. PATH issue), exit.
    if ! command -v gemini &> /dev/null; then
        log_error_detail "$(gemini_text cmd_not_found)"
        return 1
    fi

    # Proceed with Gemini-specific post-installation steps (auth)
    if [ "$interactive_mode" = true ]; then
        echo # Add a newline for readability
        log_info_detail "$(gemini_text interactive_intro)"
        log_info_detail "$(gemini_text interactive_command)"
        log_info_detail "$(gemini_text interactive_wait)"
        
        gemini auth </dev/tty >/dev/tty 2>&1 || log_warn_detail "$(gemini_text manual_hint)"
        
        log_info_detail "$(gemini_text auth_prompt)"
        read -r -p "" </dev/tty
    else
        echo # Add a newline for readability
        log_info_detail "$(gemini_text manual_skip)"
        log_info_detail "$(gemini_text manual_reminder)"
    fi
    
    log_success_detail "$(gemini_text install_done)"
}

main "$@"