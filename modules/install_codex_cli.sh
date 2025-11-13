#!/bin/bash

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

declare -A CODEX_TEXT_EN=(
    ["install_title"]="Starting OpenAI Codex CLI installation..."
    ["version_info"]="Codex CLI version: %s"
    ["auth_heading"]="Codex CLI Authentication Options:"
    ["option1_title"]="Option 1: Sign in with ChatGPT (recommended)"
    ["option1_line1"]="• Requires ChatGPT Plus, Pro, Business, Edu, or Enterprise"
    ["option1_line2"]="• Usage credits are included"
    ["option1_line3"]="• Command: run 'codex' and pick \"Sign in with ChatGPT\""
    ["option2_title"]="Option 2: Sign in with an OpenAI API key"
    ["option2_line1"]="• Generate a key at https://platform.openai.com/api-keys"
    ["option2_line2"]="• Add it to your shell: export OPENAI_API_KEY=\"your-key\""
    ["prompt_method"]="Which method would you like to use?"
    ["prompt_choice"]="Your choice (1/2/3): "
    ["launch_codex"]="Launching Codex—sign in with ChatGPT in the browser."
    ["browser_hint"]="Complete the login flow in the browser window."
    ["return_hint"]="Return here once authentication finishes."
    ["api_key_prompt"]="Enter your OpenAI API key: "
    ["api_key_saved"]="API key added to %s"
    ["api_key_set"]="API key exported for this session."
    ["api_key_empty"]="API key cannot be empty!"
    ["skip_auth"]="Authentication skipped. You can do it later."
    ["bulk_skip"]="Authentication skipped in 'Install All' mode."
    ["bulk_reminder"]="Please run %s later to authenticate."
    ["invalid_choice"]="Invalid selection!"
    ["usage_heading"]="Codex CLI Usage Tips:"
    ["usage_start"]="Start Codex"
    ["usage_suggest"]="Suggest mode"
    ["usage_auto_edit"]="Auto Edit mode"
    ["usage_full_auto"]="Full Auto mode"
    ["usage_model"]="Switch model"
    ["usage_upgrade"]="Upgrade Codex CLI"
    ["install_done"]="OpenAI Codex CLI installation completed!"
)

declare -A CODEX_TEXT_TR=(
    ["install_title"]="OpenAI Codex CLI kurulumu başlatılıyor..."
    ["version_info"]="Codex CLI sürümü: %s"
    ["auth_heading"]="Codex CLI Kimlik Doğrulama Seçenekleri:"
    ["option1_title"]="Seçenek 1: ChatGPT hesabı ile giriş (önerilen)"
    ["option1_line1"]="• ChatGPT Plus, Pro, Business, Edu veya Enterprise gerektirir"
    ["option1_line2"]="• Kullanım kredileri dahildir"
    ["option1_line3"]="• Komut: 'codex' çalıştırın ve \"Sign in with ChatGPT\" seçeneğini seçin"
    ["option2_title"]="Seçenek 2: OpenAI API Key ile giriş"
    ["option2_line1"]="• https://platform.openai.com/api-keys adresinden anahtar oluşturun"
    ["option2_line2"]="• Ortam değişkeni olarak ayarlayın: export OPENAI_API_KEY=\"anahtarınız\""
    ["prompt_method"]="Hangi yöntemi kullanmak istersiniz?"
    ["prompt_choice"]="Seçiminiz (1/2/3): "
    ["launch_codex"]="Codex başlatılıyor; ChatGPT ile tarayıcıdan giriş yapın."
    ["browser_hint"]="Tarayıcıda açılan pencerede oturumu tamamlayın."
    ["return_hint"]="İşlem bitince buraya dönün."
    ["api_key_prompt"]="OpenAI API Key'inizi girin: "
    ["api_key_saved"]="API Key %s dosyasına eklendi"
    ["api_key_set"]="API Key bu oturum için ayarlandı."
    ["api_key_empty"]="API Key boş olamaz!"
    ["skip_auth"]="Kimlik doğrulama atlandı. Daha sonra yapabilirsiniz."
    ["bulk_skip"]="'Tümünü Kur' modunda kimlik doğrulama atlandı."
    ["bulk_reminder"]="Daha sonra kimlik doğrulamak için %s komutunu çalıştırın."
    ["invalid_choice"]="Geçersiz seçim!"
    ["usage_heading"]="Codex CLI Kullanım İpuçları:"
    ["usage_start"]="Başlat"
    ["usage_suggest"]="Suggest modu"
    ["usage_auto_edit"]="Auto Edit modu"
    ["usage_full_auto"]="Full Auto modu"
    ["usage_model"]="Model değiştirme"
    ["usage_upgrade"]="Güncelle"
    ["install_done"]="OpenAI Codex CLI kurulumu tamamlandı!"
)

codex_text() {
    local key="$1"
    local default_value="${CODEX_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${CODEX_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

codex_printf() {
    local __out="$1"
    local __key="$2"
    shift 2
    local __fmt
    __fmt="$(codex_text "$__key")"
    # shellcheck disable=SC2059
    printf -v "$__out" "$__fmt" "$@"
}

# OpenAI Codex CLI kurulumu
install_codex_cli() {
    local interactive_mode=${1:-true}
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(codex_text install_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    npm install -g @openai/codex
    
    local codex_version_msg
    codex_printf codex_version_msg version_info "$(codex --version 2>/dev/null)"
    echo -e "${GREEN}${SUCCESS_TAG}${NC} ${codex_version_msg}"
    
    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}╔═══════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}   $(codex_text auth_heading)${NC}"
        echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}"
        echo -e "${GREEN}$(codex_text option1_title)${NC}"
        echo -e "  $(codex_text option1_line1)"
        echo -e "  $(codex_text option1_line2)"
        echo -e "  $(codex_text option1_line3)"
        echo -e "\n${GREEN}$(codex_text option2_title)${NC}"
        echo -e "  $(codex_text option2_line1)"
        echo -e "  $(codex_text option2_line2)"
        echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}\n"
        
        echo -e "${YELLOW}${INFO_TAG}${NC} $(codex_text prompt_method)"
        echo -e "  ${GREEN}1${NC} - $(codex_text option1_title)"
        echo -e "  ${GREEN}2${NC} - $(codex_text option2_title)"
        echo -e "  ${GREEN}3${NC} - $(codex_text skip_auth)"
        read -r -p "$(codex_text prompt_choice)" auth_choice </dev/tty
        
        case $auth_choice in
            1)
                echo -e "\n${YELLOW}${INFO_TAG}${NC} $(codex_text launch_codex)"
                echo -e "${YELLOW}${INFO_TAG}${NC} $(codex_text browser_hint)"
                echo -e "${YELLOW}${INFO_TAG}${NC} $(codex_text return_hint)\n"
                codex --auth-only 2>/dev/null || codex
                ;;
            2)
                read -r -p "$(codex_text api_key_prompt)" OPENAI_KEY </dev/tty
                
                if [ -n "$OPENAI_KEY" ]; then
                    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
                        if [ -f "$rc_file" ]; then
                            if ! grep -q 'OPENAI_API_KEY' "$rc_file"; then
                                echo '' >> "$rc_file"
                                echo "export OPENAI_API_KEY=\"$OPENAI_KEY\"" >> "$rc_file"
                                local codex_saved_msg
                                codex_printf codex_saved_msg api_key_saved "$rc_file"
                                echo -e "${GREEN}${SUCCESS_TAG}${NC} ${codex_saved_msg}"
                            fi
                        fi
                    done
                    
                    export OPENAI_API_KEY="$OPENAI_KEY"
                    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(codex_text api_key_set)"
                else
                    echo -e "${RED}${ERROR_TAG}${NC} $(codex_text api_key_empty)"
                fi
                ;;
            3)
                echo -e "${YELLOW}${INFO_TAG}${NC} $(codex_text skip_auth)"
                ;;
            *)
                echo -e "${RED}${ERROR_TAG}${NC} $(codex_text invalid_choice)"
                ;;
        esac
    else
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(codex_text bulk_skip)"
        local codex_bulk_msg
        codex_printf codex_bulk_msg bulk_reminder "${GREEN}codex${NC}"
        echo -e "${YELLOW}${INFO_TAG}${NC} ${codex_bulk_msg}"
    fi
    
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(codex_text usage_heading)"
    echo -e "  ${GREEN}•${NC} $(codex_text usage_start): ${GREEN}codex${NC}"
    echo -e "  ${GREEN}•${NC} $(codex_text usage_suggest): ${GREEN}codex --suggest${NC}"
    echo -e "  ${GREEN}•${NC} $(codex_text usage_auto_edit): ${GREEN}codex --auto-edit${NC}"
    echo -e "  ${GREEN}•${NC} $(codex_text usage_full_auto): ${GREEN}codex --full-auto${NC}"
    echo -e "  ${GREEN}•${NC} $(codex_text usage_model): ${GREEN}codex -m o3${NC}"
    echo -e "  ${GREEN}•${NC} $(codex_text usage_upgrade): ${GREEN}codex --upgrade${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${GREEN}${SUCCESS_TAG}${NC} $(codex_text install_done)"
}

# Ana kurulum akışı
main() {
    install_codex_cli "$@"
}

main "$@"
