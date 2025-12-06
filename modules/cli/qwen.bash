#!/bin/bash
set -euo pipefail

: "${NPM_LAST_INSTALL_PREFIX:=}"
: "${QWEN_NPM_PACKAGE:=@qwen-code/qwen-code@latest}"
: "${QWEN_MIN_NODE_VERSION:=18}"

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

# --- Start: Qwen-specific logic ---

declare -A QWEN_TEXT_EN=(
    ["install_title"]="Starting Qwen CLI installation..."
    ["npm_missing"]="npm command not found. Please install Node.js first."
    ["install_fail"]="Qwen CLI npm installation failed. Package: %s"
    ["command_missing"]="'qwen' command not found. Check your PATH."
    ["version_info"]="Qwen CLI version: %s"
    ["interactive_intro"]="You need to authenticate with Qwen CLI now."
    ["interactive_prompt"]="Run 'qwen login' and complete the sign-in."
    ["interactive_wait"]="Press Enter when authentication is done."
    ["manual_skip"]="Authentication skipped for batch installs."
    ["manual_reminder"]="Please run '${GREEN}qwen login${NC}' manually after installation."
    ["warn_login_error"]="Login failed; rerun 'qwen login' manually."
    ["warn_no_tty"]="TTY access missing. Run 'qwen login' manually."
    ["install_done"]="Qwen CLI installation completed!"
    ["package_required"]="The '--package' option requires a value."
    ["unknown_arg"]="Unknown argument: %s"
)

declare -A QWEN_TEXT_TR=(
    ["install_title"]="Qwen CLI kurulumu başlatılıyor..."
    ["npm_missing"]="npm komutu bulunamadı. Lütfen önce Node.js kurulumunu tamamlayın."
    ["install_fail"]="Qwen CLI npm kurulumu başarısız oldu. Paket: %s"
    ["command_missing"]="'qwen' komutu bulunamadı. PATH ayarlarınızı kontrol edin."
    ["version_info"]="Qwen CLI sürümü: %s"
    ["interactive_intro"]="Şimdi Qwen CLI ile kimlik doğrulaması yapmalısınız."
    ["interactive_prompt"]="Lütfen 'qwen login' komutunu çalıştırın."
    ["interactive_wait"]="Kimlik doğrulama tamamlandığında Enter'a basın."
    ["manual_skip"]="Toplu kuruluma göre kimlik doğrulama adımı atlandı."
    ["manual_reminder"]="Kurulum sonrası '${GREEN}qwen login${NC}' komutunu manuel olarak çalıştırmayı unutmayın."
    ["warn_login_error"]="Giriş başarısız oldu; 'qwen login' komutunu manuel çalıştırın."
    ["warn_no_tty"]="TTY erişimi yok. 'qwen login' komutunu manuel çalıştırın."
    ["install_done"]="Qwen CLI kurulumu tamamlandı!"
    ["package_required"]="'--package' seçeneği bir değer gerektirir."
    ["unknown_arg"]="Bilinmeyen argüman: %s"
)

qwen_text() {
    local key="$1"
    local default_value="${QWEN_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${QWEN_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

# --- End: Qwen-specific logic ---

main() {
    local interactive_mode="true"
    local package_spec="${QWEN_NPM_PACKAGE}"

    if [[ $# -gt 0 && "$1" != --* ]]; then
        interactive_mode="$1"
        shift
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --package)
                if [ -z "${2:-}" ]; then
                    log_error_detail "$(qwen_text package_required)"
                    return 1
                fi
                package_spec="$2"
                shift
                ;;
            *)
                log_warn_detail "$(qwen_text unknown_arg "$1")"
                ;;
        esac
        shift || true
    done

    log_info_detail "$(qwen_text install_title)"
    
    if command -v qwen &>/dev/null; then
        log_success_detail "Qwen CLI is already installed: $(qwen --version 2>/dev/null)"
    else
        require_node_version "$QWEN_MIN_NODE_VERSION" "Qwen CLI" || return 1

        log_info_detail "Installing Qwen CLI using package: $package_spec"
        if ! npm_install_global_with_fallback "$package_spec" "Qwen CLI"; then
            log_error_detail "$(qwen_text install_fail "$package_spec")"
            return 1
        fi

        reload_shell_configs silent
        hash -r 2>/dev/null || true

        if ! command -v qwen &> /dev/null; then
            log_error_detail "$(qwen_text command_missing)"
            return 1
        fi
        log_success_detail "Qwen CLI installed: $(qwen --version 2>/dev/null)"
    fi

    if [ "$interactive_mode" = true ]; then
        echo
        log_info_detail "$(qwen_text interactive_intro)"
        log_info_detail "  'qwen login' - $(qwen_text interactive_prompt)"
        if [ -r /dev/tty ] && [ -w /dev/tty ]; then
            qwen login </dev/tty >/dev/tty 2>/dev/null || log_warn_detail "$(qwen_text warn_login_error)"
        else
            log_warn_detail "$(qwen_text warn_no_tty)"
        fi
        log_info_detail "$(qwen_text interactive_wait)"
        read -r -p "" </dev/tty || true
    else
        echo
        log_info_detail "$(qwen_text manual_skip)"
        log_info_detail "$(qwen_text manual_reminder)"
    fi

    log_success_detail "$(qwen_text install_done)"
}

main "$@"