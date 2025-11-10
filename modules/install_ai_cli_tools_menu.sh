#!/bin/bash

# Ortak yardımcı fonksiyonları yükle
# shellcheck source=/dev/null
source "/mnt/d/ai/modules/utils.sh"

# GitHub'daki scriptlerin temel URL'si (setup script'inden kopyalandı)
BASE_URL="https://raw.githubusercontent.com/tamerkaraca/linux-ai-setup-script/main/modules"

# Script çalıştırma fonksiyonu (setup script'inden kopyalandı)
run_module() {
    local module_name="$1"
    local module_url="$BASE_URL/$module_name.sh"
    echo -e "${CYAN}[BİLGİ]${NC} $module_name modülü indiriliyor ve çalıştırılıyor..."
    if ! curl -fsSL "$module_url" | bash -s -- "${@:2}"; then
        echo -e "${RED}[HATA]${NC} $module_name modülü çalıştırılırken bir hata oluştu."
        return 1
    fi
    return 0
}

# AI CLI Araçları menüsü
install_ai_cli_tools_menu() {
    detect_package_manager # Ensure PKG_MANAGER, INSTALL_CMD are set

    local install_all="${1:-}" # "all" parametresi gelirse hepsini kur

    while true; do
        if [ -z "$install_all" ]; then
            clear
            echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
            echo -e "${BLUE}║           AI CLI Araçları Kurulum Menüsü        ║${NC}"
            echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}\n"
            echo -e "  ${GREEN}1${NC} - Claude Code CLI"
            echo -e "  ${GREEN}2${NC} - Gemini CLI"
            echo -e "  ${GREEN}3${NC} - OpenCode CLI"
            echo -e "  ${GREEN}4${NC} - Qoder CLI"
            echo -e "  ${GREEN}5${NC} - Qwen CLI"
            echo -e "  ${GREEN}6${NC} - OpenAI Codex CLI"
            echo -e "  ${GREEN}7${NC} - GitHub Copilot CLI"
            echo -e "  ${GREEN}8${NC} - Tüm AI CLI Araçları"
            echo -e "  ${RED}0${NC} - Ana Menüye Dön"
            echo -e "\n${YELLOW}[BİLGİ]${NC} Birden fazla seçim için virgülle ayırın (örn: 1,2,3)"

            read -r -p "Seçiminiz: " cli_choices
            if [ "$cli_choices" = "0" ] || [ -z "$cli_choices" ]; then
                echo -e "${YELLOW}[BİLGİ]${NC} Ana menüye dönülüyor..."
                break
            fi
        else
            cli_choices="8" # "all" parametresi gelirse tümünü seç
        fi

        local all_installed=false
        IFS=',' read -ra SELECTED_CLI <<< "$cli_choices"

        for choice in "${SELECTED_CLI[@]}"; do
            choice=$(echo "$choice" | tr -d ' ')
            case $choice in
                1) run_module "install_claude_code" "false" ;; # "false" interactive_mode için
                2) run_module "install_gemini_cli" "false" ;;
                3) run_module "install_opencode_cli" "false" ;;
                4) run_module "install_qoder_cli" "false" ;;
                5) run_module "install_qwen_cli" "false" ;;
                6) run_module "install_codex_cli" "false" ;;
                7) run_module "install_copilot_cli" "false" ;;
                8)
                    run_module "install_claude_code" "false"
                    run_module "install_gemini_cli" "false"
                    run_module "install_opencode_cli" "false"
                    run_module "install_qoder_cli" "false"
                    run_module "install_qwen_cli" "false"
                    run_module "install_codex_cli" "false"
                    run_module "install_copilot_cli" "false"
                    all_installed=true
                    ;;
                *) echo -e "${RED}[HATA]${NC} Geçersiz seçim: $choice" ;;
            esac
        done
        
        if [ "$all_installed" = true ] || [ -n "$install_all" ]; then
            break
        fi

        read -r -p "Başka bir AI CLI aracı kurmak ister misiniz? (e/h) [h]: " continue_choice
        if [[ "$continue_choice" != "e" && "$continue_choice" != "E" ]]; then
            break
        fi
    done
}

# Ana kurulum akışı
main() {
    install_ai_cli_tools_menu "$@"
}

main
