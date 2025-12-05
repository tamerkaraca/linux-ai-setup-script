#!/bin/bash
set -euo pipefail

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
    echo "[ERROR] Unable to load utils.bash (tried $utils_local)" >&2
    exit 1
fi

if [ -f "$platform_local" ]; then
    # shellcheck source=/dev/null
    source "$platform_local"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/platform_detection.bash" "modules/utils/platform_detection.bash"
fi

# --- Start: Codex-specific logic ---

declare -A CODEX_TEXT_EN=(
    ["install_title"]="Starting OpenAI Codex CLI installation..."
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

# --- End: Codex-specific logic ---

main() {
    local interactive_mode=${1:-true}
    
    log_info_detail "$(codex_text install_title)"
    
    # Use the universal installer from utils.sh
    # It handles checks, installation, and basic logging
    install_package "OpenAI Codex CLI" "npm" "codex" "@openai/codex"
    local install_status=$?

    if [ $install_status -ne 0 ]; then
        log_error_detail "Codex CLI installation failed. Aborting."
        return 1
    fi
    
    # If the command is still not found after successful install (e.g. PATH issue), exit.
    if ! command -v codex &> /dev/null; then
        log_error_detail "Codex command not found after installation. Aborting post-install steps."
        return 1
    fi

    # Proceed with Codex-specific post-installation steps (auth)
    if [ "$interactive_mode" = true ]; then
        echo
        log_info_detail "$(codex_text auth_heading)"
        echo -e "${GREEN}$(codex_text option1_title)${NC}\n  $(codex_text option1_line1)\n  $(codex_text option1_line2)\n  $(codex_text option1_line3)"
        echo -e "\n${GREEN}$(codex_text option2_title)${NC}\n  $(codex_text option2_line1)\n  $(codex_text option2_line2)\n"
        
        log_info_detail "$(codex_text prompt_method)"
        echo -e "  ${GREEN}1${NC} - $(codex_text option1_title)"
        echo -e "  ${GREEN}2${NC} - $(codex_text option2_title)"
        echo -e "  ${GREEN}3${NC} - $(codex_text skip_auth)"
        read -r -p "$(codex_text prompt_choice)" auth_choice </dev/tty
        
        case $auth_choice in
            1)
                log_info_detail "$(codex_text launch_codex)"
                log_info_detail "$(codex_text browser_hint)"
                log_info_detail "$(codex_text return_hint)"
                codex --auth-only 2>/dev/null || codex
                ;;
            2)
                read -r -p "$(codex_text api_key_prompt)" OPENAI_KEY </dev/tty
                if [ -n "$OPENAI_KEY" ]; then
                    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
                        if [ -f "$rc_file" ]; then
                             echo '' >> "$rc_file"
                             echo "export OPENAI_API_KEY=\"$OPENAI_KEY\"" >> "$rc_file"
                             log_success_detail "$(codex_printf \"msg\" \"api_key_saved\" \"$rc_file\" && echo \"$msg\")"
                        fi
                    done
                    export OPENAI_API_KEY="$OPENAI_KEY"
                    log_success_detail "$(codex_text api_key_set)"
                else
                    log_error_detail "$(codex_text api_key_empty)"
                fi
                ;;
            3)
                log_info_detail "$(codex_text skip_auth)"
                ;;
            *)
                log_error_detail "$(codex_text invalid_choice)"
                ;;
        esac
    else
        echo
        log_info_detail "$(codex_text bulk_skip)"
        log_info_detail "$(codex_printf \"msg\" \"bulk_reminder\" \"${GREEN}codex${NC}\" && echo \"$msg\")"
    fi
    
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    log_info_detail "$(codex_text usage_heading)"
    echo -e "  ${GREEN}•${NC} $(codex_text usage_start): ${GREEN}codex${NC}"
    echo -e "  ${GREEN}•${NC} $(codex_text usage_suggest): ${GREEN}codex --suggest${NC}"
    echo -e "  ${GREEN}•${NC} $(codex_text usage_auto_edit): ${GREEN}codex --auto-edit${NC}"
    echo -e "  ${GREEN}•${NC} $(codex_text usage_full_auto): ${GREEN}codex --full-auto${NC}"
    echo -e "  ${GREEN}•${NC} $(codex_text usage_model): ${GREEN}codex -m o3${NC}"
    echo -e "  ${GREEN}•${NC} $(codex_text usage_upgrade): ${GREEN}codex --upgrade${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    echo
    log_success_detail "$(codex_text install_done)"
}

main "$@"