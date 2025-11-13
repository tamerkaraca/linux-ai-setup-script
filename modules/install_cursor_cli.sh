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

ensure_cursor_npm_available() {
    if command -v npm >/dev/null 2>&1; then
        return 0
    fi
    if bootstrap_node_runtime; then
        return 0
    fi
    echo -e "${RED}${ERROR_TAG}${NC} npm komutu bulunamadı. Lütfen 'Ana Menü -> 3' ile Node.js kurulumu yapın."
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
                    echo -e "${RED}${ERROR_TAG}${NC} '--package' seçeneği bir değer gerektirir."
                    return 1
                fi
                package_spec="$2"
                shift
                ;;
            *)
                echo -e "${YELLOW}${WARN_TAG}${NC} Bilinmeyen argüman: $1"
                ;;
        esac
        shift || true
    done

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} Cursor Agent CLI kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if [ "$dry_run" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Node.js >= ${CURSOR_MIN_NODE_VERSION} doğrulanacak."
        echo -e "${YELLOW}[DRY-RUN]${NC} npm install -g ${package_spec}"
        echo -e "${YELLOW}${INFO_TAG}${NC} Dry-run modunda kimlik doğrulama adımları atlanır."
        return 0
    fi

    require_node_version "$CURSOR_MIN_NODE_VERSION" "Cursor Agent CLI" || return 1
    ensure_cursor_npm_available || return 1

    echo -e "${YELLOW}${INFO_TAG}${NC} Cursor Agent CLI npm paketinin kurulumu başlatılıyor..."
    if ! npm_install_global_with_fallback "$package_spec" "Cursor Agent CLI"; then
        echo -e "${RED}${ERROR_TAG}${NC} Cursor Agent CLI kurulumu başarısız oldu. Paket: ${package_spec}"
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
        echo -e "${YELLOW}${WARN_TAG}${NC} 'cursor-agent' yerine '${cursor_cmd##*/}' komutu bulundu; bu komut kullanılacak."
    else
        echo -e "${RED}${ERROR_TAG}${NC} 'cursor-agent' komutu bulunamadı. PATH ayarlarınızı kontrol edin."
        return 1
    fi

    echo -e "${GREEN}${SUCCESS_TAG}${NC} Cursor Agent CLI sürümü: $("$cursor_cmd" --version 2>/dev/null)"

    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}${INFO_TAG}${NC} Cursor hesabınızla oturum açmanız gerekiyor."
        echo -e "${CYAN}  cursor-agent login${NC} komutunu çalıştırarak tarayıcı üzerinden giriş yapın."
        if [ -r /dev/tty ] && [ -w /dev/tty ]; then
            "$cursor_cmd" login </dev/tty >/dev/tty 2>&1 || echo -e "${YELLOW}${WARN_TAG}${NC} Oturum açma sırasında bir hata oluştu. Gerekirse manuel olarak 'cursor-agent login' çalıştırın."
        else
            echo -e "${YELLOW}${WARN_TAG}${NC} TTY erişimi yok. Lütfen manuel olarak 'cursor-agent login' çalıştırın."
        fi
        read -r -p "Devam etmek için Enter'a basın..." </dev/tty || true
    else
        echo -e "\n${YELLOW}${INFO_TAG}${NC} Toplu kurulum modunda kimlik doğrulama atlandı."
        echo -e "${YELLOW}${INFO_TAG}${NC} Kurulum sonrası '${GREEN}cursor-agent login${NC}' komutunu manuel olarak çalıştırmayı unutmayın."
    fi

    echo -e "${GREEN}${SUCCESS_TAG}${NC} Cursor Agent CLI kurulumu tamamlandı!"
}

main() {
    install_cursor_cli "$@"
}

main "$@"
