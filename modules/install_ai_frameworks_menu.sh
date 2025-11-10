#!/bin/bash

# Ortak yardımcı fonksiyonları yükle
# shellcheck source=/dev/null
source "./modules/utils.sh"

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

# AI Frameworks menüsü
install_ai_frameworks_menu() {
    detect_package_manager # Ensure PKG_MANAGER, INSTALL_CMD are set
    
    local install_all="${1:-}" # "all" parametresi gelirse hepsini kur

    while true; do
        if [ -z "$install_all" ]; then
            clear
            echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
            echo -e "${BLUE}║          AI Frameworks Kurulum Menüsü         ║${NC}"
            echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}\n"
            echo -e "  ${GREEN}1${NC} - SuperGemini Framework"
            echo -e "  ${GREEN}2${NC} - SuperQwen Framework"
            echo -e "  ${GREEN}3${NC} - SuperClaude Framework"
            echo -e "  ${GREEN}4${NC} - Tüm AI Frameworkleri"
            echo -e "  ${RED}0${NC} - Ana Menüye Dön"
            echo -e "\n${YELLOW}[BİLGİ]${NC} Birden fazla seçim için virgülle ayırın (örn: 1,2)"

            read -r -p "Seçiminiz: " framework_choices
            if [ "$framework_choices" = "0" ] || [ -z "$framework_choices" ]; then
                echo -e "${YELLOW}[BİLGİ]${NC} Ana menüye dönülüyor..."
                break
            fi
        else
            framework_choices="4" # "all" parametresi gelirse tümünü seç
        fi

        # Pipx kontrolü
        if ! command -v pipx &> /dev/null; then
            echo -e "${YELLOW}[UYARI]${NC} AI Frameworks için önce Pipx kurulumu yapılıyor..."
            if ! command -v python3 &> /dev/null; then
                 echo -e "${YELLOW}[UYARI]${NC} Pipx için önce Python kurulumu yapılıyor..."
                 install_python
            fi
            install_pipx
        fi

        local all_installed=false
        IFS=',' read -ra SELECTED_FW <<< "$framework_choices"

        for choice in "${SELECTED_FW[@]}"; do
            choice=$(echo "$choice" | tr -d ' ')
            case $choice in
                1) run_module "install_supergemini" ;;
                2) run_module "install_superqwen" ;;
                3) run_module "install_superclaude" ;;
                4) 
                    run_module "install_supergemini"
                    run_module "install_superqwen"
                    run_module "install_superclaude"
                    all_installed=true
                    ;;
                *) echo -e "${RED}[HATA]${NC} Geçersiz seçim: $choice" ;;
            esac
        done
        
        if [ "$all_installed" = true ] || [ -n "$install_all" ]; then
            break
        fi

        read -r -p "Başka bir AI Framework kurmak ister misiniz? (e/h) [h]: " continue_choice
        if [[ "$continue_choice" != "e" && "$continue_choice" != "E" ]]; then
            break
        fi
    done
}

# Ana kurulum akışı
main() {
    install_ai_frameworks_menu "$@"
}

main
