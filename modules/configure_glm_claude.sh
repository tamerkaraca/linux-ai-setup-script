#!/bin/bash
set -euo pipefail

# Ortak yardımcı fonksiyonları yükle
if [ -f "./modules/utils.sh" ]; then
    # shellcheck source=/dev/null
    source "./modules/utils.sh"
else
    BASE_URL="${BASE_URL:-https://raw.githubusercontent.com/tamerkaraca/linux-ai-setup-script/main/modules}"
    if command -v curl &> /dev/null; then
        # shellcheck disable=SC1090
        source <(curl -fsSL "$BASE_URL/utils.sh") || true
    fi
fi

CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

ensure_claude_settings_dir() {
    if [ ! -d "$CLAUDE_DIR" ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} Claude dizini oluşturuluyor..."
        mkdir -p "$CLAUDE_DIR"
    fi
}

read_current_env() {
    local key="$1"
    if [ -f "$SETTINGS_FILE" ]; then
        if command -v jq &> /dev/null; then
            jq -r --arg key "$key" '.env[$key] // ""' "$SETTINGS_FILE" 2>/dev/null || echo ""
        else
            grep -m1 "\"$key\"" "$SETTINGS_FILE" | sed -nE 's/.*"'"$key"'": *"(.*)".*/\1/p'
        fi
    fi
}

write_settings_file() {
    local content="$1"
    echo "$content" > "$SETTINGS_FILE"
    echo -e "${GREEN}[BAŞARILI]${NC} Yapılandırma kaydedildi: ${SETTINGS_FILE}"
}

# shellcheck disable=SC2120
configure_glm_provider() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Claude Code için GLM-4.6 yapılandırması başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    ensure_claude_settings_dir
    
    echo -e "\n${YELLOW}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}   GLM API Key Alma Talimatları:${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}1.${NC} https://z.ai/model-api adresine gidin"
    echo -e "${GREEN}2.${NC} Kayıt olun veya giriş yapın"
    echo -e "${GREEN}3.${NC} https://z.ai/manage-apikey/apikey-list sayfasından API Key oluşturun"
    echo -e "${GREEN}4.${NC} API Key'inizi kopyalayın"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}\n"
    
    local default_base_url="https://api.z.ai/api/anthropic"
    local current_api_key
    current_api_key=$(read_current_env "ANTHROPIC_AUTH_TOKEN")
    local GLM_BASE_URL="$default_base_url"

    local masked_key_display="Henüz ayarlı değil"
    if [ -n "$current_api_key" ]; then
        masked_key_display=$(mask_secret "$current_api_key")
    fi

    read -r -p "GLM API Key [${masked_key_display}]: " GLM_API_KEY </dev/tty
    
    if [ -z "$GLM_API_KEY" ]; then
        if [ -n "$current_api_key" ]; then
            GLM_API_KEY="$current_api_key"
            echo -e "${YELLOW}[BİLGİ]${NC} Mevcut API Key korunuyor."
        else
            echo -e "${RED}[HATA]${NC} API Key boş olamaz!"
            return 1
        fi
    fi
    
    echo -e "${YELLOW}[BİLGİ]${NC} settings.json dosyası oluşturuluyor..."
    
    write_settings_file "$(cat << EOF
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
)"
    
    echo -e "\n${YELLOW}[BİLGİ]${NC} Yapılandırma dosyası: $SETTINGS_FILE"
    echo -e "${YELLOW}[BİLGİ]${NC} Model yapılandırması:"
    echo -e "  ${GREEN}•${NC} Opus Model: GLM-4.6"
    echo -e "  ${GREEN}•${NC} Sonnet Model: GLM-4.6"
    echo -e "  ${GREEN}•${NC} Haiku Model: GLM-4.5-Air"
    echo -e "\n${YELLOW}[BİLGİ]${NC} Claude Code'u başlatmak için: ${GREEN}claude${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Model durumunu kontrol etmek için: ${GREEN}/status${NC} komutunu kullanın"
    
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} GLM Coding Plan hakkında:"
    echo -e "  ${GREEN}•${NC} $3/aydan başlayan fiyatlarla premium kodlama deneyimi"
    echo -e "  ${GREEN}•${NC} PRO ve üzeri planlarda Vision ve Web Search MCP desteği"
    echo -e "  ${GREEN}•${NC} Daha fazla bilgi: https://z.ai/subscribe"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
}

maybe_reinstall_claude_cli() {
    if ! command -v npm &> /dev/null; then
        echo -e "${YELLOW}[UYARI]${NC} npm bulunamadı; Claude Code CLI yeniden kurulumu atlandı."
        return 0
    fi
    read -r -p "Claude Code CLI'yi yeniden kurmak ister misiniz? (e/h) [h]: " reinstall_choice </dev/tty || true
    if [[ "$reinstall_choice" =~ ^[EeYy]$ ]]; then
        require_node_version 18 "Claude Code CLI"
        echo -e "${YELLOW}[BİLGİ]${NC} Claude Code CLI yeniden kuruluyor..."
        if npm_install_global_with_fallback "@anthropic-ai/claude-code" "Claude Code CLI"; then
            echo -e "${GREEN}[BAŞARILI]${NC} Claude Code CLI güncellendi."
        else
            echo -e "${RED}[HATA]${NC} Claude Code CLI yeniden kurulamadı."
        fi
    fi
}

# shellcheck disable=SC2120
configure_kimi_provider() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Moonshot (kimi-k2) sağlayıcısı için Claude Code yapılandırması başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    ensure_claude_settings_dir
    require_node_version 18 "Moonshot kimi-k2 Claude Code"

    echo -e "\n${YELLOW}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}   Moonshot API Key Alma Adımları:${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}1.${NC} https://platform.moonshot.ai/docs/guide/agent-support#install-claude-code yönergesindeki 'K2 Vendor Verifier' adımlarını tamamlayın."
    echo -e "${GREEN}2.${NC} https://platform.moonshot.ai/console/api-keys adresinden API key oluşturun."
    echo -e "${GREEN}3.${NC} API key'i kopyalayın (\"moonshot-\" ile başlar)."
    echo -e "${GREEN}4.${NC} Claude Code CLI'nin güncel olduğundan emin olun (gerekirse bu modül yeniden kurabilir)."
    echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}"

    maybe_reinstall_claude_cli

    local default_base_url="https://api.moonshot.ai/anthropic"
    local current_api_key
    current_api_key=$(read_current_env "ANTHROPIC_AUTH_TOKEN")

    local masked="Henüz ayarlı değil"
    if [ -n "$current_api_key" ]; then
        masked=$(mask_secret "$current_api_key")
    fi

    read -r -p "Moonshot API Key [${masked}]: " MOONSHOT_API_KEY </dev/tty
    if [ -z "$MOONSHOT_API_KEY" ]; then
        if [ -n "$current_api_key" ]; then
            MOONSHOT_API_KEY="$current_api_key"
            echo -e "${YELLOW}[BİLGİ]${NC} Mevcut API key korunuyor."
        else
            echo -e "${RED}[HATA]${NC} API key boş olamaz."
            return 1
        fi
    fi

    local MOONSHOT_BASE_URL="$default_base_url"

    echo -e "\n${YELLOW}[BİLGİ]${NC} Kullanmak istediğiniz modeli seçin:"
    echo -e "  ${GREEN}1${NC} kimi-k2-0711-preview (önerilen)"
    echo -e "  ${GREEN}2${NC} kimi-k2-turbo-preview"
    echo -e "  ${GREEN}3${NC} Manuel model adı gir"
    read -r -p "Seçiminiz [1]: " model_choice </dev/tty
    local selected_model
    case "${model_choice:-1}" in
        2) selected_model="kimi-k2-turbo-preview" ;;
        3)
            read -r -p "Model adı: " manual_model </dev/tty
            if [ -z "$manual_model" ]; then
                echo -e "${RED}[HATA]${NC} Model adı boş olamaz."
                return 1
            fi
            selected_model="$manual_model"
            ;;
        *) selected_model="kimi-k2-0711-preview" ;;
    esac

    write_settings_file "$(cat << EOF
{
  "env": {
      "ANTHROPIC_AUTH_TOKEN": "${MOONSHOT_API_KEY}",
      "ANTHROPIC_BASE_URL": "${MOONSHOT_BASE_URL}",
      "MOONSHOT_PROVIDER": "kimi-k2",
      "API_TIMEOUT_MS": "3000000",
      "ANTHROPIC_DEFAULT_OPUS_MODEL": "${selected_model}",
      "ANTHROPIC_DEFAULT_SONNET_MODEL": "${selected_model}",
      "ANTHROPIC_DEFAULT_HAIKU_MODEL": "${selected_model}"
  }
}
EOF
)"

    echo -e "\n${GREEN}[BAŞARILI]${NC} Moonshot (kimi-k2) yapılandırması tamamlandı."
    echo -e "${YELLOW}[BİLGİ]${NC} ${SETTINGS_FILE} dosyasında '${selected_model}' modeli varsayılan olarak ayarlandı."
    echo -e "${YELLOW}[BİLGİ]${NC} Claude Code CLI'de ${GREEN}claude${NC} çalıştırarak '${selected_model}' ile kodlama yapabilirsiniz."
}

configure_menu() {
    while true; do
        echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║      Claude Code Sağlayıcı Yapılandırması     ║${NC}"
        echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
        echo -e "  ${GREEN}1${NC} GLM-4.6 (z.ai) sağlayıcısı"
        echo -e "  ${GREEN}2${NC} Moonshot kimi-k2 sağlayıcısı"
        echo -e "  ${RED}0${NC} Ana menüye dön"
        read -r -p "Seçiminiz: " cfg_choice </dev/tty
        case "${cfg_choice:-}" in
            1)
                # shellcheck disable=SC2119
                configure_glm_provider
                ;;
            2)
                # shellcheck disable=SC2119
                configure_kimi_provider
                ;;
            0)
                echo -e "${YELLOW}[BİLGİ]${NC} Ana menüye dönülüyor..."
                return 0
                ;;
            *)
                echo -e "${RED}[HATA]${NC} Geçersiz seçim."
                ;;
        esac
    done
}

# Ana kurulum akışı
main() {
    configure_menu
}

main
select_base_url() {
    local provider_label="$1"
    local default_url="$2"
    local previous_url="$3"
    local has_previous="false"
    if [ -n "$previous_url" ] && [ "$previous_url" != "$default_url" ]; then
        has_previous="true"
    else
        previous_url=""
    fi

    echo -e "\n${YELLOW}[BİLGİ]${NC} ${provider_label} için base URL seçin:"
    echo -e "  ${GREEN}1${NC} Varsayılan (${default_url})"
    if [ "$has_previous" = "true" ]; then
        echo -e "  ${GREEN}2${NC} Mevcut değer (${previous_url})"
        echo -e "  ${GREEN}3${NC} Özel base URL gir"
    else
        echo -e "  ${GREEN}2${NC} Özel base URL gir"
    fi

    read -r -p "Seçiminiz [1]: " selection </dev/tty || true
    case "${selection:-1}" in
        1)
            echo "$default_url"
            ;;
        2)
            if [ "$has_previous" = "true" ]; then
                echo "$previous_url"
            else
                read -r -p "Base URL: " custom_url </dev/tty || true
                if [ -z "$custom_url" ]; then
                    echo "$default_url"
                else
                    echo "$custom_url"
                fi
            fi
            ;;
        3)
            read -r -p "Base URL: " custom_url </dev/tty || true
            if [ -z "$custom_url" ]; then
                echo "$default_url"
            else
                echo "$custom_url"
            fi
            ;;
        *)
            echo "$default_url"
            ;;
    esac
}
