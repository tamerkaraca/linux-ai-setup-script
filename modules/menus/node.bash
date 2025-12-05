#!/bin/bash
set -euo pipefail

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
    echo "[ERROR] Unable to load utils.bash (tried $utils_local)" >&2
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

declare -A NODE_MENU_TEXT_EN=(
    ["node_menu_title"]="Node.js Tooling Menu"
    ["node_menu_subtitle"]="Select components to install."
    ["node_option1"]="Node.js via NVM (LTS)"
    ["node_option2"]="Bun Runtime"
    ["node_option3"]="Node CLI Extras (pnpm, yarn)"
    ["node_optionA"]="Install All Components"
    ["node_option0"]="Return to Main Menu"
    ["menu_multi_hint"]="You can make multiple selections with commas (e.g., 1,2)."
    ["prompt_choice"]="Your choice"
    ["warning_no_selection"]="No selection made. Please try again."
    ["info_returning"]="Returning to the main menu..."
    ["warning_invalid_choice"]="Invalid choice"
    ["prompt_press_enter"]="Press Enter to continue..."
)

declare -A NODE_MENU_TEXT_TR=(
    ["node_menu_title"]="Node.js Araçları Menüsü"
    ["node_menu_subtitle"]="Kurulacak bileşenleri seçin."
    ["node_option1"]="Node.js (NVM üzerinden, LTS)"
    ["node_option2"]="Bun Runtime"
    ["node_option3"]="Node CLI Ekstraları (pnpm, yarn)"
    ["node_optionA"]="Tüm Bileşenleri Kur"
    ["node_option0"]="Ana Menüye Dön"
    ["menu_multi_hint"]="Birden fazla seçim için virgül kullanabilirsiniz (örn: 1,2)."
    ["prompt_choice"]="Seçiminiz"
    ["warning_no_selection"]="Hiçbir seçim yapılmadı. Lütfen tekrar deneyin."
    ["info_returning"]="Ana menüye dönülüyor..."
    ["warning_invalid_choice"]="Geçersiz seçim"
    ["prompt_press_enter"]="Devam etmek için Enter'a basın..."
)

node_menu_text() {
    local key="$1"
    local default_value="${NODE_MENU_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${NODE_MENU_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}



show_node_menu() {
    clear
    print_heading_panel "$(node_menu_text node_menu_title)"
    log_info_detail "$(node_menu_text node_menu_subtitle)"
    log_info_detail "  1 - $(node_menu_text node_option1)"
    log_info_detail "  2 - $(node_menu_text node_option2)"
    log_info_detail "  3 - $(node_menu_text node_option3)"
    log_info_detail "  A - $(node_menu_text node_optionA)"
    log_info_detail "  0 - $(node_menu_text node_option0)"
    log_info_detail "$(node_menu_text menu_multi_hint)"
}

run_node_choice() {
    local option="$1"
    case "$option" in
        1)
            run_module "utils/nodejs_tools" "--node-only"
            ;; 
        2)
            run_module "utils/nodejs_tools" "--bun-only"
            ;; 
        3)
            run_module "utils/nodejs_tools" "--extras-only"
            ;; 
        A)
            run_module "utils/nodejs_tools"
            ;; 
        *)
            log_warn_detail "$(node_menu_text warning_invalid_choice): $option"
            ;; 
    esac
}

main() {
    local auto_run="${1:-}"
    if [ "$auto_run" = "all" ]; then
        run_node_choice "A"
        return
    fi

    while true; do
        show_node_menu
        read -r -p "$(node_menu_text prompt_choice): " selection </dev/tty
        if [ -z "$(echo "$selection" | tr -d '[:space:]')" ]; then
            log_warn_detail "$(node_menu_text warning_no_selection)"
            sleep 1
            continue
        fi

        if [ "$selection" = "0" ]; then
            log_info_detail "$(node_menu_text info_returning)"
            break
        fi

        local batch_context=false
        IFS=',' read -ra choices <<< "$selection"
        [ "${#choices[@]}" -gt 1 ] && batch_context=true

        for raw in "${choices[@]}"; do
            local choice
            choice="$(echo "$raw" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')"
            [ -z "$choice" ] && continue
            if [ "$choice" = "0" ]; then
                batch_context=false
                break
            fi
            run_node_choice "$choice"
        done

        if [ "$batch_context" = false ]; then
            read -r -p "$(node_menu_text prompt_press_enter)" _tmp </dev/tty || true
        fi
    done
}

main "$@"