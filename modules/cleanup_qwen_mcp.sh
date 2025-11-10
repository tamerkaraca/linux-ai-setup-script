#!/bin/bash

# Ortak yardımcı fonksiyonları yükle
# shellcheck source=/dev/null
source "/mnt/d/ai/modules/utils.sh"

# SuperQwen MCP Sunucu Temizleme
cleanup_qwen_mcp() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} SuperQwen MCP Sunucu Yapılandırması Temizleme..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    detect_package_manager # Ensure PKG_MANAGER, INSTALL_CMD are set

    SETTINGS_FILE="$HOME/.qwen/settings.json"
    
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}[HATA]${NC} 'jq' komutu bulunamadı. Bu özellik için 'jq' gereklidir."
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen 'jq' paketini kurun (örn: sudo apt install jq)."
        return 1
    fi
    
    if [ ! -f "$SETTINGS_FILE" ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} $SETTINGS_FILE bulunamadı, işlem atlanıyor."
        return 0
    fi

    if ! jq -e '.mcpServers' "$SETTINGS_FILE" > /dev/null; then
        echo -e "${YELLOW}[BİLGİ]${NC} Dosyada 'mcpServers' ayarı bulunmuyor."
        return 0
    fi

    mapfile -t mcp_servers < <(jq -r '.mcpServers | keys[]' "$SETTINGS_FILE")

    if [ ${#mcp_servers[@]} -eq 0 ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} Yapılandırılmış MCP sunucusu bulunamadı."
        return 0
    fi

    echo -e "\n${YELLOW}Kaldırmak istediğiniz MCP sunucu(lar)ını seçin:${NC}"
    local index=1
    for server in "${mcp_servers[@]}"; do
        echo -e "  ${GREEN}${index}${NC} - ${server}"
        index=$((index + 1))
    done
    echo -e "  ${RED}0${NC} - İptal"
    echo -e "${YELLOW}[BİLGİ]${NC} Birden fazla seçim için virgülle ayırın (örn: 1,2,3)"

    read -r -p "Seçiminiz: " choices
    if [ "$choices" = "0" ] || [ -z "$choices" ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} Temizleme işlemi iptal edildi."
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
            echo -e "${RED}[HATA]${NC} Geçersiz seçim: $choice"
            continue
        fi

        local idx=$((choice - 1))
        if [ $idx -lt 0 ] || [ $idx -ge ${#mcp_servers[@]} ]; then
            echo -e "${RED}[HATA]${NC} Desteklenmeyen seçim: $choice"
            continue
        fi

        local server_to_remove="${mcp_servers[$idx]}"
        echo -e "${YELLOW}[BİLGİ]${NC} '${server_to_remove}' MCP sunucusu kaldırılıyor..."
        
        jq "del(.mcpServers.\"$server_to_remove\")" "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[BAŞARILI]${NC} '${server_to_remove}' kaldırıldı."
            changes_made=true
        else
            echo -e "${RED}[HATA]${NC} '${server_to_remove}' kaldırılırken hata oluştu."
        fi
    done

    if [ "$changes_made" = true ]; then
        mv "$temp_file" "$SETTINGS_FILE"
        echo -e "${GREEN}[BAŞARILI]${NC} Değişiklikler $SETTINGS_FILE dosyasına kaydedildi."
    else
        rm -f "$temp_file"
        echo -e "${YELLOW}[BİLGİ]${NC} Hiçbir değişiklik yapılmadı."
    fi
}

# Ana kaldırma akışı
main() {
    cleanup_qwen_mcp
}

main
