#!/bin/bash
set -euo pipefail

# Resolve the directory this script lives in so sources work regardless of CWD
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$script_dir/utils.bash"
platform_local="$script_dir/platform_detection.bash"

# Prefer local direct source (relative to this file). If not available, fall back to
# the setup-provided `source_module` helper when running under the main `setup` script.
if [ -f "$utils_local" ]; then
    # shellcheck source=/dev/null
    source "$utils_local"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/utils.bash" "modules/utils/utils.bash"
else
    echo "[HATA/ERROR] utils.bash yüklenemedi / Unable to load utils.bash (tried $utils_local)" >&2
    exit 1
fi

if [ -f "$platform_local" ]; then
    # shellcheck source=/dev/null
    source "$platform_local"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/platform_detection.bash" "modules/utils/platform_detection.bash"
fi

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

declare -A REMOVE_SUPERQWEN_TEXT_EN=(
    ["title"]="Starting SuperQwen removal process..."
    ["removed_pipx"]="SuperQwen has been removed from the pipx environment."
    ["removed_pipx_fail"]="Failed to remove SuperQwen from the pipx environment."
    ["not_found_pipx"]="SuperQwen not found in the pipx environment."
    ["pipx_not_installed"]="Pipx is not installed, proceeding with direct file cleanup."
    ["cleaned_path"]="[CLEANED]"
    ["remove_done"]="SuperQwen removal process completed."
    ["nothing_to_remove"]="No components found to remove for SuperQwen."
)

declare -A REMOVE_SUPERQWEN_TEXT_TR=(
    ["title"]="SuperQwen kaldırma işlemi başlatılıyor..."
    ["removed_pipx"]="SuperQwen pipx ortamından kaldırıldı."
    ["removed_pipx_fail"]="SuperQwen pipx ortamından kaldırılamadı."
    ["not_found_pipx"]="SuperQwen pipx ortamında bulunamadı."
    ["pipx_not_installed"]="Pipx yüklü değil, doğrudan dosya temizliği yapılacak."
    ["cleaned_path"]="[TEMİZLENDİ]"
    ["remove_done"]="SuperQwen kaldırma işlemi tamamlandı."
    ["nothing_to_remove"]="SuperQwen için kaldırılacak bir bileşen bulunamadı."
)

remove_superqwen_text() {
    local key="$1"
    local default_value="${REMOVE_SUPERQWEN_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${REMOVE_SUPERQWEN_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

# SuperQwen kaldırma
remove_superqwen() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(remove_superqwen_text title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    local pipx_removed=false
    local paths_removed=false

    if command -v pipx &> /dev/null; then
        if pipx list 2>/dev/null | grep -q "SuperQwen"; then
            if pipx uninstall SuperQwen; then
                echo -e "${GREEN}${SUCCESS_TAG}${NC} $(remove_superqwen_text removed_pipx)"
                pipx_removed=true
            else
                echo -e "${RED}${ERROR_TAG}${NC} $(remove_superqwen_text removed_pipx_fail)"
            fi
        else
            echo -e "${YELLOW}${INFO_TAG}${NC} $(remove_superqwen_text not_found_pipx)"
        fi
    else
        echo -e "${YELLOW}${WARN_TAG}${NC} $(remove_superqwen_text pipx_not_installed)"
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
            echo -e "${GREEN}$(remove_superqwen_text cleaned_path)${NC} $path"
            paths_removed=true
        fi
    done

    hash -r 2>/dev/null || true

    if [ "$pipx_removed" = true ] || [ "$paths_removed" = true ]; then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(remove_superqwen_text remove_done)"
    else
        echo -e "${YELLOW}${INFO_TAG}${NC} $(remove_superqwen_text nothing_to_remove)"
    fi
}

# Ana kaldırma akışı
main() {
    remove_superqwen
}

main
