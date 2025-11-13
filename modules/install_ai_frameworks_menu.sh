#!/bin/bash
set -euo pipefail

# Ortak yardımcı fonksiyonları yükle
# shellcheck source=/dev/null
source "./modules/utils.sh"

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

declare -A AI_FW_MENU_TEXT_EN=(
    ["fw_menu_title"]="AI Frameworks Installation Menu"
    ["fw_option1"]="SuperGemini Framework"
    ["fw_option2"]="SuperQwen Framework"
    ["fw_option3"]="SuperClaude Framework"
    ["fw_optionA"]="Install All Frameworks"
    ["fw_option_return"]="Return to Main Menu"
    ["fw_menu_hint"]="You can make multiple selections with commas (e.g., 1,2)."
    ["prompt_choice"]="Your choice"
    ["info_returning"]="Returning to the previous menu..."
    ["warning_invalid_choice"]="Invalid choice"
    ["fw_prompt_install_more"]="Install another framework? (y/n) [n]: "
    ["pipx_required"]="Pipx is required for AI Frameworks; installing it first..."
    ["python_required"]="Python is required for Pipx; installing it first..."
    ["module_running_local"]="Running %s module from local file..."
    ["module_downloading"]="Downloading and running %s module..."
    ["module_error"]="An error occurred while running the %s module."
)

declare -A AI_FW_MENU_TEXT_TR=(
    ["fw_menu_title"]="AI Frameworks Kurulum Menüsü"
    ["fw_option1"]="SuperGemini Framework"
    ["fw_option2"]="SuperQwen Framework"
    ["fw_option3"]="SuperClaude Framework"
    ["fw_optionA"]="Tüm Framework'leri Kur"
    ["fw_option_return"]="Ana Menüye Dön"
    ["fw_menu_hint"]="Birden fazla seçim için virgül kullanabilirsiniz (örn: 1,2)."
    ["prompt_choice"]="Seçiminiz"
    ["info_returning"]="Bir önceki menüye dönülüyor..."
    ["warning_invalid_choice"]="Geçersiz seçim"
    ["fw_prompt_install_more"]="Başka bir framework kurmak ister misiniz? (e/h) [h]: "
    ["pipx_required"]="AI Frameworks için önce Pipx kurulumu yapılıyor..."
    ["python_required"]="Pipx için önce Python kurulumu yapılıyor..."
    ["module_running_local"]="%s modülü yerel dosyadan çalıştırılıyor..."
    ["module_downloading"]="%s modülü indiriliyor ve çalıştırılıyor..."
    ["module_error"]="%s modülü çalıştırılırken bir hata oluştu."
)

ai_fw_menu_text() {
    local key="$1"
    local default_value="${AI_FW_MENU_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${AI_FW_MENU_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

# Script çalıştırma fonksiyonu (setup script'inin güncel versiyonu ile aynı davranış)
run_module() {
    local module_name="$1"
    local local_path="./modules/${module_name}.sh"
    local module_url="$BASE_URL/$module_name.sh"
    shift

    if [ -f "$local_path" ]; then
        printf -v msg "$(ai_fw_menu_text module_running_local)" "$module_name"
        echo -e "${CYAN}${INFO_TAG}${NC} $msg"
        if ! PKG_MANAGER="$PKG_MANAGER" UPDATE_CMD="$UPDATE_CMD" INSTALL_CMD="$INSTALL_CMD" LANGUAGE="$LANGUAGE" bash "$local_path" "$@"; then
            printf -v msg "$(ai_fw_menu_text module_error)" "$module_name"
            echo -e "${RED}${ERROR_TAG}${NC} $msg"
            return 1
        fi
    else
        printf -v msg "$(ai_fw_menu_text module_downloading)" "$module_name"
        echo -e "${CYAN}${INFO_TAG}${NC} $msg"
        if ! curl -fsSL "$module_url" | PKG_MANAGER="$PKG_MANAGER" UPDATE_CMD="$UPDATE_CMD" INSTALL_CMD="$INSTALL_CMD" LANGUAGE="$LANGUAGE" bash -s -- "$@"; then
            printf -v msg "$(ai_fw_menu_text module_error)" "$module_name"
            echo -e "${RED}${ERROR_TAG}${NC} $msg"
            return 1
        fi
    fi
    return 0
}

# AI Frameworks menüsü
install_ai_frameworks_menu() {

    local install_all="${1:-}" # "all" parametresi gelirse hepsini kur

    while true; do
        if [ -z "$install_all" ]; then
            clear
            echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
            printf "${BLUE}║%*s║${NC}\n" -43 " $(ai_fw_menu_text fw_menu_title) "
            echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}\n"
            echo -e "  ${GREEN}1${NC} - $(ai_fw_menu_text fw_option1)"
            echo -e "  ${GREEN}2${NC} - $(ai_fw_menu_text fw_option2)"
            echo -e "  ${GREEN}3${NC} - $(ai_fw_menu_text fw_option3)"
            echo -e "  ${GREEN}A${NC} - $(ai_fw_menu_text fw_optionA)"
            echo -e "  ${RED}0${NC} - $(ai_fw_menu_text fw_option_return)"
            echo -e "\n${YELLOW}$(ai_fw_menu_text fw_menu_hint)${NC}"

            read -r -p "${YELLOW}$(ai_fw_menu_text prompt_choice):${NC} " framework_choices </dev/tty
            if [ "$framework_choices" = "0" ] || [ -z "$framework_choices" ]; then
                echo -e "${YELLOW}$(ai_fw_menu_text info_returning)${NC}"
                break
            fi
        else
            framework_choices="A" # "all" parametresi gelirse tümünü seç
        fi

        # Pipx kontrolü
        if ! command -v pipx &> /dev/null; then
            echo -e "${YELLOW}${WARN_TAG}${NC} $(ai_fw_menu_text pipx_required)"
            if ! command -v python3 &> /dev/null; then
                 echo -e "${YELLOW}${WARN_TAG}${NC} $(ai_fw_menu_text python_required)"
                 install_python
            fi
            install_pipx
        fi

        local all_installed=false
        IFS=',' read -ra SELECTED_FW <<< "$framework_choices"

        for choice in "${SELECTED_FW[@]}"; do
            choice=$(echo "$choice" | tr -d ' ' | tr '[:lower:]' '[:upper:]')
            case $choice in
                1) run_module "install_supergemini" ;;
                2) run_module "install_superqwen" ;;
                3) run_module "install_superclaude" ;;
                A) 
                    run_module "install_supergemini"
                    run_module "install_superqwen"
                    run_module "install_superclaude"
                    all_installed=true
                    ;;
                0)
                    echo -e "${YELLOW}$(ai_fw_menu_text info_returning)${NC}"
                    return 0
                    ;;
                *) echo -e "${RED}$(ai_fw_menu_text warning_invalid_choice): $choice${NC}" ;;
            esac
        done
        
        if [ "$all_installed" = true ] || [ -n "$install_all" ]; then
            break
        fi

        read -r -p "${YELLOW}$(ai_fw_menu_text fw_prompt_install_more)${NC} " continue_choice </dev/tty
        if [[ ! "$continue_choice" =~ ^([eEyY])$ ]]; then
            break
        fi
    done
}

# Ana kurulum akışı
main() {
    install_ai_frameworks_menu "$@"
}

main "$@"
