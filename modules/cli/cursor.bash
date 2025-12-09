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

# --- Start: Cursor-specific logic ---

declare -A CURSOR_TEXT_EN=(
    ["install_title"]="Starting Cursor Agent CLI installation..."
    ["npm_missing"]="npm command not found. Please install Node.js via menu option 3."
    ["install_fail"]="Cursor Agent CLI installation failed. Package: %s"
    ["command_missing"]="'cursor-agent' command not found. Check your PATH."
    ["command_fallback"]="'cursor-agent' not found; fallback '%s' will be used."
    ["version_info"]="Cursor Agent CLI version: %s"
    ["interactive_intro"]="You need to sign in with your Cursor account."
    ["interactive_hint"]="Run 'cursor-agent login' to open the browser flow."
    ["login_error"]="Login failed; run 'cursor-agent login' manually."
    ["no_tty"]="TTY not available. Run 'cursor-agent login' manually."
    ["press_enter"]="Press Enter to continue..."
    ["batch_skip"]="Authentication skipped in batch mode."
    ["batch_reminder"]="Please run '%s' manually after installation."
    ["install_done"]="Cursor Agent CLI installation completed!"
    ["package_required"]="The '--package' option requires a value."
    ["unknown_arg"]="Unknown argument: %s"
)

declare -A CURSOR_TEXT_TR=(
    ["npm_missing"]="npm komutu bulunamadı. Lütfen ana menüdeki 3. seçenek ile Node.js kurun."
    ["install_title"]="Cursor Agent CLI kurulumu başlatılıyor..."
    ["install_fail"]="Cursor Agent CLI kurulumu başarısız oldu. Paket: %s"
    ["command_missing"]="'cursor-agent' komutu bulunamadı. PATH ayarlarınızı kontrol edin."
    ["command_fallback"]="'cursor-agent' yerine '%s' komutu bulundu; bu komut kullanılacak."
    ["version_info"]="Cursor Agent CLI sürümü: %s"
    ["interactive_intro"]="Cursor hesabınızla oturum açmanız gerekiyor."
    ["interactive_hint"]="'cursor-agent login' komutunu çalıştırarak tarayıcı üzerinden giriş yapın."
    ["login_error"]="Oturum açma sırasında hata oluştu. Gerekirse 'cursor-agent login' komutunu manuel çalıştırın."
    ["no_tty"]="TTY erişimi yok. Lütfen 'cursor-agent login' komutunu manuel çalıştırın."
    ["press_enter"]="Devam etmek için Enter'a basın..."
    ["batch_skip"]="Toplu kurulum modunda kimlik doğrulama atlandı."
    ["batch_reminder"]="Kurulum sonrası '%s' komutunu manuel çalıştırmayı unutmayın."
    ["install_done"]="Cursor Agent CLI kurulumu tamamlandı!"
    ["package_required"]="'--package' seçeneği bir değer gerektirir."
    ["unknown_arg"]="Bilinmeyen argüman: %s"
)

cursor_text() {
    local key="$1"
    local default_value="${CURSOR_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${CURSOR_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

# --- End: Cursor-specific logic ---

main() {
    local interactive_mode="true"
    if [[ $# -gt 0 && "$1" != --* ]]; then
        interactive_mode="$1"
        shift
    fi

    log_info_detail "$(cursor_text install_title)"

    if ! command -v cursor-agent &>/dev/null; then
        log_info_detail "Installing Cursor Agent CLI via curl script..."
        local install_cmd="curl https://cursor.com/install -fsS | bash"
        if ! retry_command "$install_cmd"; then
            log_error_detail "Cursor Agent CLI installation failed."
            return 1
        fi
        reload_shell_configs silent
        hash -r 2>/dev/null || true
    else
        log_success_detail "Cursor Agent CLI is already installed."
    fi

    local cursor_cmd="cursor-agent"
    if ! command -v "$cursor_cmd" &> /dev/null; then
        log_error_detail "$(cursor_text command_missing)"
        return 1
    fi
    
    log_success_detail "$(cursor_text version_info "$("$cursor_cmd" --version 2>/dev/null)")"

    if [ "$interactive_mode" = true ]; then
        echo
        log_info_detail "$(cursor_text interactive_intro)"
        log_info_detail "  $(cursor_text interactive_hint)"
        if [ -r /dev/tty ] && [ -w /dev/tty ]; then
            "$cursor_cmd" login </dev/tty >/dev/tty 2>&1 || log_warn_detail "$(cursor_text login_error)"
        else
            log_warn_detail "$(cursor_text no_tty)"
        fi
        read -r -p "$(cursor_text press_enter)" </dev/tty || true
    else
        echo
        log_info_detail "$(cursor_text batch_skip)"
        log_info_detail "$(cursor_text batch_reminder "${GREEN}${cursor_cmd##*/} login${NC}")"
    fi

    log_success_detail "$(cursor_text install_done)"
}

main "$@"