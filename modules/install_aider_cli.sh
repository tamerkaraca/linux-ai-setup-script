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

ensure_aider_build_prereqs() {
    if [ -z "${PKG_MANAGER:-}" ]; then
        detect_package_manager
    fi

    local packages=()
    case "${PKG_MANAGER}" in
        apt)
            packages=(build-essential python3-dev python3-venv)
            ;;
        dnf|dnf5)
            packages=(gcc gcc-c++ make python3-devel)
            ;;
        yum)
            packages=(gcc gcc-c++ make python3-devel)
            ;;
        pacman)
            packages=(base-devel python)
            ;;
        *)
            return 0
            ;;
    esac

    local missing=()
    for pkg in "${packages[@]}"; do
        case "${PKG_MANAGER}" in
            apt)
                dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
                ;;
            dnf|dnf5|yum)
                rpm -q "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
                ;;
            pacman)
                pacman -Qi "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
                ;;
        esac
    done

    if [ ${#missing[@]} -eq 0 ]; then
        return 0
    fi

    local install_cmd="${INSTALL_CMD:-}"
    if [ -z "$install_cmd" ]; then
        case "${PKG_MANAGER}" in
            apt)
                install_cmd="sudo apt install -y"
                ;;
            dnf|dnf5)
                install_cmd="sudo ${PKG_MANAGER} install -y"
                ;;
            yum)
                install_cmd="sudo yum install -y"
                ;;
            pacman)
                install_cmd="sudo pacman -S --noconfirm"
                ;;
        esac
    fi

    if [ "${LANGUAGE:-en}" = "tr" ]; then
        echo -e "${YELLOW}${INFO_TAG}${NC} Aider için gerekli derleme paketleri yükleniyor: ${missing[*]}"
    else
        echo -e "${YELLOW}${INFO_TAG}${NC} Installing required build packages for Aider: ${missing[*]}"
    fi
    if [ -n "$install_cmd" ]; then
        $install_cmd "${missing[@]}" >/dev/null 2>&1 || $install_cmd "${missing[@]}"
    fi
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

    ensure_aider_build_prereqs || true

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
