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

# AI Framework Kaldırma menüsü
remove_ai_frameworks_menu() {
    detect_package_manager # Ensure PKG_MANAGER, INSTALL_CMD are set

    while true; do
        clear
        echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║        AI Framework Kaldırma Menüsü           ║${NC}"
        echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}\n"
        echo -e "  ${GREEN}1${NC} - SuperGemini Framework'ü kaldır"
        echo -e "  ${GREEN}2${NC} - SuperQwen Framework'ü kaldır"
        echo -e "  ${GREEN}3${NC} - SuperClaude Framework'ü kaldır"
        echo -e "  ${GREEN}4${NC} - Tüm AI Frameworklerini kaldır"
        echo -e "  ${RED}0${NC} - Ana Menüye Dön"
        echo -e "\n${YELLOW}[BİLGİ]${NC} Birden fazla seçim için virgülle ayırın (örn: 1,3)"

        read -r -p "Seçiminiz: " removal_choices
        if [ "$removal_choices" = "0" ] || [ -z "$removal_choices" ]; then
            echo -e "${YELLOW}[BİLGİ]${NC} Ana menüye dönülüyor..."
            break
        fi

        local all_removed=false
        IFS=',' read -ra SELECTED_REMOVE <<< "$removal_choices"

        for choice in "${SELECTED_REMOVE[@]}"; do
            choice=$(echo "$choice" | tr -d ' ')
            case $choice in
                1) run_module "remove_supergemini" ;;
                2) run_module "remove_superqwen" ;;
                3) run_module "remove_superclaude" ;;
                4) 
                    run_module "remove_supergemini"
                    run_module "remove_superqwen"
                    run_module "remove_superclaude"
                    all_removed=true
                    ;;
                *) echo -e "${RED}[HATA]${NC} Geçersiz seçim: $choice" ;;
            esac
        done

        if [ "$all_removed" = true ]; then
            break
        fi

        read -r -p "Başka bir AI Framework kaldırmak ister misiniz? (e/h) [h]: " continue_choice
        if [[ "$continue_choice" != "e" && "$continue_choice" != "E" ]]; then
            break
        fi
    done
}

# Ana kaldırma akışı
main() {
    remove_ai_frameworks_menu
}

main
