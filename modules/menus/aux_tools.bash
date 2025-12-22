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
    echo "[HATA/ERROR] utils.bash yüklenemedi / Unable to load utils.bash (tried $utils_local)" >&2
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
    ["option1"]="OpenSpec CLI"
    ["option2"]="specify-cli"
    ["option3"]="Contains Studio Agents (for Claude)"
    ["option4"]="Wes Hobson Agents (for Claude)"
    ["option5"]="AgentSkills Agents (for Claude)"
    ["option6"]="davila7 Templates (for Claude)"
    ["option7"]="OpenAgents (darrenhinde/OpenAgents)"
    ["option8"]="Conductor (Gemini CLI Extension)"
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
    ["option1"]="OpenSpec CLI"
    ["option2"]="specify-cli"
    ["option3"]="Contains Studio Agents (Claude için)"
    ["option4"]="Wes Hobson Agents (Claude için)"
    ["option5"]="AgentSkills Agents (Claude için)"
    ["option6"]="davila7 Şablonları (Claude için)"
    ["option7"]="OpenAgents (darrenhinde/OpenAgents)"
    ["option8"]="Conductor (Gemini CLI Eklentisi)"
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
            echo -e "  ${GREEN}1${NC} - $(aux_menu_text option1)"
            echo -e "  ${GREEN}2${NC} - $(aux_menu_text option2)"
            echo -e "  ${GREEN}3${NC} - $(aux_menu_text option3)"
            echo -e "  ${GREEN}4${NC} - $(aux_menu_text option4)"
            echo -e "  ${GREEN}5${NC} - $(aux_menu_text option5)"
            echo -e "  ${GREEN}6${NC} - $(aux_menu_text option6)"
            echo -e "  ${GREEN}7${NC} - $(aux_menu_text option7)"
            echo -e "  ${GREEN}8${NC} - $(aux_menu_text option8)"
            echo -e "  ${GREEN}A${NC} - $(aux_menu_text optionA)"
            echo -e "  ${GREEN}0${NC} - $(aux_menu_text option_return)"
            echo -e "${YELLOW}$(aux_menu_text menu_hint)${NC}"

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
                1) run_module "auxiliary/openspec" ;;
                2) run_module "auxiliary/specify" ;;
                3) run_module "auxiliary/claude_agents" "contains" ;;
                4) run_module "auxiliary/claude_agents" "wshobson" ;;
                5) run_module "auxiliary/claude_agents" "agentskills" ;;
                6) run_module "menus/davila7_menu" ;;
                7) run_module "auxiliary/open_agents" ;;
                8) run_module "auxiliary/conductor" ;;
                A|a)
                    run_module "auxiliary/openspec"
                    run_module "auxiliary/specify"
                    run_module "auxiliary/claude_agents" "contains"
                    run_module "auxiliary/claude_agents" "wshobson"
                    run_module "auxiliary/claude_agents" "agentskills"
                    # davila7 has its own menu, skip in "install all"
                    run_module "auxiliary/open_agents"
                    run_module "auxiliary/conductor"
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
