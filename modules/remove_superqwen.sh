#!/bin/bash

# Ortak yardımcı fonksiyonları yükle


# SuperQwen kaldırma
remove_superqwen() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} SuperQwen kaldırma işlemi başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    local pipx_removed=false
    local paths_removed=false

    if command -v pipx &> /dev/null; then
        if pipx list 2>/dev/null | grep -q "SuperQwen"; then
            if pipx uninstall SuperQwen; then
                echo -e "${GREEN}${SUCCESS_TAG}${NC} SuperQwen pipx ortamından kaldırıldı."
                pipx_removed=true
            else
                echo -e "${RED}${ERROR_TAG}${NC} SuperQwen pipx ortamından kaldırılamadı."
            fi
        else
            echo -e "${YELLOW}${INFO_TAG}${NC} SuperQwen pipx ortamında bulunamadı."
        fi
    else
        echo -e "${YELLOW}${WARN_TAG}${NC} Pipx yüklü değil, doğrudan dosya temizliği yapılacak."
    fi

    local superqwen_paths=(
        "$HOME/.config/SuperQwen"
        "$HOME/.local/share/SuperQwen"
        "$HOME/.cache/SuperQwen"
        "$HOME/.SuperQwen"
        "$HOME/.superqwen"
        "$HOME/.qwen"
    )

    for path in "${superqwen_paths[@]}"; do
        if [ -e "$path" ]; then
            rm -rf "$path"
            echo -e "${GREEN}[TEMİZLENDİ]${NC} $path"
            paths_removed=true
        fi
    done

    hash -r 2>/dev/null || true

    if [ "$pipx_removed" = true ] || [ "$paths_removed" = true ]; then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} SuperQwen kaldırma işlemi tamamlandı."
    else
        echo -e "${YELLOW}${INFO_TAG}${NC} SuperQwen için kaldırılacak bir bileşen bulunamadı."
    fi
}

# Ana kaldırma akışı
main() {
    remove_superqwen
}

main
