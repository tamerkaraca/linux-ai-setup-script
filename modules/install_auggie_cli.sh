#!/bin/bash
set -euo pipefail

: "${AUGGIE_NPM_PACKAGE:=@augmentcode/auggie}"
: "${AUGGIE_MIN_NODE_VERSION:=22}"
: "${AUGGIE_DOC_URL:=https://docs.augmentcode.com/cli/overview}"

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

ensure_auggie_npm_available() {
    if command -v npm >/dev/null 2>&1; then
        return 0
    fi
    if bootstrap_node_runtime; then
        return 0
    fi
    echo -e "${RED}${ERROR_TAG}${NC} npm komutu bulunamadı. Lütfen ana menüdeki '3 - Node.js araçları' seçeneğini çalıştırarak Node.js kurun."
    return 1
}

install_auggie_cli() {
    local interactive_mode="true"
    local dry_run="false"
    local package_spec="${AUGGIE_NPM_PACKAGE}"

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
    echo -e "${YELLOW}${INFO_TAG}${NC} Auggie CLI kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if [ "$dry_run" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Node.js >= ${AUGGIE_MIN_NODE_VERSION} doğrulanacak."
        echo -e "${YELLOW}[DRY-RUN]${NC} npm install -g ${package_spec}"
        echo -e "${YELLOW}${INFO_TAG}${NC} Dry-run modunda kimlik doğrulama adımları atlanır."
        return 0
    fi

    require_node_version "$AUGGIE_MIN_NODE_VERSION" "Auggie CLI" || return 1
    ensure_auggie_npm_available || return 1

    echo -e "${YELLOW}${INFO_TAG}${NC} Auggie CLI npm paketinin kurulumu başlatılıyor..."
    if ! npm_install_global_with_fallback "$package_spec" "Auggie CLI"; then
        echo -e "${RED}${ERROR_TAG}${NC} Auggie CLI kurulumu başarısız oldu. Paket: ${package_spec}"
        return 1
    fi

    if [ -n "${NPM_LAST_INSTALL_PREFIX:-}" ]; then
        ensure_path_contains_dir "${NPM_LAST_INSTALL_PREFIX}/bin" "npm user prefix"
    fi
    reload_shell_configs silent
    hash -r 2>/dev/null || true

    if ! command -v auggie >/dev/null 2>&1; then
        echo -e "${RED}${ERROR_TAG}${NC} 'auggie' komutu bulunamadı. PATH ayarlarınızı kontrol edin."
        return 1
    fi

    echo -e "${GREEN}${SUCCESS_TAG}${NC} Auggie CLI sürümü: $(auggie --version 2>/dev/null || echo 'sürüm bilgisi alınamadı')"

    cat <<EOF
${CYAN}${INFO_TAG}${NC} Auggie CLI, depodaki kodu anlayıp güvenli değişiklikler yapabilmeniz için şu özellikleri sunar:
  • ${GREEN}auggie login${NC} → tarayıcı tabanlı oturum açma
  • ${GREEN}auggie "prompt"${NC} → proje dizininde interaktif oturum
  • ${GREEN}auggie --print "..."${NC} → CI çıktısı (yalnızca son mesaj)
  • ${GREEN}.augment/commands/*.md${NC} → slash komutları için tekrar kullanılabilir şablonlar
EOF

    if [ "$interactive_mode" = true ]; then
        if [ -r /dev/tty ] && [ -w /dev/tty ]; then
            echo -e "\n${YELLOW}${INFO_TAG}${NC} Augment hesabınızla giriş yapmak için '${GREEN}auggie login${NC}' komutunu çalıştırıyoruz..."
            if ! auggie login </dev/tty >/dev/tty 2>&1; then
                echo -e "${YELLOW}${WARN_TAG}${NC} 'auggie login' komutu başarısız oldu. Gerekirse manuel olarak tekrar çalıştırın."
            fi
        else
            echo -e "\n${YELLOW}${WARN_TAG}${NC} TTY erişimi yok; lütfen '${GREEN}auggie login${NC}' komutunu manuel olarak çalıştırın."
        fi
        read -r -p "Devam etmek için Enter'a basın..." </dev/tty || true
    else
        echo -e "\n${YELLOW}${INFO_TAG}${NC} Toplu modda kimlik doğrulama atlandı. Kurulum sonrası '${GREEN}auggie login${NC}' komutunu çalıştırmayı unutmayın."
    fi

    echo -e "${GREEN}${SUCCESS_TAG}${NC} Auggie CLI kurulumu tamamlandı! Detaylı rehber: ${AUGGIE_DOC_URL}"
}

main() {
    install_auggie_cli "$@"
}

main "$@"
