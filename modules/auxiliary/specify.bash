#!/bin/bash
# Windows CRLF düzeltme kontrolü
if [ -f "$0" ]; then
    if command -v file &>/dev/null && file "$0" | grep -q "CRLF"; then
        if command -v dos2unix &> /dev/null; then dos2unix "$0"; elif command -v sed &> /dev/null; then sed -i 's/\r$//' "$0"; fi
        exec bash "$0" "$@"
    fi
fi
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

: "${RED:=\033[0;31m}"
: "${GREEN:=\033[0;32m}"
: "${YELLOW:=\033[1;33m}"
: "${BLUE:=\033[0;34m}"
: "${CYAN:=\033[0;36m}"
: "${NC:=\033[0m}"

declare -A SPECIFY_TEXT_EN=(
    ["install_title"]="Installing specify-cli (from github/spec-kit)..."
    ["uv_missing"]="'uv' command not found. Please install Python Tools (Main Menu -> 2) first."
    ["installing"]="Installing 'specify-cli' via 'uv tool install' from git..."
    ["install_fail"]="specify-cli installation failed."
    ["command_missing"]="'specify' command not found after installation. Check your PATH (uv's bin path should be sourced)."
    ["version_info"]="specify-cli version: %s"
    ["install_done"]="specify-cli installation completed!"
    ["usage_note"]="You can now use 'specify' to manage your project specs."
)

declare -A SPECIFY_TEXT_TR=(
    ["install_title"]="specify-cli (github/spec-kit'ten) kuruluyor..."
    ["uv_missing"]="'uv' komutu bulunamadı. Lütfen önce Python Araçlarını (Ana Menü -> 2) kurun."
    ["installing"]="'specify-cli' git üzerinden 'uv tool install' ile kuruluyor..."
    ["install_fail"]="specify-cli kurulumu başarısız oldu."
    ["command_missing"]="'specify' komutu kurulumdan sonra bulunamadı. PATH ayarlarınızı kontrol edin (uv'nin bin yolu kaynak olarak eklenmelidir)."
    ["version_info"]="specify-cli sürümü: %s"
    ["install_done"]="specify-cli kurulumu tamamlandı!"
    ["usage_note"]="Artık proje spesifikasyonlarınızı yönetmek için 'specify' komutunu kullanabilirsiniz."
)

specify_text() {
    local key="$1"
    local default_value="${SPECIFY_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${SPECIFY_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

install_specify_cli() {
    log_info_detail "$(specify_text install_title)"

    if ! command -v uv &> /dev/null; then
        log_info_detail "'uv' not found, attempting to install it..."
        if ! install_uv; then
            log_error_detail "$(specify_text uv_missing)"
            return 1
        fi
        # After installation, ensure the path is recognized in the current script
        if [ -d "$HOME/.local/bin" ]; then
            export PATH="$HOME/.local/bin:$PATH"
        fi
    fi

    log_info_detail "$(specify_text installing)"
    if ! uv tool install specify-cli --from git+https://github.com/github/spec-kit.git; then
        log_error_detail "$(specify_text install_fail)"
        return 1
    fi

    reload_shell_configs silent
    hash -r 2>/dev/null || true

    if ! command -v specify &> /dev/null; then
        log_error_detail "$(specify_text command_missing)"
        return 1
    fi

    local version_info
    version_info=$(specify --version 2>/dev/null || echo "unknown")
    log_success_detail "$(specify_text version_info "$version_info")"
    
    log_success_detail "$(specify_text install_done)"
    log_info_detail "$(specify_text usage_note)"
}

main() {
    install_specify_cli
}

main "$@"
