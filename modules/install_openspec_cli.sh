#!/bin/bash
set -euo pipefail

: "${OPEN_SPEC_REPO:=https://github.com/Fission-AI/OpenSpec.git}"

UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"

ensure_npm_available_local() {
    if command -v npm >/dev/null 2>&1; then
        return 0
    fi
    if bootstrap_node_runtime; then
        return 0
    fi
    echo -e "${RED}[HATA]${NC} npm komutu bulunamadı. Lütfen menüdeki 3. seçenekle Node.js kurulumunu tamamlayın."
    return 1
}

ensure_modern_npm_local() {
    local min_version="9.0.0"
    local current_version
    current_version=$(npm -v 2>/dev/null | tr -d '[:space:]')
    if [ -z "$current_version" ]; then
        echo -e "${RED}[HATA]${NC} npm sürümü okunamadı."
        return 1
    fi
    if [ "$(printf '%s\n%s\n' "$current_version" "$min_version" | sort -V | head -n1)" = "$min_version" ]; then
        return 0
    fi
    echo -e "${YELLOW}[BİLGİ]${NC} npm sürümü güncelleniyor (mevcut: ${current_version}, hedef: ${min_version}+)."
    if npm install -g npm@latest >/dev/null 2>&1; then
        echo -e "${GREEN}[BİLGİ]${NC} npm güncellendi: $(npm -v 2>/dev/null)"
        return 0
    fi
    echo -e "${RED}[HATA]${NC} npm güncellemesi başarısız oldu."
    return 1
}

install_openspec_cli() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} OpenSpec CLI kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    require_node_version 18 || return 1
    ensure_npm_available_local || return 1
    ensure_modern_npm_local || return 1

    if npm_install_global_with_fallback "@fission-ai/openspec" "OpenSpec CLI"; then
        echo -e "${GREEN}[BAŞARILI]${NC} OpenSpec CLI kuruldu: $(openspec --version 2>/dev/null)"
    else
        echo -e "${RED}[HATA]${NC} OpenSpec CLI kurulumu başarısız oldu."
        return 1
    fi
}

main() {
    install_openspec_cli "$@"
}

main "$@"
