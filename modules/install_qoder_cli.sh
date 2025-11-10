#!/bin/bash
set -euo pipefail

# Ortak yardımcı fonksiyonları yükle


ensure_npm_available() {
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}[HATA]${NC} npm bulunamadı. Lütfen Node.js ve npm'i kurun (Ana Menü -> 3. Node.js ve İlgili Araçları Kur)."
        return 1
    fi
}

install_npm_cli() {
    local display_name="$1"
    local npm_package="$2"
    local binary_name="$3"
    local dry_run="${4:-false}"

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} ${display_name} kurulumu https://docs.qoder.com/cli/quick-start rehberine göre başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if command -v "$binary_name" &> /dev/null; then
        echo -e "${GREEN}[BAŞARILI]${NC} ${display_name} zaten kurulu: $("$binary_name" --version 2>/dev/null)"
        return 0
    fi

    ensure_npm_available || return 1

    if [ "$dry_run" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} sudo npm install -g ${npm_package}"
    else
        echo -e "${YELLOW}[BİLGİ]${NC} ${display_name} npm ile kuruluyor..."
        if sudo npm install -g "$npm_package"; then
            echo -e "${GREEN}[BAŞARILI]${NC} ${display_name} kurulumu tamamlandı."
            reload_shell_configs silent
        else
            echo -e "${RED}[HATA]${NC} ${display_name} kurulumu başarısız oldu."
            return 1
        fi
    fi

    if [ "$dry_run" = true ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} Kurulum atlandı (dry-run)."
        return 0
    fi

    if command -v "$binary_name" &> /dev/null; then
        echo -e "${GREEN}[BAŞARILI]${NC} ${display_name} başarıyla kuruldu: $("$binary_name" --version 2>/dev/null)"
    else
        echo -e "${RED}[HATA]${NC} ${display_name} kuruldu ancak '${binary_name}' komutu bulunamadı. PATH ayarlarınızı kontrol edin."
        return 1
    fi
}

install_qoder_cli() {
    local dry_run="${1:-false}"
    install_npm_cli "Qoder CLI" "qoder" "qoder" "$dry_run"
}

install_coder_cli() {
    local dry_run="${1:-false}"
    install_npm_cli "Coder CLI" "@qoder/coder" "coder" "$dry_run"
}

main() {
    local interactive_mode="true"
    local target_cli="qoder"
    local dry_run="false"

    if [[ $# -gt 0 && "$1" != --* ]]; then
        interactive_mode="${1}"
        shift
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --tool)
                target_cli="${2:-qoder}"
                shift
                ;;
            --both|--all)
                target_cli="both"
                ;;
            --dry-run)
                dry_run="true"
                ;;
            *)
                echo -e "${YELLOW}[UYARI]${NC} Bilinmeyen argüman: $1"
                ;;
        esac
        shift || true
    done

    case "$target_cli" in
        qoder)
            install_qoder_cli "$dry_run"
            ;;
        coder)
            install_coder_cli "$dry_run"
            ;;
        both)
            install_qoder_cli "$dry_run"
            install_coder_cli "$dry_run"
            ;;
        *)
            echo -e "${RED}[HATA]${NC} Geçersiz --tool değeri: ${target_cli}. 'qoder', 'coder' veya 'both' kullanın."
            return 1
            ;;
    esac

    if [ "$interactive_mode" != "false" ]; then
        echo -e "\n${YELLOW}[BİLGİ]${NC} ${target_cli} CLI kurulum adımları tamamlandı."
    fi
}

main "$@"
