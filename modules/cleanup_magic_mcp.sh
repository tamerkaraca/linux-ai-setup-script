#!/bin/bash
set -euo pipefail

# Ortak yardımcı fonksiyonları yükle
UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

declare -A CLEANUP_MAGIC_TEXT_EN=(
    ["cleanup_title"]="Cleaning up SuperGemini MCP Server Configuration..."
    ["jq_not_found"]="'jq' command not found. 'jq' is required for this feature."
    ["jq_install_prompt"]="Please install the 'jq' package (e.g., sudo apt install jq)."
    ["settings_not_found"]="%s not found, skipping."
    ["mcp_settings_missing"]="'mcpServers' setting not found in the file."
    ["no_mcp_servers"]="No configured MCP servers found."
    ["select_servers_prompt"]="Select the MCP server(s) you want to remove:"
    ["choice_prompt"]="Your choice: "
    ["operation_canceled"]="Cleanup operation canceled."
    ["invalid_selection"]="Invalid selection: %s"
    ["unsupported_selection"]="Unsupported selection: %s"
    ["removing_server"]="Removing '%s' MCP server..."
    ["server_removed"]="'%s' removed."
    ["server_remove_error"]="Error removing '%s'."
    ["changes_saved"]="Changes saved to %s."
    ["no_changes_made"]="No changes were made."
    ["cancel_option"]="Cancel"
    ["multiple_selection_hint"]="For multiple selections, separate with commas (e.g., 1,2,3)"
)

declare -A CLEANUP_MAGIC_TEXT_TR=(
    ["cleanup_title"]="SuperGemini MCP Sunucu Yapılandırması Temizleme..."
    ["jq_not_found"]="'jq' komutu bulunamadı. Bu özellik için 'jq' gereklidir."
    ["jq_install_prompt"]="Lütfen 'jq' paketini kurun (örn: sudo apt install jq)."
    ["settings_not_found"]="%s bulunamadı, işlem atlanıyor."
    ["mcp_settings_missing"]="Dosyada 'mcpServers' ayarı bulunmuyor."
    ["no_mcp_servers"]="Yapılandırılmış MCP sunucusu bulunamadı."
    ["select_servers_prompt"]="Kaldırmak istediğiniz MCP sunucu(lar)ını seçin:"
    ["choice_prompt"]="Seçiminiz: "
    ["operation_canceled"]="Temizleme işlemi iptal edildi."
    ["invalid_selection"]="Geçersiz seçim: %s"
    ["unsupported_selection"]="Desteklenmeyen seçim: %s"
    ["removing_server"]="'%s' MCP sunucusu kaldırılıyor..."
    ["server_removed"]="'%s' kaldırıldı."
    ["server_remove_error"]="'%s' kaldırılırken hata oluştu."
    ["changes_saved"]="Değişiklikler %s dosyasına kaydedildi."
    ["no_changes_made"]="Hiçbir değişiklik yapılmadı."
    ["cancel_option"]="İptal"
    ["multiple_selection_hint"]="Birden fazla seçim için virgülle ayırın (örn: 1,2,3)"
)

cleanup_magic_text() {
    local key="$1"
    local default_value="${CLEANUP_MAGIC_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${CLEANUP_MAGIC_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

# SuperGemini MCP Sunucu Temizleme
cleanup_magic_mcp() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(cleanup_magic_text cleanup_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    SETTINGS_FILE="$HOME/.gemini/settings.json"
    
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}${ERROR_TAG}${NC} $(cleanup_magic_text jq_not_found)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(cleanup_magic_text jq_install_prompt)"
        return 1
    fi
    
    if [ ! -f "$SETTINGS_FILE" ]; then
        local msg_format
        msg_format="$(cleanup_magic_text settings_not_found)"
        local msg="${msg_format//\%s/$SETTINGS_FILE}"
        echo -e "${YELLOW}${INFO_TAG}${NC} $msg"
        return 0
    fi

    if ! jq -e '.mcpServers' "$SETTINGS_FILE" > /dev/null; then
        echo -e "${YELLOW}${INFO_TAG}${NC} $(cleanup_magic_text mcp_settings_missing)"
        return 0
    fi

    mapfile -t mcp_servers < <(jq -r '.mcpServers | keys[]' "$SETTINGS_FILE")

    if [ ${#mcp_servers[@]} -eq 0 ]; then
        echo -e "${YELLOW}${INFO_TAG}${NC} $(cleanup_magic_text no_mcp_servers)"
        return 0
    fi

    echo -e "\n${YELLOW}$(cleanup_magic_text select_servers_prompt)${NC}"
    local index=1
    for server in "${mcp_servers[@]}"; do
        echo -e "  ${GREEN}${index}${NC} - ${server}"
        index=$((index + 1))
    done
    echo -e "  ${RED}0${NC} - $(cleanup_magic_text cancel_option)"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(cleanup_magic_text multiple_selection_hint)"

    read -r -p "$(cleanup_magic_text choice_prompt)" choices </dev/tty
    if [ "$choices" = "0" ] || [ -z "$choices" ]; then
        echo -e "${YELLOW}${INFO_TAG}${NC} $(cleanup_magic_text operation_canceled)"
        return 0
    fi

    IFS=',' read -ra SELECTED_INDICES <<< "$choices"
    
    local temp_file
    temp_file=$(mktemp)
    cp "$SETTINGS_FILE" "$temp_file"

    local changes_made=false
    for choice in "${SELECTED_INDICES[@]}"; do
        choice=$(echo "$choice" | tr -d ' ')
        if ! [[ "$choice" =~ ^[1-9][0-9]*$ ]]; then
            local msg_format
            msg_format="$(cleanup_magic_text invalid_selection)"
            local msg="${msg_format//\%s/$choice}"
            echo -e "${RED}${ERROR_TAG}${NC} $msg"
            continue
        fi

        local idx=$((choice - 1))
        if [ $idx -lt 0 ] || [ $idx -ge ${#mcp_servers[@]} ]; then
            local msg_format
            msg_format="$(cleanup_magic_text unsupported_selection)"
            local msg="${msg_format//\%s/$choice}"
            echo -e "${RED}${ERROR_TAG}${NC} $msg"
            continue
        fi

        local server_to_remove="${mcp_servers[$idx]}"
        local msg_format
        msg_format="$(cleanup_magic_text removing_server)"
        local msg="${msg_format//\%s/$server_to_remove}"
        echo -e "${YELLOW}${INFO_TAG}${NC} $msg"
        
        if jq "del(.mcpServers.\"$server_to_remove\")" "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"; then
            local msg_format
            msg_format="$(cleanup_magic_text server_removed)"
            local msg="${msg_format//\%s/$server_to_remove}"
            echo -e "${GREEN}${SUCCESS_TAG}${NC} $msg"
            changes_made=true
        else
            local msg_format
            msg_format="$(cleanup_magic_text server_remove_error)"
            local msg="${msg_format//\%s/$server_to_remove}"
            echo -e "${RED}${ERROR_TAG}${NC} $msg"
        fi
    done

    if [ "$changes_made" = true ]; then
        mv "$temp_file" "$SETTINGS_FILE"
        local msg_format
        msg_format="$(cleanup_magic_text changes_saved)"
        local msg="${msg_format//\%s/$SETTINGS_FILE}"
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $msg"
    else
        rm -f "$temp_file"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(cleanup_magic_text no_changes_made)"
    fi
}

# Ana kaldırma akışı
main() {
    cleanup_magic_mcp
}

main
