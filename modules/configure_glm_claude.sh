#!/bin/bash

# Ortak yardımcı fonksiyonları yükle
# shellcheck source=/dev/null
source "/mnt/d/ai/modules/utils.sh"

# GLM-4.6 Claude Code yapılandırması
configure_glm_claude() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Claude Code için GLM-4.6 yapılandırması başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    detect_package_manager # Ensure PKG_MANAGER, INSTALL_CMD are set

    CLAUDE_DIR="$HOME/.claude"
    SETTINGS_FILE="$CLAUDE_DIR/settings.json"
    
    if [ ! -d "$CLAUDE_DIR" ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} Claude dizini oluşturuluyor..."
        mkdir -p "$CLAUDE_DIR"
    fi
    
    echo -e "\n${YELLOW}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}   GLM API Key Alma Talimatları:${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}1.${NC} https://z.ai/model-api adresine gidin"
    echo -e "${GREEN}2.${NC} Kayıt olun veya giriş yapın"
    echo -e "${GREEN}3.${NC} https://z.ai/manage-apikey/apikey-list sayfasından API Key oluşturun"
    echo -e "${GREEN}4.${NC} API Key'inizi kopyalayın"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}\n"
    
    local default_base_url="https://api.z.ai/api/anthropic"
    local current_api_key=""
    local current_base_url="$default_base_url"

    if [ -f "$SETTINGS_FILE" ]; then
        if command -v jq &> /dev/null; then
            current_api_key=$(jq -r '.env.ANTHROPIC_AUTH_TOKEN // ""' "$SETTINGS_FILE" 2>/dev/null || echo "")
            local detected_base
            detected_base=$(jq -r '.env.ANTHROPIC_BASE_URL // ""' "$SETTINGS_FILE" 2>/dev/null || echo "")
            if [ -n "$detected_base" ]; then
                current_base_url="$detected_base"
            fi
        else
            current_api_key=$(grep -m1 'ANTHROPIC_AUTH_TOKEN' "$SETTINGS_FILE" | sed -nE 's/.*"ANTHROPIC_AUTH_TOKEN": *"(.*)".*/\1/p')
            local raw_base
            raw_base=$(grep -m1 'ANTHROPIC_BASE_URL' "$SETTINGS_FILE" | sed -nE 's/.*"ANTHROPIC_BASE_URL": *"(.*)".*/\1/p')
            if [ -n "$raw_base" ]; then
                current_base_url="$raw_base"
            fi
        fi
    fi

    local masked_key_display="Henüz ayarlı değil"
    if [ -n "$current_api_key" ]; then
        masked_key_display=$(mask_secret "$current_api_key")
    fi

    read -r -p "GLM API Key [${masked_key_display}]: " GLM_API_KEY
    
    if [ -z "$GLM_API_KEY" ]; then
        if [ -n "$current_api_key" ]; then
            GLM_API_KEY="$current_api_key"
            echo -e "${YELLOW}[BİLGİ]${NC} Mevcut API Key korunuyor."
        else
            echo -e "${RED}[HATA]${NC} API Key boş olamaz!"
            return 1
        fi
    fi
    
    echo -e "\n${YELLOW}[BİLGİ]${NC} Base URL [Varsayılan: $current_base_url]"
    read -r -p "Base URL: " GLM_BASE_URL
    
    if [ -z "$GLM_BASE_URL" ]; then
        GLM_BASE_URL="$current_base_url"
    fi
    
    echo -e "${YELLOW}[BİLGİ]${NC} settings.json dosyası oluşturuluyor..."
    
    cat > "$SETTINGS_FILE" << EOF
{
  "env": {
      "ANTHROPIC_AUTH_TOKEN": "${GLM_API_KEY}",
      "ANTHROPIC_BASE_URL": "${GLM_BASE_URL}",
      "API_TIMEOUT_MS": "3000000",
      "ANTHROPIC_DEFAULT_OPUS_MODEL": "GLM-4.6",
      "ANTHROPIC_DEFAULT_SONNET_MODEL": "GLM-4.6",
      "ANTHROPIC_DEFAULT_HAIKU_MODEL": "GLM-4.5-Air"
  }
}
EOF
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[BAŞARILI]${NC} GLM-4.6 yapılandırması tamamlandı!"
        echo -e "\n${YELLOW}[BİLGİ]${NC} Yapılandırma dosyası: $SETTINGS_FILE"
        echo -e "${YELLOW}[BİLGİ]${NC} Model yapılandırması:"
        echo -e "  ${GREEN}•${NC} Opus Model: GLM-4.6"
        echo -e "  ${GREEN}•${NC} Sonnet Model: GLM-4.6"
        echo -e "  ${GREEN}•${NC} Haiku Model: GLM-4.5-Air"
        echo -e "\n${YELLOW}[BİLGİ]${NC} Claude Code'u başlatmak için: ${GREEN}claude${NC}"
        echo -e "${YELLOW}[BİLGİ]${NC} Model durumunu kontrol etmek için: ${GREEN}/status${NC} komutunu kullanın"
    else
        echo -e "${RED}[HATA]${NC} settings.json dosyası oluşturulamadı!"
        return 1
    fi
    
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} GLM Coding Plan hakkında:"
    echo -e "  ${GREEN}•${NC} $3/aydan başlayan fiyatlarla premium kodlama deneyimi"
    echo -e "  ${GREEN}•${NC} PRO ve üzeri planlarda Vision ve Web Search MCP desteği"
    echo -e "  ${GREEN}•${NC} Daha fazla bilgi: https://z.ai/subscribe"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
}

# Ana kurulum akışı
main() {
    configure_glm_claude
}

main
