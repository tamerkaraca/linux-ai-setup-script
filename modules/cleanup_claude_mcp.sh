#!/bin/bash

# Ortak yardımcı fonksiyonları yükle


# SuperClaude MCP Sunucu Temizleme
cleanup_claude_mcp() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} SuperClaude MCP Sunucu Yapılandırması Temizleme..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    SETTINGS_FILE="$HOME/.claude/settings.json"
    
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}${ERROR_TAG}${NC} 'jq' komutu bulunamadı. Bu özellik için 'jq' gereklidir."
        echo -e "${YELLOW}${INFO_TAG}${NC} Lütfen 'jq' paketini kurun (örn: sudo apt install jq)."
        return 1
    fi
    
    if [ ! -f "$SETTINGS_FILE" ]; then
        echo -e "${YELLOW}${INFO_TAG}${NC} $SETTINGS_FILE bulunamadı, işlem atlanıyor."
        return 0
    fi

    if ! jq -e '.mcpServers' "$SETTINGS_FILE" > /dev/null; then
        echo -e "${YELLOW}${INFO_TAG}${NC} Dosyada 'mcpServers' ayarı bulunmuyor."
        return 0
    fi

    mapfile -t mcp_servers < <(jq -r '.mcpServers | keys[]' "$SETTINGS_FILE")

    if [ ${#mcp_servers[@]} -eq 0 ]; then
        echo -e "${YELLOW}${INFO_TAG}${NC} Yapılandırılmış MCP sunucusu bulunamadı."
        return 0
    fi

    echo -e "\n${YELLOW}Kaldırmak istediğiniz MCP sunucu(lar)ını seçin:${NC}"
    local index=1
    for server in "${mcp_servers[@]}"; do
        echo -e "  ${GREEN}${index}${NC} - ${server}"
        index=$((index + 1))
    done
    read -r -p "Seçiminiz: " choices </dev/tty
    if [ "$choices" = "0" ] || [ -z "$choices" ]; then
        echo -e "${YELLOW}${INFO_TAG}${NC} Temizleme işlemi iptal edildi."
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
            echo -e "${RED}${ERROR_TAG}${NC} Geçersiz seçim: $choice"
            continue
        fi

        local idx=$((choice - 1))
        if [ $idx -lt 0 ] || [ $idx -ge ${#mcp_servers[@]} ]; then
            echo -e "${RED}${ERROR_TAG}${NC} Desteklenmeyen seçim: $choice"
            continue
        fi

        local server_to_remove="${mcp_servers[$idx]}"
        echo -e "${YELLOW}${INFO_TAG}${NC} '${server_to_remove}' MCP sunucusu kaldırılıyor..."
        
        jq "del(.mcpServers.\"$server_to_remove\")" "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}${SUCCESS_TAG}${NC} '${server_to_remove}' kaldırıldı."
            changes_made=true
        else
            echo -e "${RED}${ERROR_TAG}${NC} '${server_to_remove}' kaldırılırken hata oluştu."
        fi
    done

    if [ "$changes_made" = true ]; then
        mv "$temp_file" "$SETTINGS_FILE"
        echo -e "${GREEN}${SUCCESS_TAG}${NC} Değişiklikler $SETTINGS_FILE dosyasına kaydedildi."
    else
        rm -f "$temp_file"
        echo -e "${YELLOW}${INFO_TAG}${NC} Hiçbir değişiklik yapılmadı."
    fi
}

# Ana kaldırma akışı
main() {
    cleanup_claude_mcp
}

main
