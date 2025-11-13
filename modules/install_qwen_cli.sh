#!/bin/bash
set -euo pipefail

: "${NPM_LAST_INSTALL_PREFIX:=}"
: "${QWEN_NPM_PACKAGE:=@qwen-code/qwen-code@latest}"
: "${QWEN_MIN_NODE_VERSION:=18}"

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
    ["dry_run_requirement"]="Will verify Node.js >= %s."
    ["dry_run_install"]="npm install -g %s"
    ["dry_run_skip"]="Authentication is skipped in dry-run mode."
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
    ["dry_run_requirement"]="Node.js >= %s gereksinimi doğrulanacak."
    ["dry_run_install"]="npm install -g %s"
    ["dry_run_skip"]="Dry-run modunda kimlik doğrulama adımları atlanır."
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

qwen_printf() {
    local __out="$1"
    local __key="$2"
    shift 2
    local __fmt
    __fmt="$(qwen_text "$__key")"
    # shellcheck disable=SC2059
    printf -v "$__out" "$__fmt" "$@"
}

ensure_npm_available() {
    if command -v npm >/dev/null 2>&1; then
        return 0
    fi
    if bootstrap_node_runtime; then
        return 0
    fi
    echo -e "${RED}${ERROR_TAG}${NC} $(qwen_text npm_missing)"
    return 1
}

install_qwen_cli() {
    local interactive_mode="true"
    local dry_run="false"
    local package_spec="${QWEN_NPM_PACKAGE}"

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
                    echo -e "${RED}${ERROR_TAG}${NC} $(qwen_text package_required)"
                    return 1
                fi
                package_spec="$2"
                shift
                ;;
            *)
                local qwen_unknown_msg
                qwen_printf qwen_unknown_msg unknown_arg "$1"
                echo -e "${YELLOW}${WARN_TAG}${NC} ${qwen_unknown_msg}"
                ;;
        esac
        shift || true
    done

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(qwen_text install_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if [ "$dry_run" = true ]; then
        local qwen_req_fmt qwen_install_fmt
        qwen_req_fmt="$(qwen_text dry_run_requirement)"
        qwen_install_fmt="$(qwen_text dry_run_install)"
        # shellcheck disable=SC2059
        printf -v qwen_req "$qwen_req_fmt" "$QWEN_MIN_NODE_VERSION"
        # shellcheck disable=SC2059
        printf -v qwen_install_cmd "$qwen_install_fmt" "$package_spec"
        echo -e "${YELLOW}[DRY-RUN]${NC} ${qwen_req}"
        echo -e "${YELLOW}[DRY-RUN]${NC} ${qwen_install_cmd}"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(qwen_text dry_run_skip)"
        return 0
    fi

    require_node_version "$QWEN_MIN_NODE_VERSION" "Qwen CLI" || return 1
    ensure_npm_available || return 1

    echo -e "${YELLOW}${INFO_TAG}${NC} $(qwen_text install_title)"
    if ! npm_install_global_with_fallback "$package_spec" "Qwen CLI"; then
        local qwen_install_fmt
        qwen_install_fmt="$(qwen_text install_fail)"
        # shellcheck disable=SC2059
        printf -v qwen_install_error "$qwen_install_fmt" "$package_spec"
        echo -e "${RED}${ERROR_TAG}${NC} ${qwen_install_error}"
        return 1
    fi

    if [ -n "${NPM_LAST_INSTALL_PREFIX}" ]; then
        ensure_path_contains_dir "${NPM_LAST_INSTALL_PREFIX}/bin" "npm user prefix"
    fi
    reload_shell_configs silent
    hash -r 2>/dev/null || true

    if ! command -v qwen >/dev/null 2>&1; then
        echo -e "${RED}${ERROR_TAG}${NC} $(qwen_text command_missing)"
        return 1
    fi

    local qwen_version_fmt
    qwen_version_fmt="$(qwen_text version_info)"
    # shellcheck disable=SC2059
    printf -v qwen_version_msg "$qwen_version_fmt" "$(qwen --version 2>/dev/null)"
    echo -e "${GREEN}${SUCCESS_TAG}${NC} ${qwen_version_msg}"

    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(qwen_text interactive_intro)"
        echo -e "${CYAN}  qwen login${NC} $(qwen_text interactive_prompt)"
        if [ -r /dev/tty ] && [ -w /dev/tty ]; then
            qwen login </dev/tty >/dev/tty 2>/dev/null || echo -e "${YELLOW}${WARN_TAG}${NC} $(qwen_text warn_login_error)"
        else
            echo -e "${YELLOW}${WARN_TAG}${NC} $(qwen_text warn_no_tty)"
        fi
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(qwen_text interactive_wait)"
        read -r -p "" </dev/tty || true
    else
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(qwen_text manual_skip)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(qwen_text manual_reminder)"
    fi

    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(qwen_text install_done)"
}

main() {
    install_qwen_cli "$@"
}

main "$@"
