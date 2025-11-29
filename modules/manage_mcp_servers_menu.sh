#!/bin/bash

# Ortak yardımcı fonksiyonları yükle
# shellcheck source=/dev/null
source "./modules/utils.sh"

CURRENT_LANG="${LANGUAGE:-en}"


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
    if [ "$CURRENT_LANG" = "tr" ]; then
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

# Script çalıştırma fonksiyonu (setup script'indeki ile aynı)
run_module() {
    local module_name="$1"
    local local_path="./modules/${module_name}.sh"
    local module_url="$BASE_URL/$module_name.sh"
    shift

    if [ -f "$local_path" ]; then
        echo -e "${CYAN}${INFO_TAG}${NC} $module_name modülü yerel dosyadan çalıştırılıyor..."
        if ! PKG_MANAGER="$PKG_MANAGER" UPDATE_CMD="$UPDATE_CMD" INSTALL_CMD="$INSTALL_CMD" bash "$local_path" "$@"; then
            echo -e "${RED}${ERROR_TAG}${NC} $module_name modülü çalıştırılırken bir hata oluştu."
            return 1
        fi
    else
        echo -e "${CYAN}${INFO_TAG}${NC} $module_name modülü indiriliyor ve çalıştırılıyor..."
        if ! curl -fsSL "$module_url" | PKG_MANAGER="$PKG_MANAGER" UPDATE_CMD="$UPDATE_CMD" INSTALL_CMD="$INSTALL_CMD" bash -s -- "$@"; then
        echo -e "${RED}${ERROR_TAG}${NC} $module_name modülü çalıştırılırken bir hata oluştu."
            return 1
        fi
    fi
    return 0
}

print_mcp_servers() {
    local label="$1"
    local settings_file="$2"
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} ${label}: $(mcp_text listing) (${settings_file})"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if [ ! -f "$settings_file" ]; then
        echo -e "${YELLOW}${INFO_TAG}${NC} $(mcp_text file_missing): ${settings_file}"
        return
    fi

    if ! command -v jq &> /dev/null; then
        echo -e "${RED}${ERROR_TAG}${NC} $(mcp_text jq_missing)"
        return
    fi

    if ! jq -e '.mcpServers' "$settings_file" >/dev/null; then
        echo -e "${YELLOW}${INFO_TAG}${NC} $(mcp_text no_section)"
        return 1
    fi

    local listed=false
    while IFS=':::' read -r key type value; do
        listed=true
        type=${type:-"-"}
        value=${value:-"-"}
        echo -e "  ${GREEN}•${NC} ${key} (tip: ${type}, hedef: ${value})"
    done < <(jq -r '.mcpServers | to_entries[] | "\(.key):::\(.value.type // "-"):::\(.value.command // (.value.url // "-"))"' "$settings_file")

    if [ "$listed" = false ]; then
        echo -e "${YELLOW}${INFO_TAG}${NC} $(mcp_text no_servers)"
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
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(mcp_text no_servers)"
    fi

    echo -e "\n${YELLOW}$(mcp_text continue_prompt)${NC}"
    read -r </dev/tty
}

# MCP Sunucu Yönetimi menüsü
manage_mcp_servers_menu() {
    while true; do
        clear
        echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════════════════╗${NC}"
        printf "${BLUE}║%*s║${NC}\n" -70 " $(mcp_text menu_title) "
        echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════╝${NC}\n"
        echo -e "  ${GREEN}1${NC} - $(mcp_text option1)"
        echo -e "  ${GREEN}2${NC} - $(mcp_text option2)"
        echo -e "  ${GREEN}3${NC} - $(mcp_text option3)"
        echo -e "  ${GREEN}A${NC} - $(mcp_text optionA)"
        echo -e "  ${RED}0${NC} - $(mcp_text option0)"
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(mcp_text hint)"

        read -r -p "${YELLOW}$(mcp_text prompt):${NC} " mcp_choices </dev/tty
        if [ "$mcp_choices" = "0" ] || [ -z "$mcp_choices" ]; then
            echo -e "${YELLOW}${INFO_TAG}${NC} $(mcp_text returning)"
            break
        fi

        local all_managed=false
        IFS=',' read -ra SELECTED_MCP <<< "$mcp_choices"

        for choice in "${SELECTED_MCP[@]}"; do
            choice=$(echo "$choice" | tr -d ' ')
            case $choice in
                1) run_module "cleanup_magic_mcp" ;;
                2) run_module "cleanup_qwen_mcp" ;;
                3) run_module "cleanup_claude_mcp" ;;
                A|a)
                    list_all_mcp_servers
                    continue 2
                    ;;
                *) echo -e "${RED}${ERROR_TAG}${NC} $(mcp_text invalid): $choice" ;;
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
