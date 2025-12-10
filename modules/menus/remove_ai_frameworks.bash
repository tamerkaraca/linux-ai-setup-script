#!/bin/bash

# Resolve the directory this script lives in so sources work regardless of CWD
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$script_dir/../utils/utils.bash"
platform_local="$script_dir/../utils/platform_detection.bash"

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

declare -A RM_TEXT_EN=(
    ["menu_title"]="AI Framework Removal Menu"
    ["option1"]="Remove SuperGemini Framework"
    ["option2"]="Remove SuperQwen Framework"
    ["option3"]="Remove SuperClaude Framework"
    ["optionA"]="Remove all AI frameworks"
    ["option0"]="Return to main menu"
    ["hint"]="Use commas for multiple selections (e.g., 1,3)."
    ["prompt"]="Your choice"
    ["returning"]="Returning to the main menu..."
    ["invalid"]="Invalid selection"
    ["continue_prompt"]="Remove another framework? (y/n) [n]: "
)

declare -A RM_TEXT_TR=(
    ["menu_title"]="AI Framework Kaldırma Menüsü"
    ["option1"]="SuperGemini Framework'ü kaldır"
    ["option2"]="SuperQwen Framework'ü kaldır"
    ["option3"]="SuperClaude Framework'ü kaldır"
    ["optionA"]="Tüm AI Frameworklerini kaldır"
    ["option0"]="Ana menüye dön"
    ["hint"]="Birden fazla seçim için virgülle ayırabilirsiniz (örn: 1,3)."
    ["prompt"]="Seçiminiz"
    ["returning"]="Ana menüye dönülüyor..."
    ["invalid"]="Geçersiz seçim"
    ["continue_prompt"]="Başka bir framework kaldırmak ister misiniz? (e/h) [h]: "
)

rm_text() {
    local key="$1"
    local default_value="${RM_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        echo "${RM_TEXT_TR[$key]:-$default_value}"
    else
        echo "$default_value"
    fi
}

# AI Framework Kaldırma menüsü
remove_ai_frameworks_menu() {
    while true; do
        clear
        print_heading_panel "$(rm_text menu_title)"
        log_info_detail "  1 - $(rm_text option1)"
        log_info_detail "  2 - $(rm_text option2)"
        log_info_detail "  3 - $(rm_text option3)"
        log_info_detail "  A - $(rm_text optionA)"
        log_info_detail "  0 - $(rm_text option0)"
        log_info_detail "$(rm_text hint)"

        read -r -p "$(rm_text prompt): " removal_choices </dev/tty
        if [ "$removal_choices" = "0" ] || [ -z "$removal_choices" ]; then
            log_info_detail "$(rm_text returning)"
            break
        fi

        local all_removed=false
        IFS=',' read -ra SELECTED_REMOVE <<< "$removal_choices"

        for choice in "${SELECTED_REMOVE[@]}"; do
            choice=$(echo "$choice" | tr -d ' ')
            case $choice in
                1) run_module "utils/remove_supergemini" ;;
                2) run_module "utils/remove_superqwen" ;;
                3) run_module "utils/remove_superclaude" ;;
                A|a) 
                    run_module "utils/remove_supergemini"
                    run_module "utils/remove_superqwen"
                    run_module "utils/remove_superclaude"
                    all_removed=true
                    ;;
                *) log_error_detail "$(rm_text invalid): $choice" ;;
            esac
        done

        if [ "$all_removed" = true ]; then
            break
        fi

        read -r -p "$(rm_text continue_prompt)" continue_choice </dev/tty
        if [[ ! "$continue_choice" =~ ^([eEyY])$ ]]; then
            break
        fi
    done
}

# Ana kaldırma akışı
main() {
    remove_ai_frameworks_menu
}

main