#!/bin/bash
set -euo pipefail

: "${NPM_LAST_INSTALL_PREFIX:=}"
: "${CURSOR_NPM_PACKAGE:=cursor-agent}"
: "${CURSOR_MIN_NODE_VERSION:=18}"

UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

declare -A CURSOR_TEXT_EN=(
    ["npm_missing"]="npm command not found. Please install Node.js via menu option 3."
    ["install_title"]="Starting Cursor Agent CLI installation..."
    ["dry_run_requirement"]="Will verify Node.js >= %s."
    ["dry_run_install"]="npm install -g %s"
    ["dry_run_skip"]="Dry-run mode skips authentication."
    ["install_start"]="Cursor Agent CLI npm installation begins..."
    ["install_fail"]="Cursor Agent CLI installation failed. Package: %s"
    ["command_missing"]="'cursor-agent' command not found. Check your PATH."
    ["command_fallback"]="'cursor-agent' not found; '%s' command will be used."
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
    ["dry_run_requirement"]="Node.js >= %s gereksinimi doğrulanacak."
    ["dry_run_install"]="npm install -g %s"
    ["dry_run_skip"]="Dry-run modunda kimlik doğrulama adımları atlanır."
    ["install_start"]="Cursor Agent CLI npm paketinin kurulumu başlatılıyor..."
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

cursor_printf() {
    local __out="$1"
    local __key="$2"
    shift 2
    local __fmt
    __fmt="$(cursor_text "$__key")"
    # shellcheck disable=SC2059
    printf -v "$__out" "$__fmt" "$@"
}

ensure_cursor_npm_available() {
    if command -v npm >/dev/null 2>&1; then
        return 0
    fi
    if bootstrap_node_runtime; then
        return 0
    fi
    echo -e "${RED}${ERROR_TAG}${NC} $(cursor_text npm_missing)"
    return 1
}

install_cursor_cli() {
    local interactive_mode="true"
    local dry_run="false"
    local package_spec="${CURSOR_NPM_PACKAGE}"

    if [[ $# -gt 0 && "$1" != --* ]]; then
        interactive_mode="$1"
        shift
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                dry_run="true"
                ;;
            --package)
                if [ -z "${2:-}" ]; then
                    echo -e "${RED}${ERROR_TAG}${NC} $(cursor_text package_required)"
                    return 1
                fi
                package_spec="$2"
                shift
                ;;
            *)
                local cursor_unknown_msg
                cursor_printf cursor_unknown_msg unknown_arg "$1"
                echo -e "${YELLOW}${WARN_TAG}${NC} ${cursor_unknown_msg}"
                ;;
        esac
        shift || true
    done

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(cursor_text install_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if [ "$dry_run" = true ]; then
        local cursor_req cursor_install
        cursor_printf cursor_req dry_run_requirement "$CURSOR_MIN_NODE_VERSION"
        cursor_printf cursor_install dry_run_install "$package_spec"
        echo -e "${YELLOW}[DRY-RUN]${NC} ${cursor_req}"
        echo -e "${YELLOW}[DRY-RUN]${NC} ${cursor_install}"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(cursor_text dry_run_skip)"
        return 0
    fi

    require_node_version "$CURSOR_MIN_NODE_VERSION" "Cursor Agent CLI" || return 1
    ensure_cursor_npm_available || return 1

    echo -e "${YELLOW}${INFO_TAG}${NC} $(cursor_text install_start)"
    if ! npm_install_global_with_fallback "$package_spec" "Cursor Agent CLI"; then
        local cursor_fail_msg
        cursor_printf cursor_fail_msg install_fail "$package_spec"
        echo -e "${RED}${ERROR_TAG}${NC} ${cursor_fail_msg}"
        return 1
    fi

    if [ -n "${NPM_LAST_INSTALL_PREFIX}" ]; then
        ensure_path_contains_dir "${NPM_LAST_INSTALL_PREFIX}/bin" "npm user prefix"
    fi
    reload_shell_configs silent
    hash -r 2>/dev/null || true

    local cursor_cmd=""
    if cursor_cmd="$(locate_npm_binary "cursor-agent")"; then
        :
    elif cursor_cmd="$(locate_npm_binary "cursor")"; then
        local cursor_fallback_msg
        cursor_printf cursor_fallback_msg command_fallback "${cursor_cmd##*/}"
        echo -e "${YELLOW}${WARN_TAG}${NC} ${cursor_fallback_msg}"
    else
        echo -e "${RED}${ERROR_TAG}${NC} $(cursor_text command_missing)"
        return 1
    fi

    local cursor_version_msg
    cursor_printf cursor_version_msg version_info "$("$cursor_cmd" --version 2>/dev/null)"
    echo -e "${GREEN}${SUCCESS_TAG}${NC} ${cursor_version_msg}"

    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(cursor_text interactive_intro)"
        echo -e "${CYAN}  $(cursor_text interactive_hint)${NC}"
        if [ -r /dev/tty ] && [ -w /dev/tty ]; then
            "$cursor_cmd" login </dev/tty >/dev/tty 2>&1 || echo -e "${YELLOW}${WARN_TAG}${NC} $(cursor_text login_error)"
        else
            echo -e "${YELLOW}${WARN_TAG}${NC} $(cursor_text no_tty)"
        fi
        read -r -p "$(cursor_text press_enter)" </dev/tty || true
    else
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(cursor_text batch_skip)"
        local cursor_reminder
        cursor_printf cursor_reminder batch_reminder "${GREEN}cursor-agent login${NC}"
        echo -e "${YELLOW}${INFO_TAG}${NC} ${cursor_reminder}"
    fi

    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(cursor_text install_done)"
}

main() {
    install_cursor_cli "$@"
}

main "$@"
