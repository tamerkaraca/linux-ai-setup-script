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
CURRENT_LANG="${LANGUAGE:-en}"

if [ "$CURRENT_LANG" = "tr" ]; then
    INFO_TAG="${INFO_TAG}"
    WARN_TAG="${WARN_TAG}"
    ERROR_TAG="${ERROR_TAG}"
    SUCCESS_TAG="${SUCCESS_TAG}"
else
    INFO_TAG="[INFO]"
    WARN_TAG="[WARNING]"
    ERROR_TAG="[ERROR]"
    SUCCESS_TAG="[SUCCESS]"
fi

declare -A GL_TEXT_EN=(
    ["glm_title"]="Starting GLM-4.6 configuration for Claude Code..."
    ["glm_steps_header"]="GLM API Key Instructions:"
    ["glm_step1"]="1. Visit https://z.ai/model-api"
    ["glm_step2"]="2. Sign up or sign in"
    ["glm_step3"]="3. Generate an API key at https://z.ai/manage-apikey/apikey-list"
    ["glm_step4"]="4. Copy your API key"
    ["glm_api_prompt"]="GLM API Key"
    ["glm_keep_existing"]="Keeping previously saved API key."
    ["glm_empty_key"]="API key cannot be empty!"
    ["glm_settings_creating"]="Creating settings.json..."
    ["glm_settings_path"]="Configuration file:"
    ["glm_config_header"]="Model summary:"
    ["glm_launch_hint"]="Launch Claude Code with: claude"
    ["glm_status_hint"]="Run /status inside Claude Code to check model state."
    ["glm_plan_header"]="About the GLM Coding Plan:"
    ["glm_plan_point1"]="• Premium coding experience starting at \$3/month"
    ["glm_plan_point2"]="• Vision & Web Search MCP support on PRO and higher tiers"
    ["glm_plan_point3"]="• Details: https://z.ai/subscribe"
    ["kimi_title"]="Starting Moonshot (kimi-k2) configuration for Claude Code..."
    ["kimi_steps_header"]="Moonshot API Key Steps:"
    ["kimi_step1"]="1. Complete the \"K2 Vendor Verifier\" steps in the official guide."
    ["kimi_step2"]="2. Create an API key at https://platform.moonshot.ai/console/api-keys"
    ["kimi_step3"]="3. Copy the key (it starts with \"moonshot-\")."
    ["kimi_step4"]="4. Ensure Claude Code CLI is up to date (this module can reinstall it)."
    ["kimi_reinstall_prompt"]="Reinstall Claude Code CLI? (y/n) [n]: "
    ["kimi_api_prompt"]="Moonshot API Key"
    ["kimi_keep_existing"]="Keeping previously saved API key."
    ["kimi_empty_key"]="API key cannot be empty."
    ["kimi_model_prompt"]="Select the preferred kimi model:"
    ["kimi_model_opt1"]="1 kimi-k2-0711-preview (recommended)"
    ["kimi_model_opt2"]="2 kimi-k2-turbo-preview"
    ["kimi_model_opt3"]="3 Enter model name manually"
    ["kimi_model_manual_prompt"]="Model name: "
    ["kimi_model_manual_error"]="Model name cannot be empty."
    ["reinstall_missing_npm"]="npm not found; skipping Claude Code CLI reinstall."
    ["reinstall_done"]="Claude Code CLI updated."
    ["reinstall_fail"]="Claude Code CLI could not be reinstalled."
    ["reinstall_running"]="Reinstalling Claude Code CLI..."
    ["api_masked_default"]="Not set"
    ["settings_saved"]="Configuration saved"
    ["kimi_success_title"]="Moonshot (kimi-k2) configuration completed."
    ["kimi_success_path"]="Settings file updated"
    ["kimi_success_run"]="Run claude to start coding with"
    ["prov_menu_title"]="Claude Code Provider Setup"
    ["prov_option1"]="GLM-4.6 (z.ai) provider"
    ["prov_option2"]="Moonshot kimi-k2 provider"
    ["prov_option0"]="Return to main menu"
    ["prov_prompt"]="Your choice"
    ["prov_returning"]="Returning to the main menu..."
    ["prov_invalid"]="Invalid selection."
)

declare -A GL_TEXT_TR=(
    ["glm_title"]="Claude Code için GLM-4.6 yapılandırması başlatılıyor..."
    ["glm_steps_header"]="GLM API Key Alma Talimatları:"
    ["glm_step1"]="1. https://z.ai/model-api adresine gidin"
    ["glm_step2"]="2. Kayıt olun veya giriş yapın"
    ["glm_step3"]="3. https://z.ai/manage-apikey/apikey-list sayfasından API Key oluşturun"
    ["glm_step4"]="4. API Key'inizi kopyalayın"
    ["glm_api_prompt"]="GLM API Key"
    ["glm_keep_existing"]="Mevcut API key korunuyor."
    ["glm_empty_key"]="API key boş olamaz!"
    ["glm_settings_creating"]="settings.json dosyası oluşturuluyor..."
    ["glm_config_header"]="Model yapılandırması:"
    ["glm_launch_hint"]="Claude Code'u başlatmak için: claude"
    ["glm_status_hint"]="Model durumunu kontrol etmek için: /status komutunu kullanın."
    ["glm_plan_header"]="GLM Coding Plan hakkında:"
    ["glm_plan_point1"]="• \$3/aydan başlayan fiyatlarla premium kodlama deneyimi"
    ["glm_plan_point2"]="• PRO ve üzeri planlarda Vision ve Web Search MCP desteği"
    ["glm_plan_point3"]="• Daha fazla bilgi: https://z.ai/subscribe"
    ["kimi_title"]="Moonshot (kimi-k2) sağlayıcısı için Claude Code yapılandırması başlatılıyor..."
    ["kimi_steps_header"]="Moonshot API Key Alma Adımları:"
    ["kimi_step1"]="1. Resmi rehberdeki \"K2 Vendor Verifier\" adımlarını tamamlayın."
    ["kimi_step2"]="2. https://platform.moonshot.ai/console/api-keys adresinden API key oluşturun."
    ["kimi_step3"]="3. API key'i kopyalayın (\"moonshot-\" ile başlar)."
    ["kimi_step4"]="4. Claude Code CLI'nin güncel olduğundan emin olun (gerekirse bu modül yeniden kurabilir)."
    ["kimi_reinstall_prompt"]="Claude Code CLI'yi yeniden kurmak ister misiniz? (e/h) [h]: "
    ["kimi_api_prompt"]="Moonshot API Key"
    ["kimi_keep_existing"]="Mevcut API key korunuyor."
    ["kimi_empty_key"]="API key boş olamaz."
    ["kimi_model_prompt"]="Kullanmak istediğiniz modeli seçin:"
    ["kimi_model_opt1"]="1 kimi-k2-0711-preview (önerilen)"
    ["kimi_model_opt2"]="2 kimi-k2-turbo-preview"
    ["kimi_model_opt3"]="3 Manuel model adı gir"
    ["kimi_model_manual_prompt"]="Model adı: "
    ["kimi_model_manual_error"]="Model adı boş olamaz."
    ["reinstall_missing_npm"]="npm bulunamadı; Claude Code CLI yeniden kurulumu atlandı."
    ["reinstall_done"]="Claude Code CLI güncellendi."
    ["reinstall_fail"]="Claude Code CLI yeniden kurulamadı."
    ["reinstall_running"]="Claude Code CLI yeniden kuruluyor..."
    ["api_masked_default"]="Henüz ayarlı değil"
    ["settings_saved"]="Yapılandırma kaydedildi"
    ["kimi_success_title"]="Moonshot (kimi-k2) yapılandırması tamamlandı."
    ["kimi_success_path"]="Güncellenen dosya"
    ["kimi_success_run"]="Claude Code'da claude komutunu çalıştırarak kullanabilirsiniz"
    ["prov_menu_title"]="Claude Code Sağlayıcı Yapılandırması"
    ["prov_option1"]="GLM-4.6 (z.ai) sağlayıcısı"
    ["prov_option2"]="Moonshot kimi-k2 sağlayıcısı"
    ["prov_option0"]="Ana menüye dön"
    ["prov_prompt"]="Seçiminiz"
    ["prov_returning"]="Ana menüye dönülüyor..."
    ["prov_invalid"]="Geçersiz seçim."
)

gl_text() {
    local key="$1"
    local default_value="${GL_TEXT_EN[$key]:-$key}"
    if [ "$CURRENT_LANG" = "tr" ]; then
        echo "${GL_TEXT_TR[$key]:-$default_value}"
    else
        echo "$default_value"
    fi
}

ensure_claude_settings_dir() {
    if [ ! -d "$CLAUDE_DIR" ]; then
        echo -e "${YELLOW}${INFO_TAG}${NC} Claude dizini oluşturuluyor..."
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
    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(gl_text settings_saved): ${SETTINGS_FILE}"
}

# shellcheck disable=SC2120
configure_glm_provider() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(gl_text glm_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    ensure_claude_settings_dir
    
    echo -e "\n${YELLOW}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}   $(gl_text glm_steps_header)${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}1.${NC} $(gl_text glm_step1)"
    echo -e "${GREEN}2.${NC} $(gl_text glm_step2)"
    echo -e "${GREEN}3.${NC} $(gl_text glm_step3)"
    echo -e "${GREEN}4.${NC} $(gl_text glm_step4)"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}\n"
    
    local default_base_url="https://api.z.ai/api/anthropic"
    local current_api_key
    current_api_key=$(read_current_env "ANTHROPIC_AUTH_TOKEN")
    local GLM_BASE_URL="$default_base_url"

    local masked_key_display="$(gl_text api_masked_default)"
    if [ -n "$current_api_key" ]; then
        masked_key_display=$(mask_secret "$current_api_key")
    fi

    read -r -p "$(gl_text glm_api_prompt) [${masked_key_display}]: " GLM_API_KEY </dev/tty
    
    if [ -z "$GLM_API_KEY" ]; then
        if [ -n "$current_api_key" ]; then
            GLM_API_KEY="$current_api_key"
            echo -e "${YELLOW}${INFO_TAG}${NC} $(gl_text glm_keep_existing)"
        else
            echo -e "${RED}${ERROR_TAG}${NC} $(gl_text glm_empty_key)"
            return 1
        fi
    fi
    
    echo -e "${YELLOW}${INFO_TAG}${NC} $(gl_text glm_settings_creating)"
    
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
    
    echo -e "\n${YELLOW}${INFO_TAG}${NC} $(gl_text glm_settings_path) $SETTINGS_FILE"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(gl_text glm_config_header)"
    echo -e "  ${GREEN}•${NC} Opus Model: GLM-4.6"
    echo -e "  ${GREEN}•${NC} Sonnet Model: GLM-4.6"
    echo -e "  ${GREEN}•${NC} Haiku Model: GLM-4.5-Air"
    echo -e "\n${YELLOW}${INFO_TAG}${NC} $(gl_text glm_launch_hint)"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(gl_text glm_status_hint)"
    
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(gl_text glm_plan_header)"
    echo -e "  ${GREEN}•${NC} $(gl_text glm_plan_point1)"
    echo -e "  ${GREEN}•${NC} $(gl_text glm_plan_point2)"
    echo -e "  ${GREEN}•${NC} $(gl_text glm_plan_point3)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
}

maybe_reinstall_claude_cli() {
    if ! command -v npm &> /dev/null; then
        echo -e "${YELLOW}${WARN_TAG}${NC} $(gl_text reinstall_missing_npm)"
        return 0
    fi
    read -r -p "$(gl_text kimi_reinstall_prompt)" reinstall_choice </dev/tty || true
    if [[ "$reinstall_choice" =~ ^([eEyY])$ ]]; then
        require_node_version 18 "Claude Code CLI"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(gl_text reinstall_running)"
        if npm_install_global_with_fallback "@anthropic-ai/claude-code" "Claude Code CLI"; then
            echo -e "${GREEN}${SUCCESS_TAG}${NC} $(gl_text reinstall_done)"
        else
            echo -e "${RED}${ERROR_TAG}${NC} $(gl_text reinstall_fail)"
        fi
    fi
}

# shellcheck disable=SC2120
configure_kimi_provider() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(gl_text kimi_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    ensure_claude_settings_dir
    require_node_version 18 "Moonshot kimi-k2 Claude Code"

    echo -e "\n${YELLOW}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}   $(gl_text kimi_steps_header)${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}1.${NC} $(gl_text kimi_step1)"
    echo -e "${GREEN}2.${NC} $(gl_text kimi_step2)"
    echo -e "${GREEN}3.${NC} $(gl_text kimi_step3)"
    echo -e "${GREEN}4.${NC} $(gl_text kimi_step4)"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}"

    maybe_reinstall_claude_cli

    local default_base_url="https://api.moonshot.ai/anthropic"
    local current_api_key
    current_api_key=$(read_current_env "ANTHROPIC_AUTH_TOKEN")

    local masked="$(gl_text api_masked_default)"
    if [ -n "$current_api_key" ]; then
        masked=$(mask_secret "$current_api_key")
    fi

    read -r -p "$(gl_text kimi_api_prompt) [${masked}]: " MOONSHOT_API_KEY </dev/tty
    if [ -z "$MOONSHOT_API_KEY" ]; then
        if [ -n "$current_api_key" ]; then
            MOONSHOT_API_KEY="$current_api_key"
            echo -e "${YELLOW}${INFO_TAG}${NC} $(gl_text kimi_keep_existing)"
        else
            echo -e "${RED}${ERROR_TAG}${NC} $(gl_text kimi_empty_key)"
            return 1
        fi
    fi

    local MOONSHOT_BASE_URL="$default_base_url"

    echo -e "\n${YELLOW}${INFO_TAG}${NC} $(gl_text kimi_model_prompt)"
    echo -e "  ${GREEN}1${NC} $(gl_text kimi_model_opt1)"
    echo -e "  ${GREEN}2${NC} $(gl_text kimi_model_opt2)"
    echo -e "  ${GREEN}3${NC} $(gl_text kimi_model_opt3)"
    read -r -p "$(gl_text prov_prompt) [1]: " model_choice </dev/tty
    local selected_model
    case "${model_choice:-1}" in
        2) selected_model="kimi-k2-turbo-preview" ;;
        3)
            read -r -p "$(gl_text kimi_model_manual_prompt)" manual_model </dev/tty
            if [ -z "$manual_model" ]; then
                echo -e "${RED}${ERROR_TAG}${NC} $(gl_text kimi_model_manual_error)"
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

    echo -e "\n${GREEN}${SUCCESS_TAG}${NC} $(gl_text kimi_success_title)"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(gl_text kimi_success_path): ${SETTINGS_FILE} (${selected_model})"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(gl_text kimi_success_run) ${GREEN}${selected_model}${NC}."
}

configure_menu() {
    while true; do
        echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
        printf "${BLUE}║%*s║${NC}\n" -43 " $(gl_text prov_menu_title) "
        echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
        echo -e "  ${GREEN}1${NC} $(gl_text prov_option1)"
        echo -e "  ${GREEN}2${NC} $(gl_text prov_option2)"
        echo -e "  ${RED}0${NC} $(gl_text prov_option0)"
        read -r -p "$(gl_text prov_prompt): " cfg_choice </dev/tty
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
                echo -e "${YELLOW}${INFO_TAG}${NC} $(gl_text prov_returning)"
                return 0
                ;;
            *)
                echo -e "${RED}${ERROR_TAG}${NC} $(gl_text prov_invalid)"
                ;;
        esac
    done
}

# Ana kurulum akışı
main() {
    configure_menu
}

main
