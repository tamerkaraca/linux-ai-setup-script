#!/bin/bash
# Windows CRLF düzeltme kontrolü
if [ -f "$0" ]; then
    if file "$0" | grep -q "CRLF"; then
        if command -v dos2unix &> /dev/null; then dos2unix "$0"; elif command -v sed &> /dev/null; then sed -i 's/\r$//' "$0"; fi
        exec bash "$0" "$@"
    fi
fi
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

: "${RED:=\033[0;31m}"
: "${GREEN:=\033[0;32m}"
: "${YELLOW:=\033[1;33m}"
: "${BLUE:=\033[0;34m}"
: "${CYAN:=\033[0;36m}"
: "${NC:=\033[0m}"

declare -A AUX_MENU_TEXT_EN=(
    ["menu_title"]="Auxiliary AI Tools & Agents Menu"
    ["option1"]="OpenSpec CLI (Spec-Driven Development)"
    ["option2"]="specify-cli (from github/spec-kit)"
    ["option3"]="Contains Studio Agents (for Claude)"
    ["option4"]="Wes Hobson Agents (for Claude)"
    ["option5"]="OpenAgents (darrenhinde/OpenAgents)"
    ["optionA"]="Install All Auxiliary Tools"
    ["option_return"]="Return to Main Menu"
    ["menu_hint"]="You can make multiple selections with commas (e.g., 1,3)."
    ["prompt_choice"]="Your choice"
    ["info_returning"]="Returning to the main menu..."
    ["warning_invalid_choice"]="Invalid choice"
    ["prompt_continue"]="Install another auxiliary tool? (y/n) [n]: "
)

declare -A AUX_MENU_TEXT_TR=(
    ["menu_title"]="Yardımcı AI Araçları ve Ajanları Menüsü"
    ["option1"]="OpenSpec CLI (Spesifikasyon Odaklı Geliştirme)"
    ["option2"]="specify-cli (github/spec-kit'ten)"
    ["option3"]="Contains Studio Agents (Claude için)"
    ["option4"]="Wes Hobson Agents (Claude için)"
    ["option5"]="OpenAgents (darrenhinde/OpenAgents)"
    ["optionA"]="Tüm Yardımcı Araçları Kur"
    ["option_return"]="Ana Menüye Dön"
    ["menu_hint"]="Birden fazla seçim için virgül kullanabilirsiniz (örn: 1,3)."
    ["prompt_choice"]="Seçiminiz"
    ["info_returning"]="Ana menüye dönülüyor..."
    ["warning_invalid_choice"]="Geçersiz seçim"
    ["prompt_continue"]="Başka bir yardımcı araç kurmak ister misiniz? (e/h) [h]: "
)

aux_menu_text() {
    local key="$1"
    local default_value="${AUX_MENU_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${AUX_MENU_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

install_aux_tools_menu() {
    local install_all="${1:-""}"

    while true; do
        local choices=""
        if [ -z "$install_all" ]; then
            clear
            print_heading_panel "$(aux_menu_text menu_title)"
            log_info_detail "  1 - $(aux_menu_text option1)"
            log_info_detail "  2 - $(aux_menu_text option2)"
            log_info_detail "  3 - $(aux_menu_text option3)"
            log_info_detail "  4 - $(aux_menu_text option4)"
            log_info_detail "  5 - $(aux_menu_text option5)"
            log_info_detail "  A - $(aux_menu_text optionA)"
            log_info_detail "  0 - $(aux_menu_text option_return)"
            log_info_detail "$(aux_menu_text menu_hint)"

            read -r -p "$(aux_menu_text prompt_choice): " choices </dev/tty
            if [ "$choices" = "0" ] || [ -z "$choices" ]; then
                log_info_detail "$(aux_menu_text info_returning)"
                break
            fi
        else
            choices="A" # Install all
        fi

        local all_installed=false
        IFS=',' read -ra SELECTED_ITEMS <<< "$choices"

        for choice in "${SELECTED_ITEMS[@]}"; do
            choice=$(echo "$choice" | tr -d '[:space:]')
            case $choice in
                1) run_module "aux/openspec" ;;
                2) run_module "aux/specify" ;;
                3) run_module "aux/claude_agents" "contains" ;;
                4) run_module "aux/claude_agents" "wshobson" ;;
                5) run_module "aux/open_agents" ;;
                A|a) 
                    run_module "aux/openspec"
                    run_module "aux/specify"
                    run_module "aux/claude_agents" "contains"
                    run_module "aux/claude_agents" "wshobson"
                    run_module "aux/open_agents"
                    all_installed=true
                    ;;
                0) 
                    log_info_detail "$(aux_menu_text info_returning)"
                    return 0
                    ;;
                *) 
                    log_error_detail "$(aux_menu_text warning_invalid_choice): $choice"
                    ;;
            esac
        done

        if [ "$all_installed" = true ] || [ -n "$install_all" ]; then
            break
        fi

        read -r -p "$(aux_menu_text prompt_continue): " continue_choice </dev/tty
        if [[ ! "$continue_choice" =~ ^([eEyY])$ ]]; then
            break
        fi
    done
}

main() {
    install_aux_tools_menu "$@"
}

main "$@"
