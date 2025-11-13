#!/bin/bash
set -euo pipefail

: "${KILOCODE_NPM_PACKAGE:=@kilocode/cli}"
: "${KILOCODE_MIN_NODE_VERSION:=18}"
: "${KILOCODE_DOC_URL:=https://kilocode.ai/docs/cli}"

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

ensure_kilocode_npm_available() {
    if command -v npm >/dev/null 2>&1; then
        return 0
    fi
    if bootstrap_node_runtime; then
        return 0
    fi
    echo -e "${RED}${ERROR_TAG}${NC} npm komutu bulunamadı. Lütfen ana menüdeki '3 - Node.js araçları' seçeneğini çalıştırarak Node.js kurun."
    return 1
}

install_kilocode_cli() {
    local interactive_mode="true"
    local dry_run="false"
    local package_spec="${KILOCODE_NPM_PACKAGE}"

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
    echo -e "${YELLOW}${INFO_TAG}${NC} Kilocode CLI kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if [ "$dry_run" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Node.js >= ${KILOCODE_MIN_NODE_VERSION} doğrulanacak."
        echo -e "${YELLOW}[DRY-RUN]${NC} npm install -g ${package_spec}"
        echo -e "${YELLOW}${INFO_TAG}${NC} Dry-run modunda kimlik doğrulama veya konfigürasyon çağrılmaz."
        return 0
    fi

    require_node_version "$KILOCODE_MIN_NODE_VERSION" "Kilocode CLI" || return 1
    ensure_kilocode_npm_available || return 1

    echo -e "${YELLOW}${INFO_TAG}${NC} Kilocode CLI npm paketinin kurulumu başlatılıyor..."
    if ! npm_install_global_with_fallback "$package_spec" "Kilocode CLI"; then
        echo -e "${RED}${ERROR_TAG}${NC} Kilocode CLI kurulumu başarısız oldu. Paket: ${package_spec}"
        return 1
    fi

    if [ -n "${NPM_LAST_INSTALL_PREFIX:-}" ]; then
        ensure_path_contains_dir "${NPM_LAST_INSTALL_PREFIX}/bin" "npm user prefix"
    fi
    reload_shell_configs silent
    hash -r 2>/dev/null || true

    if ! command -v kilocode >/dev/null 2>&1; then
        echo -e "${RED}${ERROR_TAG}${NC} 'kilocode' komutu bulunamadı. PATH ayarlarınızı kontrol edin."
        return 1
    fi

    echo -e "${GREEN}${SUCCESS_TAG}${NC} Kilocode CLI sürümü: $(kilocode --version 2>/dev/null || echo 'sürüm bilgisi alınamadı')"

    echo -e "\n${CYAN}${INFO_TAG}${NC} Kilocode CLI, aynı anda birden fazla ajanın çalışabildiği modları içerir:"
    echo -e "  • ${GREEN}kilocode --mode architect${NC} → kapsam belirleme ve planlama"
    echo -e "  • ${GREEN}kilocode --mode debug${NC} → hata izleme"
    echo -e "  • ${GREEN}kilocode --auto \"Build feature X\"${NC} → CI/CD veya başsız çalıştırma"
    echo -e "  • ${GREEN}kilocode config${NC} → sağlayıcı anahtarlarını (OpenRouter, Vercel Gateway vb.) yapılandırma"

    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}${INFO_TAG}${NC} Sağlayıcı anahtarlarını tanımlamak için '${GREEN}kilocode config${NC}' komutunu çalıştırın."
        if [ -r /dev/tty ] && [ -w /dev/tty ]; then
            read -r -p "Kilocode yapılandırmasını şimdi başlatmak ister misiniz? (e/h) [h]: " launch_config </dev/tty || true
            if [[ "$launch_config" =~ ^[eE]$ ]]; then
                kilocode config </dev/tty >/dev/tty 2>&1 || echo -e "${YELLOW}${WARN_TAG}${NC} 'kilocode config' çalıştırılırken hata oluştu. Gerekirse manuel olarak komutu tekrar çalıştırın."
            else
                echo -e "${YELLOW}${INFO_TAG}${NC} 'kilocode config' adımını daha sonra manuel olarak çalıştırabilirsiniz."
            fi
        else
            echo -e "${YELLOW}${WARN_TAG}${NC} TTY erişimi yok; 'kilocode config' komutunu manuel olarak çalıştırın."
        fi
        read -r -p "Devam etmek için Enter'a basın..." </dev/tty || true
    else
        echo -e "\n${YELLOW}${INFO_TAG}${NC} Toplu kurulum modunda konfigürasyon adımları atlandı."
        echo -e "${YELLOW}${NOTE_TAG}${NC} Kurulum sonrası '${GREEN}kilocode config${NC}' ve '${GREEN}kilocode --mode architect${NC}' komutlarını manuel çalıştırmayı unutmayın."
    fi

    echo -e "${GREEN}${SUCCESS_TAG}${NC} Kilocode CLI kurulumu tamamlandı! Detaylı rehber: ${KILOCODE_DOC_URL}"
}

main() {
    install_kilocode_cli "$@"
}

main "$@"
