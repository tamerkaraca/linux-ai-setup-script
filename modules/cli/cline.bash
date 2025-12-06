#!/bin/bash
set -euo pipefail

: "${CLINE_NPM_PACKAGE_CANDIDATES:=cline @cline/cli cline-cli}"
: "${CLINE_MANUAL_URL:=https://cline.bot/cline-cli}"
: "${CLINE_MIN_NODE_VERSION:=18}"

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

# --- Start: Cline-specific logic ---

declare -A CLINE_TEXT_EN=(
    ["install_title"]="Starting Cline CLI installation..."
    ["install_fail"]="Cline CLI installation failed. Please follow the official guide: %s"
    ["command_missing"]="'cline' command not found. Check your PATH."
    ["interactive_intro"]="You need to sign in with your Cline account."
    ["interactive_hint"]="Run 'cline login' to authenticate in the browser."
    ["login_error"]="Login failed; run 'cline login' manually if needed."
    ["no_tty"]="TTY not available. Please run 'cline login' manually."
    ["press_enter"]="Press Enter to continue..."
    ["batch_skip"]="Authentication skipped in batch mode."
    ["batch_reminder"]="Please run '%s' manually after installation."
    ["install_done"]="Cline CLI installation completed!"
    ["build_tools_install"]="Installing required native build tools for Cline CLI: %s"
    ["build_tools_warn"]="Could not auto-install build tools. Ensure 'make', 'g++', and 'python3' are available."
)

declare -A CLINE_TEXT_TR=(
    ["install_title"]="Cline CLI kurulumu başlatılıyor..."
    ["install_fail"]="Cline CLI paketleri kurulamadı. Lütfen resmi dökümandaki (%s) adımları izleyin."
    ["command_missing"]="'cline' komutu bulunamadı. PATH ayarlarınızı kontrol edin."
    ["interactive_intro"]="Cline hesabınızla oturum açmanız gerekiyor."
    ["interactive_hint"]="'cline login' komutunu çalıştırarak tarayıcı üzerinden giriş yapın."
    ["login_error"]="Oturum açma sırasında hata oluştu. Gerekirse 'cline login' komutunu manuel çalıştırın."
    ["no_tty"]="TTY erişimi yok. Lütfen 'cline login' komutunu manuel çalıştırın."
    ["press_enter"]="Devam etmek için Enter'a basın..."
    ["batch_skip"]="Toplu kurulum modunda kimlik doğrulama atlandı."
    ["batch_reminder"]="Kurulum sonrası '%s' komutunu manuel olarak çalıştırmayı unutmayın."
    ["install_done"]="Cline CLI kurulumu tamamlandı!"
    ["build_tools_install"]="Cline CLI için gerekli derleme araçları kuruluyor: %s"
    ["build_tools_warn"]="Derleme araçları otomatik kurulamadı. Lütfen 'make', 'g++' ve 'python3' komutlarının mevcut olduğundan emin olun."
)

cline_text() {
    local key="$1"
    local default_value="${CLINE_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${CLINE_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

ensure_cline_build_prereqs() {
    local missing=()
    for tool in make g++ python3; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing+=("$tool")
        fi
    done

    if [ ${#missing[@]} -eq 0 ]; then
        return 0
    fi
    
    log_info_detail "$(cline_text build_tools_install "${missing[*]}")"
    case "${PKG_MANAGER:-}" in
        apt) sudo apt-get update -y >/dev/null 2>&1 && sudo apt-get install -y build-essential python3 python3-dev ;;
        dnf|dnf5) dnf_group_install "Development Tools" && sudo "${PKG_MANAGER:-dnf}" install -y python3 python3-devel make gcc-c++ ;;
        yum) sudo yum groupinstall -y "Development Tools" >/dev/null 2>&1 && sudo yum install -y python3 python3-devel ;;
        pacman) sudo pacman -S --noconfirm base-devel python ;;
        *) log_warn_detail "$(cline_text build_tools_warn)" ;;
    esac
}

# --- End: Cline-specific logic ---

main() {
    local interactive_mode="true"
    [[ $# -gt 0 && "$1" != --* ]] && interactive_mode="$1"

    log_info_detail "$(cline_text install_title)"
    
    # Prerequisites
    require_node_version "$CLINE_MIN_NODE_VERSION" "Cline CLI" || return 1
    ensure_cline_build_prereqs

    # Use the universal installer
    # It tries each candidate package until one succeeds
    install_package "Cline CLI" "npm" "cline" "${CLINE_NPM_PACKAGE_CANDIDATES}"
    local install_status=$?

    if [ $install_status -ne 0 ]; then
        log_error_detail "$(cline_text install_fail "$CLINE_MANUAL_URL")"
        return 1
    fi
    
    # The `install_package` function reloads the shell, but sometimes we need to locate the binary again
    local cline_cmd
    cline_cmd=$(locate_npm_binary "cline") || cline_cmd=$(locate_npm_binary "cline-cli") || {
        log_error_detail "$(cline_text command_missing)"
        return 1
    }

    log_success_detail "Cline CLI found: $cline_cmd ($($cline_cmd --version 2>/dev/null))"

    # Post-install interactive login
    if [ "$interactive_mode" = true ]; then
        echo
        log_info_detail "$(cline_text interactive_intro)"
        log_info_detail "  $(cline_text interactive_hint)"
        if [ -r /dev/tty ] && [ -w /dev/tty ]; then
            "$cline_cmd" login </dev/tty >/dev/tty 2>&1 || log_warn_detail "$(cline_text login_error)"
        else
            log_warn_detail "$(cline_text no_tty)"
        fi
        read -r -p "$(cline_text press_enter)" </dev/tty || true
    else
        echo
        log_info_detail "$(cline_text batch_skip)"
        log_info_detail "$(cline_text batch_reminder "${GREEN}cline login${NC}")"
    fi

    log_success_detail "$(cline_text install_done)"
}

main "$@"