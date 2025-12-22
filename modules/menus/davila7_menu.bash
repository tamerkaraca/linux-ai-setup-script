#!/bin/bash
set -euo pipefail

# --- Load Utilities ---
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$script_dir/../utils/utils.bash"
if [ -f "$utils_local" ]; then source "$utils_local"; fi
# --- End Load Utilities ---

# --- Text Definitions ---
declare -A MENU_TEXT_EN=(
    ["main_title"]="davila7 Templates (for Claude)"
    ["option1"]="Agents (142 available)"
    ["option2"]="Commands (159+ available)"
    ["option3"]="Settings (60+ available)"
    ["option4"]="Hooks (40+ available)"
    ["option5"]="MCPs (70+ available)"
    ["option6"]="Plugins (8 available)"
    ["option7"]="Skills (100+ available)"
    ["option_return"]="Return to Previous Menu"
    ["select_prompt"]="Select category"
    ["npx_missing"]="npx command not found. Please install Node.js and npm first."
)
declare -A MENU_TEXT_TR=(
    ["main_title"]="davila7 Şablonları (Claude için)"
    ["option1"]="Ajanlar (142 adet)"
    ["option2"]="Komutlar (159+ adet)"
    ["option3"]="Ayarlar (60+ adet)"
    ["option4"]="Kancalar (40+ adet)"
    ["option5"]="MCP'ler (70+ adet)"
    ["option6"]="Eklentiler (8 adet)"
    ["option7"]="Yetenekler (100+ adet)"
    ["option_return"]="Önceki Menüye Dön"
    ["select_prompt"]="Kategori seçin"
    ["npx_missing"]="npx komutu bulunamadı. Lütfen önce Node.js ve npm kurun."
)

menu_text() {
    local key="$1"
    local default_value="${MENU_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${MENU_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}
# --- End Text Definitions ---

# --- Check NPX ---
check_npx() {
    if ! command -v npx &> /dev/null; then
        log_error_detail "$(menu_text 'npx_missing')"
        return 1
    fi
    return 0
}

# --- Run Install Command ---
run_install() {
    local type="$1"
    local items="$2"

    if ! check_npx; then
        return 1
    fi

    if [ -z "$items" ]; then
        log_error_detail "No items selected"
        return 1
    fi

    log_info_detail "Installing $type: $items"
    local cmd="npx claude-code-templates@latest --$type ${items}"
    log_info_detail "$ ${cmd}"

    if eval "$cmd"; then
        log_success_detail "Installation complete."
    else
        log_error_detail "Installation failed."
        return 1
    fi
}

# --- Source Sub-menus ---
source_submenu() {
    local submenu="$1"
    local submenu_file="$script_dir/davila7_${submenu}.bash"

    if [ -f "$submenu_file" ]; then
        source "$submenu_file"
        davila7_${submenu}_menu
    else
        log_error_detail "Sub-menu not found: $submenu_file"
    fi
}

# --- Main Menu ---
davila7_main_menu() {
    while true; do
        clear
        print_heading_panel "$(menu_text 'main_title')"

        echo -e "  ${GREEN}1${NC} - $(menu_text 'option1')"
        echo -e "  ${GREEN}2${NC} - $(menu_text 'option2')"
        echo -e "  ${GREEN}3${NC} - $(menu_text 'option3')"
        echo -e "  ${GREEN}4${NC} - $(menu_text 'option4')"
        echo -e "  ${GREEN}5${NC} - $(menu_text 'option5')"
        echo -e "  ${GREEN}6${NC} - $(menu_text 'option6')"
        echo -e "  ${GREEN}7${NC} - $(menu_text 'option7')"
        echo -e "  ${GREEN}0${NC} - $(menu_text 'option_return')"
        echo

        read -r -p "$(menu_text 'select_prompt'): " choice </dev/tty

        case "$choice" in
            1) source_submenu "agents" ;;
            2) source_submenu "commands" ;;
            3) source_submenu "settings" ;;
            4) source_submenu "hooks" ;;
            5) source_submenu "mcps" ;;
            6) source_submenu "plugins" ;;
            7) source_submenu "skills" ;;
            0) break ;;
            *) log_error_detail "Invalid choice: $choice" ;;
        esac
    done
}

# --- Execution ---
davila7_main_menu
