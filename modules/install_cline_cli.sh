#!/bin/bash
set -euo pipefail

: "${NPM_LAST_INSTALL_PREFIX:=}"
: "${CLINE_NPM_PACKAGE:=cline}"
: "${CLINE_NPM_PACKAGE_CANDIDATES:=cline @cline/cli cline-cli}"
: "${CLINE_MANUAL_URL:=https://cline.bot/cline-cli}"
: "${CLINE_MIN_NODE_VERSION:=18}"

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

declare -A CLINE_TEXT_EN=(
    ["npm_missing"]="npm command not found. Please install Node.js via menu option 3."
    ["install_title"]="Starting Cline CLI installation..."
    ["dry_run_requirement"]="Will verify Node.js >= %s."
    ["dry_run_install"]="npm install -g %s"
    ["dry_run_skip"]="Dry-run mode skips authentication."
    ["install_start"]="Cline CLI npm installation begins..."
    ["install_fail"]="Cline CLI installation failed. Package: %s"
    ["package_retry"]="%s could not be installed, trying next candidate."
    ["all_fail"]="Cline CLI packages could not be installed. Please follow the official guide: %s"
    ["command_missing"]="'cline' command not found. Check your PATH."
    ["manual_guide"]="Manual installation guide: %s"
    ["version_info"]="Cline CLI version: %s"
    ["interactive_intro"]="You need to sign in with your Cline account."
    ["interactive_hint"]="Run 'cline login' to authenticate in the browser."
    ["login_error"]="Login failed; run 'cline login' manually if needed."
    ["no_tty"]="TTY not available. Please run 'cline login' manually."
    ["press_enter"]="Press Enter to continue..."
    ["batch_skip"]="Authentication skipped in batch mode."
    ["batch_reminder"]="Please run '%s' manually after installation."
    ["install_done"]="Cline CLI installation completed!"
    ["package_required"]="The '--package' option requires a value."
    ["unknown_arg"]="Unknown argument: %s"
    ["build_tools_install"]="Installing required native build tools for Cline CLI: %s"
    ["build_tools_warn"]="Could not auto-install build tools. Ensure 'make', 'g++', and 'python3' are available."
)

declare -A CLINE_TEXT_TR=(
    ["npm_missing"]="npm komutu bulunamadı. Lütfen ana menüdeki 3. seçenek ile Node.js kurun."
    ["install_title"]="Cline CLI kurulumu başlatılıyor..."
    ["dry_run_requirement"]="Node.js >= %s gereksinimi doğrulanacak."
    ["dry_run_install"]="npm install -g %s"
    ["dry_run_skip"]="Dry-run modunda kimlik doğrulama adımları atlanır."
    ["install_start"]="Cline CLI npm paketinin kurulumu başlatılıyor..."
    ["install_fail"]="Cline CLI kurulumu başarısız oldu. Paket: %s"
    ["package_retry"]="%s paketi kurulamadı, bir sonraki aday denenecek."
    ["all_fail"]="Cline CLI paketleri kurulamadı. Lütfen resmi dökümandaki (%s) adımları izleyin."
    ["command_missing"]="'cline' komutu bulunamadı. PATH ayarlarınızı kontrol edin."
    ["manual_guide"]="Manuel kurulum rehberi: %s"
    ["version_info"]="Cline CLI sürümü: %s"
    ["interactive_intro"]="Cline hesabınızla oturum açmanız gerekiyor."
    ["interactive_hint"]="'cline login' komutunu çalıştırarak tarayıcı üzerinden giriş yapın."
    ["login_error"]="Oturum açma sırasında hata oluştu. Gerekirse 'cline login' komutunu manuel çalıştırın."
    ["no_tty"]="TTY erişimi yok. Lütfen 'cline login' komutunu manuel çalıştırın."
    ["press_enter"]="Devam etmek için Enter'a basın..."
    ["batch_skip"]="Toplu kurulum modunda kimlik doğrulama atlandı."
    ["batch_reminder"]="Kurulum sonrası '%s' komutunu manuel olarak çalıştırmayı unutmayın."
    ["install_done"]="Cline CLI kurulumu tamamlandı!"
    ["package_required"]="'--package' seçeneği bir değer gerektirir."
    ["unknown_arg"]="Bilinmeyen argüman: %s"
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

cline_printf() {
    local __out="$1"
    local __key="$2"
    shift 2
    local __fmt
    __fmt="$(cline_text "$__key")"
    # shellcheck disable=SC2059
    printf -v "$__out" "$__fmt" "$@"
}

ensure_cline_npm_available() {
    if command -v npm >/dev/null 2>&1; then
        return 0
    fi
    if bootstrap_node_runtime; then
        return 0
    fi
    echo -e "${RED}${ERROR_TAG}${NC} $(cline_text npm_missing)"
    return 1
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

    if [ -z "${PKG_MANAGER:-}" ]; then
        detect_package_manager
    fi

    local cline_build_msg
    cline_printf cline_build_msg build_tools_install "${missing[*]}"
    echo -e "${YELLOW}${INFO_TAG}${NC} ${cline_build_msg}"
    case "$PKG_MANAGER" in
        apt)
            sudo apt update -y >/dev/null 2>&1 || true
            sudo apt install -y build-essential python3 python3-dev >/dev/null 2>&1
            ;;
        dnf|dnf5)
            sudo "${PKG_MANAGER}" install -y @'Development Tools' python3 python3-devel make gcc-c++ >/dev/null 2>&1 || \
            sudo "${PKG_MANAGER}" group install -y "Development Tools" >/dev/null 2>&1
            ;;
        yum)
            sudo yum groupinstall -y "Development Tools" >/dev/null 2>&1
            sudo yum install -y python3 python3-devel >/dev/null 2>&1
            ;;
        pacman)
            sudo pacman -Sy --noconfirm base-devel python >/dev/null 2>&1
            ;;
        *)
            echo -e "${YELLOW}${WARN_TAG}${NC} $(cline_text build_tools_warn)"
            ;;
    esac
}

install_cline_cli() {
    local interactive_mode="true"
    local dry_run="false"
    local package_spec="${CLINE_NPM_PACKAGE}"
    local custom_package="false"

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
                    echo -e "${RED}${ERROR_TAG}${NC} $(cline_text package_required)"
                    return 1
                fi
                package_spec="$2"
                custom_package="true"
                shift
                ;;
            *)
                local cline_unknown_msg
                cline_printf cline_unknown_msg unknown_arg "$1"
                echo -e "${YELLOW}${WARN_TAG}${NC} ${cline_unknown_msg}"
                ;;
        esac
        shift || true
    done

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(cline_text install_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if [ "$dry_run" = true ]; then
        local cline_req cline_install
        cline_printf cline_req dry_run_requirement "$CLINE_MIN_NODE_VERSION"
        cline_printf cline_install dry_run_install "$package_spec"
        echo -e "${YELLOW}[DRY-RUN]${NC} ${cline_req}"
        echo -e "${YELLOW}[DRY-RUN]${NC} ${cline_install}"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(cline_text dry_run_skip)"
        return 0
    fi

    require_node_version "$CLINE_MIN_NODE_VERSION" "Cline CLI" || return 1
    ensure_cline_npm_available || return 1

    echo -e "${YELLOW}${INFO_TAG}${NC} $(cline_text install_start)"

    local -a package_candidates=()
    if [ "$custom_package" = "true" ]; then
        package_candidates=("$package_spec")
    else
        read -r -a package_candidates <<< "${CLINE_NPM_PACKAGE_CANDIDATES}"
    fi

    ensure_cline_build_prereqs

    local installed_package=""
    for candidate in "${package_candidates[@]}"; do
        [ -z "$candidate" ] && continue
        echo -e "${YELLOW}${INFO_TAG}${NC} npm install -g ${candidate}"
        if npm_install_global_with_fallback "$candidate" "Cline CLI (${candidate})"; then
            installed_package="$candidate"
            package_spec="$candidate"
            break
        fi
        local retry_msg
        cline_printf retry_msg package_retry "$candidate"
        echo -e "${YELLOW}${WARN_TAG}${NC} ${retry_msg}"
    done

    if [ -z "$installed_package" ]; then
        local fail_msg
        cline_printf fail_msg all_fail "$CLINE_MANUAL_URL"
        echo -e "${RED}${ERROR_TAG}${NC} ${fail_msg}"
        return 1
    fi

    if [ -n "${NPM_LAST_INSTALL_PREFIX}" ]; then
        ensure_path_contains_dir "${NPM_LAST_INSTALL_PREFIX}/bin" "npm user prefix"
    fi
    reload_shell_configs silent
    hash -r 2>/dev/null || true

    local cline_cmd=""
    for bin_name in cline cline-cli; do
        if cline_cmd="$(locate_npm_binary "$bin_name")"; then
            break
        fi
    done

    if [ -z "$cline_cmd" ]; then
        echo -e "${RED}${ERROR_TAG}${NC} $(cline_text command_missing)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(cline_text manual_guide)"
        return 1
    fi

    local cline_version_msg
    cline_printf cline_version_msg version_info "$("$cline_cmd" --version 2>/dev/null)"
    echo -e "${GREEN}${SUCCESS_TAG}${NC} ${cline_version_msg}"

    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(cline_text interactive_intro)"
        echo -e "${CYAN}  $(cline_text interactive_hint)${NC}"
        if [ -r /dev/tty ] && [ -w /dev/tty ]; then
            "$cline_cmd" login </dev/tty >/dev/tty 2>&1 || echo -e "${YELLOW}${WARN_TAG}${NC} $(cline_text login_error)"
        else
            echo -e "${YELLOW}${WARN_TAG}${NC} $(cline_text no_tty)"
        fi
        read -r -p "$(cline_text press_enter)" </dev/tty || true
    else
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(cline_text batch_skip)"
        local reminder_msg
        cline_printf reminder_msg batch_reminder "${GREEN}cline login${NC}"
        echo -e "${YELLOW}${INFO_TAG}${NC} ${reminder_msg}"
    fi

    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(cline_text install_done)"
}

main() {
    install_cline_cli "$@"
}

main "$@"
