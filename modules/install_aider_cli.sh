#!/bin/bash
set -euo pipefail

: "${AIDER_MIN_NODE_VERSION:=18}"

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

ensure_pipx_available() {
    if command -v pipx >/dev/null 2>&1; then
        return 0
    fi
    echo -e "${YELLOW}${WARN_TAG}${NC} Aider için Pipx gerekli; kuruluma başlanıyor..."
    if ! command -v python3 >/dev/null 2>&1; then
        echo -e "${YELLOW}${WARN_TAG}${NC} Python bulunamadı, Python kurulumu tetikleniyor..."
        install_python
    fi
    install_pipx
}

install_aider_cli() {
    local interactive_mode="true"
    local dry_run="false"

    if [[ $# -gt 0 && "$1" != --* ]]; then
        interactive_mode="$1"
        shift
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                dry_run="true"
                ;;
            *)
                echo -e "${YELLOW}${WARN_TAG}${NC} Bilinmeyen argüman: $1"
                ;;
        esac
        shift || true
    done

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} Aider CLI kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if [ "$dry_run" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Node.js >= ${AIDER_MIN_NODE_VERSION} doğrulanacak ve pipx install aider-chat komutu çalıştırılacak."
        echo -e "${YELLOW}${INFO_TAG}${NC} Dry-run modunda gerçek kurulum ve oturum açma adımları atlanır."
        return 0
    fi

    require_node_version "$AIDER_MIN_NODE_VERSION" "Aider CLI" || return 1
    ensure_pipx_available || {
        echo -e "${RED}${ERROR_TAG}${NC} Pipx kurulamadı; Aider CLI yüklenemiyor."
        return 1
    }

    echo -e "${YELLOW}${INFO_TAG}${NC} pipx ile 'aider-chat' paketi kuruluyor..."
    if ! pipx install aider-chat >/dev/null 2>&1 && ! pipx install aider-chat; then
        echo -e "${RED}${ERROR_TAG}${NC} Aider CLI kurulumu başarısız oldu."
        return 1
    fi

    reload_shell_configs silent
    hash -r 2>/dev/null || true

    if ! command -v aider >/dev/null 2>&1; then
        echo -e "${RED}${ERROR_TAG}${NC} 'aider' komutu bulunamadı. PATH ayarlarınızı kontrol edin."
        return 1
    fi

    echo -e "${GREEN}${SUCCESS_TAG}${NC} Aider CLI sürümü: $(aider --version 2>/dev/null)"

    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}${INFO_TAG}${NC} Aider, desteklediğiniz sağlayıcıya göre API anahtarı ister."
        echo -e "${CYAN}  export OPENAI_API_KEY=\"...\"${NC} veya ${CYAN}AIDER_ANTHROPIC_API_KEY${NC} gibi değişkenleri ayarlayın."
        read -r -p "Bilgileri ayarladıktan sonra devam etmek için Enter'a basın..." </dev/tty || true
    else
        echo -e "\n${YELLOW}${INFO_TAG}${NC} Toplu kurulumda kimlik doğrulama ve anahtarlar atlandı."
        echo -e "${YELLOW}${INFO_TAG}${NC} Lütfen '${GREEN}aider --help${NC}' komutunu çalıştırmadan önce gereken API anahtarlarını export edin."
    fi

    echo -e "${GREEN}${SUCCESS_TAG}${NC} Aider CLI kurulumu tamamlandı!"
}

main() {
    install_aider_cli "$@"
}

main "$@"
