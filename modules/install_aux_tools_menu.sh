#!/bin/bash
# Windows CRLF düzeltme kontrolü
if [ -f "$0" ]; then
    if file "$0" | grep -q "CRLF"; then
        if command -v dos2unix &> /dev/null; then dos2unix "$0"; elif command -v sed &> /dev/null; then sed -i 's/\r$//' "$0"; fi
        exec bash "$0" "$@"
    fi
fi
set -euo pipefail

# Ortak yardımcı fonksiyonları yükle
# shellcheck source=/dev/null
source "./modules/utils.sh"

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
            echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════════════════╗${NC}"
            text=" $(aux_menu_text menu_title) "
            len=${#text}
            padding=$(( (72 - len) / 2 ))
            printf "${BLUE}║%*s%s%*s║${NC}\n" "$padding" "" "$text" "$((72 - len - padding))" ""
            echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════╝${NC}\n"
            echo -e "  ${GREEN}1${NC} - $(aux_menu_text option1)"
            echo -e "  ${GREEN}2${NC} - $(aux_menu_text option2)"
            echo -e "  ${GREEN}3${NC} - $(aux_menu_text option3)"
            echo -e "  ${GREEN}4${NC} - $(aux_menu_text option4)"
            echo -e "  ${GREEN}A${NC} - $(aux_menu_text optionA)"
            echo -e "  ${RED}0${NC} - $(aux_menu_text option_return)"
            echo -e "\n${YELLOW}$(aux_menu_text menu_hint)${NC}"

            read -r -p "${YELLOW}$(aux_menu_text prompt_choice):${NC} " choices </dev/tty
            if [ "$choices" = "0" ] || [ -z "$choices" ]; then
                echo -e "${YELLOW}$(aux_menu_text info_returning)${NC}"
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
                1) run_module "install_openspec_cli" ;;
                2) run_module "install_specify_cli" ;;
                3) run_module "install_claude_agents" "contains" ;;
                4) run_module "install_claude_agents" "wshobson" ;;
                A|a) 
                    run_module "install_openspec_cli"
                    run_module "install_specify_cli"
                    run_module "install_claude_agents" "contains"
                    run_module "install_claude_agents" "wshobson"
                    all_installed=true
                    ;;
                0) 
                    echo -e "${YELLOW}$(aux_menu_text info_returning)${NC}"
                    return 0
                    ;;
                *) 
                    echo -e "${RED}$(aux_menu_text warning_invalid_choice): $choice${NC}"
                    ;;
            esac
        done

        if [ "$all_installed" = true ] || [ -n "$install_all" ]; then
            break
        fi

        read -r -p "${YELLOW}$(aux_menu_text prompt_continue)${NC} " continue_choice </dev/tty
        if [[ ! "$continue_choice" =~ ^([eEyY])$ ]]; then
            break
        fi
    done
}

main() {
    install_aux_tools_menu "$@"
}

main "$@"
