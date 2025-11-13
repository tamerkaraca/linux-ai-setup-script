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

ensure_cline_npm_available() {
    if command -v npm >/dev/null 2>&1; then
        return 0
    fi
    if bootstrap_node_runtime; then
        return 0
    fi
    echo -e "${RED}${ERROR_TAG}${NC} npm komutu bulunamadı. Lütfen 'Ana Menü -> 3' ile Node.js kurulumu yapın."
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

    if [ "${LANGUAGE:-en}" = "tr" ]; then
        echo -e "${YELLOW}${INFO_TAG}${NC} Cline CLI için gerekli derleme araçları kuruluyor: ${missing[*]}"
    else
        echo -e "${YELLOW}${INFO_TAG}${NC} Installing required native build tools for Cline CLI: ${missing[*]}"
    fi
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
            echo -e "${YELLOW}${WARN_TAG}${NC} Derleme araçları otomatik kurulamadı. Lütfen 'make', 'g++' ve 'python3' komutlarının mevcut olduğundan emin olun."
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
                    echo -e "${RED}${ERROR_TAG}${NC} '--package' seçeneği bir değer gerektirir."
                    return 1
                fi
                package_spec="$2"
                custom_package="true"
                shift
                ;;
            *)
                echo -e "${YELLOW}${WARN_TAG}${NC} Bilinmeyen argüman: $1"
                ;;
        esac
        shift || true
    done

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} Cline CLI kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if [ "$dry_run" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Node.js >= ${CLINE_MIN_NODE_VERSION} doğrulanacak."
        echo -e "${YELLOW}[DRY-RUN]${NC} npm install -g ${package_spec}"
        echo -e "${YELLOW}${INFO_TAG}${NC} Dry-run modunda kimlik doğrulama adımları atlanır."
        return 0
    fi

    require_node_version "$CLINE_MIN_NODE_VERSION" "Cline CLI" || return 1
    ensure_cline_npm_available || return 1

    echo -e "${YELLOW}${INFO_TAG}${NC} Cline CLI npm paketinin kurulumu başlatılıyor..."

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
        echo -e "${YELLOW}${WARN_TAG}${NC} ${candidate} paketi kurulamadı, bir sonraki aday denenecek."
    done

    if [ -z "$installed_package" ]; then
        echo -e "${RED}${ERROR_TAG}${NC} Cline CLI paketleri kurulamadı. Lütfen resmi dökümandaki ( ${CLINE_MANUAL_URL} ) adımları izleyin."
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
        echo -e "${RED}${ERROR_TAG}${NC} 'cline' komutu bulunamadı. PATH ayarlarınızı kontrol edin."
        echo -e "${YELLOW}${INFO_TAG}${NC} Manuel kurulum rehberi: ${CLINE_MANUAL_URL}"
        return 1
    fi

    echo -e "${GREEN}${SUCCESS_TAG}${NC} Cline CLI sürümü: $("$cline_cmd" --version 2>/dev/null)"

    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}${INFO_TAG}${NC} Cline hesabınızla oturum açmanız gerekiyor."
        echo -e "${CYAN}  cline login${NC} komutunu çalıştırarak tarayıcı üzerinden giriş yapın."
        if [ -r /dev/tty ] && [ -w /dev/tty ]; then
            "$cline_cmd" login </dev/tty >/dev/tty 2>&1 || echo -e "${YELLOW}${WARN_TAG}${NC} Oturum açma sırasında bir hata oluştu. Gerekirse manuel olarak 'cline login' çalıştırın."
        else
            echo -e "${YELLOW}${WARN_TAG}${NC} TTY erişimi yok. Lütfen manuel olarak 'cline login' çalıştırın."
        fi
        read -r -p "Devam etmek için Enter'a basın..." </dev/tty || true
    else
        echo -e "\n${YELLOW}${INFO_TAG}${NC} Toplu kurulum modunda kimlik doğrulama atlandı."
        echo -e "${YELLOW}${INFO_TAG}${NC} Kurulum sonrası '${GREEN}cline login${NC}' komutunu manuel olarak çalıştırmayı unutmayın."
    fi

    echo -e "${GREEN}${SUCCESS_TAG}${NC} Cline CLI kurulumu tamamlandı!"
}

main() {
    install_cline_cli "$@"
}

main "$@"
