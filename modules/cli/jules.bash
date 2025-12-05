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

# --- Start: Jules-specific logic ---

declare -A JULES_TEXT_EN=(
    ["install_title"]="Starting Jules CLI installation..."
    ["install_fail"]="Jules CLI npm installation failed."
    ["interactive_intro"]="You need to sign in to Jules CLI now."
    ["interactive_command"]="Please run 'jules login' and complete the flow."
    ["interactive_wait"]="Press Enter once authentication is complete."
    ["manual_skip"]="Authentication skipped in 'Install All' mode."
    ["manual_reminder"]="Please run '${GREEN}jules login${NC}' manually later."
    ["manual_hint"]="Manual authentication may be required."
    ["install_done"]="Jules CLI installation completed!"
    ["auth_prompt"]="Press Enter to continue..."
)

declare -A JULES_TEXT_TR=(
    ["install_title"]="Jules CLI kurulumu başlatılıyor..."
    ["install_fail"]="Jules CLI npm paketinin kurulumu başarısız oldu."
    ["interactive_intro"]="Şimdi Jules CLI'ya giriş yapmanız gerekiyor."
    ["interactive_command"]="Lütfen 'jules login' komutunu çalıştırıp oturumu tamamlayın."
    ["interactive_wait"]="Kimlik doğrulama tamamlanınca Enter'a basın."
    ["manual_skip"]="'Tümünü Kur' modunda kimlik doğrulama atlandı."
    ["manual_reminder"]="Lütfen daha sonra '${GREEN}jules login${NC}' komutunu manuel olarak çalıştırın."
    ["manual_hint"]="Manuel oturum açma gerekebilir."
    ["install_done"]="Jules CLI kurulumu tamamlandı!"
    ["auth_prompt"]="Devam etmek için Enter'a basın..."
)

jules_text() {
    local key="$1"
    local default_value="${JULES_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${JULES_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

# --- End: Jules-specific logic ---

main() {
    local interactive_mode=${1:-true}

    log_info_detail "$(jules_text install_title)"

    require_node_version 18 "Jules CLI" || return 1
    
    install_package "Jules CLI" "npm" "jules" "@google/jules"
    local install_status=$?

    if [ $install_status -ne 0 ]; then
        log_error_detail "$(jules_text install_fail)"
        return 1
    fi

    if ! command -v jules &> /dev/null; then
        log_error_detail "Jules command not found after installation."
        return 1
    fi
    
    log_success_detail "Jules CLI version: $(jules --version)"
    
    if [ "$interactive_mode" = true ]; then
        echo
        log_info_detail "$(jules_text interactive_intro)"
        log_info_detail "$(jules_text interactive_command)"
        log_info_detail "$(jules_text interactive_wait)"
        
        jules login </dev/tty >/dev/tty 2>&1 || log_warn_detail "$(jules_text manual_hint)"
        
        log_info_detail "$(jules_text auth_prompt)"
        read -r -p "" </dev/tty
    else
        echo
        log_info_detail "$(jules_text manual_skip)"
        log_info_detail "$(jules_text manual_reminder)"
    fi

    log_success_detail "$(jules_text install_done)"
}

main "$@"