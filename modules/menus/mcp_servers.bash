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

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

declare -A MCP_TEXT_EN=(
    [menu_title]="MCP Server Management Menu"
    [option1]="Manage SuperGemini MCP settings"
    [option2]="Manage SuperQwen MCP settings"
    [option3]="Manage SuperClaude MCP settings"
    [optionA]="List all MCP servers"
    [option0]="Return to main menu"
    [hint]="Use commas for multiple selections (e.g., 1,2)."
    [prompt]="Your choice"
    [returning]="Returning to the main menu..."
    [invalid]="Invalid selection"
    [listing]="Listing MCP servers from"
    [file_missing]="Settings file not found"
    [jq_missing]="jq is required to inspect MCP servers."
    [no_section]="'mcpServers' entry not found."
    [no_servers]="No MCP servers registered."
    [continue_prompt]="Press Enter to continue..."
    [cleanup_prompt]="Manage another server? (y/n) [n]: "
)

declare -A MCP_TEXT_TR=(
    [menu_title]="MCP Sunucu Yönetim Menüsü"
    [option1]="SuperGemini MCP sunucularını yönet"
    [option2]="SuperQwen MCP sunucularını yönet"
    [option3]="SuperClaude MCP sunucularını yönet"
    [optionA]="Tüm MCP sunucularını listele"
    [option0]="Ana menüye dön"
    [hint]="Birden fazla seçim için virgülle ayırabilirsiniz (örn: 1,2)."
    [prompt]="Seçiminiz"
    [returning]="Ana menüye dönülüyor..."
    [invalid]="Geçersiz seçim"
    [listing]="MCP sunucuları listeleniyor"
    [file_missing]="Ayar dosyası bulunamadı"
    [jq_missing]="MCP sunucularını incelemek için jq gereklidir."
    [no_section]="'mcpServers' alanı bulunamadı."
    [no_servers]="Kayıtlı MCP sunucusu yok."
    [continue_prompt]="Devam etmek için Enter'a basın..."
    [cleanup_prompt]="Başka bir sunucu yönetmek ister misiniz? (e/h) [h]: "
)

mcp_text() {
    local key="$1"
    local default_value="${MCP_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        echo "${MCP_TEXT_TR[$key]:-$default_value}"
    else
        echo "$default_value"
    fi
}

MCP_TARGETS=(
    "SuperGemini:::${HOME}/.gemini/settings.json"
    "SuperQwen:::${HOME}/.qwen/settings.json"
    "SuperClaude:::${HOME}/.claude/settings.json"
)

print_mcp_servers() {
    local label="$1"
    local settings_file="$2"
    log_info_detail "${label}: $(mcp_text listing) (${settings_file})"

    if [ ! -f "$settings_file" ]; then
        log_info_detail "$(mcp_text file_missing): ${settings_file}"
        return
    fi

    if ! command -v jq &> /dev/null; then
        log_error_detail "$(mcp_text jq_missing)"
        return
    fi

    if ! jq -e '.mcpServers' "$settings_file" >/dev/null; then
        log_info_detail "$(mcp_text no_section)"
        return 1
    fi

    local listed=false
    while IFS=':::' read -r key type value; do
        listed=true
        type=${type:-"-"}
        value=${value:-"-"}
        log_info_detail "  • ${key} (tip: ${type}, hedef: ${value})"
    done < <(jq -r '.mcpServers | to_entries[] | "\(.key):::\(.value.type // "-"):::\(.value.command // (.value.url // "-"))"' "$settings_file")

    if [ "$listed" = false ]; then
        log_info_detail "$(mcp_text no_servers)"
        return 1
    fi

    return 0
}

list_all_mcp_servers() {
    local any_listed=false
    for entry in "${MCP_TARGETS[@]}"; do
        local label="${entry%%:::*}"
        local file="${entry#*:::}"
        if print_mcp_servers "$label" "$file"; then
            any_listed=true
        fi
    done

    if [ "$any_listed" = false ]; then
        log_info_detail "$(mcp_text no_servers)"
    fi

    read -r -p "$(mcp_text continue_prompt)" </dev/tty
}

# MCP Sunucu Yönetimi menüsü
manage_mcp_servers_menu() {
    while true; do
        clear
        print_heading_panel "$(mcp_text menu_title)"
        echo -e "  ${GREEN}1${NC} - $(mcp_text option1)"
        echo -e "  ${GREEN}2${NC} - $(mcp_text option2)"
        echo -e "  ${GREEN}3${NC} - $(mcp_text option3)"
        echo -e "  ${GREEN}A${NC} - $(mcp_text optionA)"
        echo -e "  ${GREEN}0${NC} - $(mcp_text option0)"
        echo -e "${YELLOW}$(mcp_text hint)${NC}"

        read -r -p "$(mcp_text prompt): " mcp_choices </dev/tty
        if [ "$mcp_choices" = "0" ] || [ -z "$mcp_choices" ]; then
            log_info_detail "$(mcp_text returning)"
            break
        fi

        local all_managed=false
        IFS=',' read -ra SELECTED_MCP <<< "$mcp_choices"

        for choice in "${SELECTED_MCP[@]}"; do
            choice=$(echo "$choice" | tr -d ' ')
            case $choice in
                1) run_module "utils/cleanup_magic_mcp" ;;
                2) run_module "utils/cleanup_qwen_mcp" ;;
                3) run_module "utils/cleanup_claude_mcp" ;;
                A|a)
                    list_all_mcp_servers
                    continue 2
                    ;;
                *) log_error_detail "$(mcp_text invalid): $choice" ;;
            esac
        done
        
        if [ "$all_managed" = true ]; then
            break
        fi

        read -r -p "$(mcp_text cleanup_prompt)" continue_choice </dev/tty
        if [[ ! "$continue_choice" =~ ^([eEyY])$ ]]; then
            break
        fi
    done
}

# Ana yönetim akışı
main() {
    manage_mcp_servers_menu
}

main
