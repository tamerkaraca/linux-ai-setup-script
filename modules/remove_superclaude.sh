#!/bin/bash

# Ortak yardımcı fonksiyonları yükle
# shellcheck source=/dev/null
source "/mnt/d/ai/modules/utils.sh"

# SuperClaude kaldırma
remove_superclaude() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} SuperClaude kaldırma işlemi başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    detect_package_manager # Ensure PKG_MANAGER, INSTALL_CMD are set

    local pipx_removed=false
    local paths_removed=false

    if command -v pipx &> /dev/null; then
        if pipx list 2>/dev/null | grep -q "SuperClaude"; then
            if pipx uninstall SuperClaude; then
                echo -e "${GREEN}[BAŞARILI]${NC} SuperClaude pipx ortamından kaldırıldı."
                pipx_removed=true
            else
                echo -e "${RED}[HATA]${NC} SuperClaude pipx ortamından kaldırılamadı."
            fi
        else
            echo -e "${YELLOW}[BİLGİ]${NC} SuperClaude pipx ortamında bulunamadı."
        fi
    else
        echo -e "${YELLOW}[UYARI]${NC} Pipx yüklü değil, doğrudan dosya temizliği yapılacak."
    fi

    local superclaude_paths=(
        "$HOME/.config/SuperClaude"
        "$HOME/.local/share/SuperClaude"
        "$HOME/.cache/SuperClaude"
        "$HOME/.SuperClaude"
        "$HOME/.superclaude"
        "$HOME/.claude"
    )

    for path in "${superclaude_paths[@]}"; do
        if [ -e "$path" ]; then
            rm -rf "$path"
            echo -e "${GREEN}[TEMİZLENDİ]${NC} $path"
            paths_removed=true
        fi
    done

    hash -r 2>/dev/null || true

    if [ "$pipx_removed" = true ] || [ "$paths_removed" = true ]; then
        echo -e "${GREEN}[BAŞARILI]${NC} SuperClaude kaldırma işlemi tamamlandı."
    else
        echo -e "${YELLOW}[BİLGİ]${NC} SuperClaude için kaldırılacak bir bileşen bulunamadı."
    fi
}

# Ana kaldırma akışı
main() {
    remove_superclaude
}

main
