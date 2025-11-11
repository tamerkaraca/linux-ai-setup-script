#!/bin/bash
set -euo pipefail

UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"
: "${NPM_LAST_INSTALL_PREFIX:=}"

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

ensure_npm_ready() {
    if ! command -v npm >/dev/null 2>&1; then
        echo -e "${RED}[HATA]${NC} npm bulunamadı. Lütfen önce Node.js modülünü çalıştırın."
        return 1
    fi
    return 0
}

ensure_opencode_binary() {
    local prefix="$1"
    local bin_path="${prefix}/bin/opencode"
    if [ -x "$bin_path" ]; then
        return 0
    fi

    local pkg_root="${prefix}/lib/node_modules/opencode-ai"
    local js_entry="${pkg_root}/bin/opencode.js"
    if [ -f "$js_entry" ]; then
        cat > "$bin_path" <<EOF
#!/bin/bash
NODE_BIN="\${NODE_BIN:-node}"
exec "\$NODE_BIN" "$js_entry" "\$@"
EOF
        chmod +x "$bin_path"
        ensure_path_contains_dir "${prefix}/bin" "OpenCode CLI shim"
        return 0
    fi

    return 1
}

install_opencode_cli() {
    local interactive_mode=${1:-true}
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} OpenCode CLI kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    require_node_version 20 "OpenCode CLI" || return 1
    ensure_npm_ready || return 1

    if ! npm_install_global_with_fallback "opencode-ai" "OpenCode CLI" true; then
        echo -e "${RED}[HATA]${NC} OpenCode CLI npm paketinin kurulumu başarısız oldu."
        return 1
    fi

    local install_prefix="${NPM_LAST_INSTALL_PREFIX:-$(npm_prepare_user_prefix)}"
    ensure_opencode_binary "$install_prefix" || echo -e "${YELLOW}[UYARI]${NC} OpenCode binary dosyası oluşturulamadı; npm prefixinizi kontrol edin."

    if ! command -v opencode >/dev/null 2>&1 && [ -x "${install_prefix}/bin/opencode" ]; then
        ensure_path_contains_dir "${install_prefix}/bin" "OpenCode CLI"
    fi

    if command -v opencode >/dev/null 2>&1; then
        echo -e "${GREEN}[BAŞARILI]${NC} OpenCode CLI sürümü: $(opencode --version)"
    else
        echo -e "${RED}[HATA]${NC} 'opencode' komutu bulunamadı. Terminalinizi yeniden başlatın veya PATH ayarlarınızı kontrol edin."
        return 1
    fi

    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}[BİLGİ]${NC} Şimdi OpenCode CLI'ya giriş yapmanız gerekiyor."
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen 'opencode login' komutunu çalıştırın."
        echo -e "${YELLOW}[BİLGİ]${NC} Oturum açma tamamlandığında buraya dönün ve Enter'a basın.\n"

        opencode login </dev/tty >/dev/tty 2>&1 || echo -e "${YELLOW}[BİLGİ]${NC} Manuel oturum açma gerekebilir."

        echo -e "\n${YELLOW}[BİLGİ]${NC} Oturum açma işlemi tamamlandı mı? (Enter'a basarak devam edin)"
        read -r -p "Devam etmek için Enter'a basın..." </dev/tty
    else
        echo -e "\n${YELLOW}[BİLGİ]${NC} 'Tümünü Kur' modunda kimlik doğrulama atlandı."
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen daha sonra manuel olarak '${GREEN}opencode login${NC}' komutunu çalıştırın."
    fi

    echo -e "${GREEN}[BAŞARILI]${NC} OpenCode CLI kurulumu tamamlandı!"
}

main() {
    install_opencode_cli "$@"
}

main "$@"
