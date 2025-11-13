#!/bin/bash

# Ortak yardımcı fonksiyonları yükle


# SuperGemini kaldırma
remove_supergemini() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} SuperGemini kaldırma işlemi başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    local pipx_removed=false
    local paths_removed=false

    if command -v pipx &> /dev/null; then
        if pipx list 2>/dev/null | grep -q "SuperGemini"; then
            if pipx uninstall SuperGemini; then
                echo -e "${GREEN}${SUCCESS_TAG}${NC} SuperGemini pipx ortamından kaldırıldı."
                pipx_removed=true
            else
                echo -e "${RED}${ERROR_TAG}${NC} SuperGemini pipx ortamından kaldırılamadı."
            fi
        else
            echo -e "${YELLOW}${INFO_TAG}${NC} SuperGemini pipx ortamında bulunamadı."
        fi
    else
        echo -e "${YELLOW}${WARN_TAG}${NC} Pipx yüklü değil, doğrudan dosya temizliği yapılacak."
    fi

    local supergemini_paths=(
        "$HOME/.config/SuperGemini"
        "$HOME/.local/share/SuperGemini"
        "$HOME/.cache/SuperGemini"
        "$HOME/.SuperGemini"
        "$HOME/.supergemini"
        "$HOME/.gemini"
    )

    for path in "${supergemini_paths[@]}"; do
        if [ -e "$path" ]; then
            rm -rf "$path"
            echo -e "${GREEN}[TEMİZLENDİ]${NC} $path"
            paths_removed=true
        fi
    done

    hash -r 2>/dev/null || true

    if [ "$pipx_removed" = true ] || [ "$paths_removed" = true ]; then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} SuperGemini kaldırma işlemi tamamlandı."
    else
        echo -e "${YELLOW}${INFO_TAG}${NC} SuperGemini için kaldırılacak bir bileşen bulunamadı."
    fi
}

# Ana kaldırma akışı
main() {
    remove_supergemini
}

main
