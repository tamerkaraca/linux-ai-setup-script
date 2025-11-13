#!/bin/bash
set -euo pipefail

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

install_nvm() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} NVM kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
        if [ -f "$rc_file" ] && ! grep -q 'NVM_DIR' "$rc_file"; then
            {
                echo ""
                echo "# NVM PATH (linux-ai-setup-script)"
                echo "export NVM_DIR=\"$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")\""
                echo "[ -s \"$NVM_DIR/nvm.sh\" ] && \\. \"$NVM_DIR/nvm.sh\""
            } >> "$rc_file"
        fi
    done

    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    echo -e "${YELLOW}[BİLGİ]${NC} Node.js LTS sürümü kuruluyor..."
    (
        set +u
        nvm install --lts
        nvm use --lts >/dev/null
    )

    echo -e "\n${GREEN}[BAŞARILI]${NC} Node.js sürümü: $(node -v)"
    echo -e "${GREEN}[BAŞARILI]${NC} npm sürümü: $(npm -v)"
}

install_bun() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Bun.js kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    echo -e "${YELLOW}[BİLGİ]${NC} Bun resmi scripti ile kuruluyor..."
    curl -fsSL https://bun.sh/install | bash

    export BUN_INSTALL="$HOME/.bun"
    ensure_path_contains_dir "$BUN_INSTALL/bin" "bun runtime"

    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
        if [ -f "$rc_file" ] && ! grep -q '.bun/bin' "$rc_file"; then
            {
                echo ""
                echo "# Bun PATH (linux-ai-setup-script)"
                echo "export BUN_INSTALL=\"$HOME/.bun\""
                echo "export PATH=\"$BUN_INSTALL/bin:\$PATH\""
            } >> "$rc_file"
        fi
    done

    reload_shell_configs silent

    if command -v bun >/dev/null 2>&1; then
        echo -e "${GREEN}[BAŞARILI]${NC} Bun.js kuruldu: $(bun --version)"
    else
        echo -e "${RED}[HATA]${NC} Bun.js kurulumu başarısız oldu."
        return 1
    fi
}

main() {
    local install_node="true"
    local install_bun_flag="true"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --node-only)
                install_bun_flag="false"
                ;;
            --bun-only)
                install_node="false"
                ;;
            --skip-bun)
                install_bun_flag="false"
                ;;
            *)
                echo -e "${YELLOW}[UYARI]${NC} Bilinmeyen argüman: $1"
                ;;
        esac
        shift || true
    done

    if [ "$install_node" = "true" ]; then
        install_nvm
    fi

    if [ "$install_bun_flag" = "true" ]; then
        install_bun
    fi

    reload_shell_configs

    local rc_files=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.profile")
    for rc_file in "${rc_files[@]}"; do
        if [ -f "$rc_file" ]; then
            echo -e "${YELLOW}[BİLGİ]${NC} Güncellenen ortam değişkenleri uygulanıyor: source ${rc_file}"
            # shellcheck source=/dev/null
            . "$rc_file"
        fi
    done

    echo -e "${GREEN}[BAŞARILI]${NC} Node.js ve ilgili araçların kurulumu tamamlandı!"
}

main "$@"
