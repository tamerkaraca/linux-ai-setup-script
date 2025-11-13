#!/bin/bash
set -euo pipefail

# Ortak yardımcı fonksiyonları yükle
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

declare -A REMOVE_SUPERGEMINI_TEXT_EN=(
    ["title"]="Starting SuperGemini removal process..."
    ["removed_pipx"]="SuperGemini has been removed from the pipx environment."
    ["removed_pipx_fail"]="Failed to remove SuperGemini from the pipx environment."
    ["not_found_pipx"]="SuperGemini not found in the pipx environment."
    ["pipx_not_installed"]="Pipx is not installed, proceeding with direct file cleanup."
    ["cleaned_path"]="[CLEANED]"
    ["remove_done"]="SuperGemini removal process completed."
    ["nothing_to_remove"]="No components found to remove for SuperGemini."
)

declare -A REMOVE_SUPERGEMINI_TEXT_TR=(
    ["title"]="SuperGemini kaldırma işlemi başlatılıyor..."
    ["removed_pipx"]="SuperGemini pipx ortamından kaldırıldı."
    ["removed_pipx_fail"]="SuperGemini pipx ortamından kaldırılamadı."
    ["not_found_pipx"]="SuperGemini pipx ortamında bulunamadı."
    ["pipx_not_installed"]="Pipx yüklü değil, doğrudan dosya temizliği yapılacak."
    ["cleaned_path"]="[TEMİZLENDİ]"
    ["remove_done"]="SuperGemini kaldırma işlemi tamamlandı."
    ["nothing_to_remove"]="SuperGemini için kaldırılacak bir bileşen bulunamadı."
)

remove_supergemini_text() {
    local key="$1"
    local default_value="${REMOVE_SUPERGEMINI_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${REMOVE_SUPERGEMINI_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

# SuperGemini kaldırma
remove_supergemini() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(remove_supergemini_text title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    local pipx_removed=false
    local paths_removed=false

    if command -v pipx &> /dev/null; then
        if pipx list 2>/dev/null | grep -q "SuperGemini"; then
            if pipx uninstall SuperGemini; then
                echo -e "${GREEN}${SUCCESS_TAG}${NC} $(remove_supergemini_text removed_pipx)"
                pipx_removed=true
            else
                echo -e "${RED}${ERROR_TAG}${NC} $(remove_supergemini_text removed_pipx_fail)"
            fi
        else
            echo -e "${YELLOW}${INFO_TAG}${NC} $(remove_supergemini_text not_found_pipx)"
        fi
    else
        echo -e "${YELLOW}${WARN_TAG}${NC} $(remove_supergemini_text pipx_not_installed)"
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
            echo -e "${GREEN}$(remove_supergemini_text cleaned_path)${NC} $path"
            paths_removed=true
        fi
    done

    hash -r 2>/dev/null || true

    if [ "$pipx_removed" = true ] || [ "$paths_removed" = true ]; then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(remove_supergemini_text remove_done)"
    else
        echo -e "${YELLOW}${INFO_TAG}${NC} $(remove_supergemini_text nothing_to_remove)"
    fi
}

# Ana kaldırma akışı
main() {
    remove_supergemini
}

main
