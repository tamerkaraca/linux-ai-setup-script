#!/bin/bash
set -euo pipefail

: "${OPEN_SPEC_REPO:=https://github.com/Fission-AI/OpenSpec.git}"

UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"

install_openspec_cli() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} OpenSpec CLI kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    require_node_version 18 || return 1
    ensure_npm_available || return 1
    ensure_modern_npm false || return 1

    if npm_install_global_with_fallback "@fission-ai/openspec" "OpenSpec CLI"; then
        echo -e "${GREEN}[BAŞARILI]${NC} OpenSpec CLI kuruldu: $(openspec --version 2>/dev/null)"
    else
        echo -e "${RED}[HATA]${NC} OpenSpec CLI kurulumu başarısız oldu."
        return 1
    fi
}

install_claude_agents() {
    run_module "install_claude_agents"
}

install_openspec_suite() {
    install_openspec_cli || return 1
    install_claude_agents || {
        echo -e "${YELLOW}[UYARI]${NC} Agents kurulumu başarısız oldu; CLI kurulu durumda."
        return 1
    }
    echo -e "${GREEN}[BAŞARILI]${NC} OpenSpec CLI + Contains Studio ajanları yüklendi."
}

main() {
    install_openspec_suite "$@"
}

main "$@"
