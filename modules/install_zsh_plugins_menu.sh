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

declare -A ZSH_PLUGINS_MENU_TEXT_EN=(
    ["menu_title"]="Zsh Complete Setup Menu"
    ["option1"]="Install Zsh (Advanced Shell)"
    ["option2"]="Install Oh My Zsh (Framework)"
    ["option3"]="Zsh Autosuggestions"
    ["option4"]="Zsh Syntax Highlighting"
    ["option5"]="Powerlevel10k Theme"
    ["option6"]="Zsh Completions"
    ["option7"]="Configure Zsh (.zshrc)"
    ["optionA"]="Install All Zsh Components"
    ["option_return"]="Return to Terminal Tools Menu"
    ["menu_hint"]="You can make multiple selections with commas (e.g., 1,2,7)."
    ["prompt_choice"]="Your choice"
    ["info_returning"]="Returning to terminal tools menu..."
    ["warning_invalid_choice"]="Invalid choice"
    ["prompt_continue"]="Install another Zsh component? (y/n) [n]: "
)

declare -A ZSH_PLUGINS_MENU_TEXT_TR=(
    ["menu_title"]="Zsh Tam Kurulum Menüsü"
    ["option1"]="Zsh Kur (Gelişmiş Shell)"
    ["option2"]="Oh My Zsh Kur (Framework)"
    ["option3"]="Zsh Otomatik Öneriler"
    ["option4"]="Zsh Sözdizimi Vurgulama"
    ["option5"]="Powerlevel10k Teması"
    ["option6"]="Zsh Tamamlamaları"
    ["option7"]="Zsh Yapılandır (.zshrc)"
    ["optionA"]="Tüm Zsh Bileşenlerini Kur"
    ["option_return"]="Terminal Araçları Menüsüne Dön"
    ["menu_hint"]="Birden fazla seçim için virgül kullanabilirsiniz (örn: 1,2,7)."
    ["prompt_choice"]="Seçiminiz"
    ["info_returning"]="Terminal araçları menüsüne dönülüyor..."
    ["warning_invalid_choice"]="Geçersiz seçim"
    ["prompt_continue"]="Başka bir Zsh bileşeni kurmak ister misiniz? (e/h) [h]: "
)

zsh_plugins_menu_text() {
    local key="$1"
    local default_value="${ZSH_PLUGINS_MENU_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${ZSH_PLUGINS_MENU_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

install_zsh_plugins_menu() {
    local install_all="${1:-""}"

    while true; do
        local choices=""
        if [ -z "$install_all" ]; then
            clear
            echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════════════════╗${NC}"
            text=" $(zsh_plugins_menu_text menu_title) "
            len=${#text}
            padding=$(( (72 - len) / 2 ))
            printf "${BLUE}║%*s%s%*s║${NC}\n" "$padding" "" "$text" "$((72 - len - padding))" ""
            echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════╝${NC}\n"
            echo -e "  ${GREEN}1${NC} - $(zsh_plugins_menu_text option1)"
            echo -e "  ${GREEN}2${NC} - $(zsh_plugins_menu_text option2)"
            echo -e "  ${GREEN}3${NC} - $(zsh_plugins_menu_text option3)"
            echo -e "  ${GREEN}4${NC} - $(zsh_plugins_menu_text option4)"
            echo -e "  ${GREEN}5${NC} - $(zsh_plugins_menu_text option5)"
            echo -e "  ${GREEN}6${NC} - $(zsh_plugins_menu_text option6)"
            echo -e "  ${GREEN}7${NC} - $(zsh_plugins_menu_text option7)"
            echo -e "  ${GREEN}A${NC} - $(zsh_plugins_menu_text optionA)"
            echo -e "  ${RED}0${NC} - $(zsh_plugins_menu_text option_return)"
            echo -e "\n${YELLOW}$(zsh_plugins_menu_text menu_hint)${NC}"

            read -r -p "${YELLOW}$(zsh_plugins_menu_text prompt_choice):${NC} " choices </dev/tty
            if [ "$choices" = "0" ] || [ -z "$choices" ]; then
                echo -e "${YELLOW}$(zsh_plugins_menu_text info_returning)${NC}"
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
                1) run_module "install_zsh" ;;
                2) run_module "install_oh_my_zsh" ;;
                3) run_module "install_zsh_autosuggestions" ;;
                4) run_module "install_zsh_syntax_highlighting" ;;
                5) run_module "install_powerlevel10k" ;;
                6) run_module "install_zsh_completions" ;;
                7) run_module "configure_zsh" ;;
                A|a) 
                    run_module "install_zsh"
                    run_module "install_oh_my_zsh"
                    run_module "install_zsh_autosuggestions"
                    run_module "install_zsh_syntax_highlighting"
                    run_module "install_powerlevel10k"
                    run_module "install_zsh_completions"
                    run_module "configure_zsh"
                    all_installed=true
                    ;;
                0) 
                    echo -e "${YELLOW}$(zsh_plugins_menu_text info_returning)${NC}"
                    return 0
                    ;;
                *) 
                    echo -e "${RED}$(zsh_plugins_menu_text warning_invalid_choice): $choice${NC}"
                    ;;
            esac
        done

        if [ "$all_installed" = true ] || [ -n "$install_all" ]; then
            break
        fi

        read -r -p "${YELLOW}$(zsh_plugins_menu_text prompt_continue)${NC} " continue_choice </dev/tty
        if [[ ! "$continue_choice" =~ ^([eEyY])$ ]]; then
            break
        fi
    done
}

main() {
    install_zsh_plugins_menu "$@"
}

main "$@"