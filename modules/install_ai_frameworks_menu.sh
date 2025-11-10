#!/bin/bash

# Ortak yardımcı fonksiyonları yükle
# shellcheck source=/dev/null
source "./modules/utils.sh"

# Script çalıştırma fonksiyonu (setup script'inin güncel versiyonu ile aynı davranış)
run_module() {
    local module_name="$1"
    local local_path="./modules/${module_name}.sh"
    local module_url="$BASE_URL/$module_name.sh"
    shift

    if [ -f "$local_path" ]; then
        echo -e "${CYAN}[BİLGİ]${NC} $module_name modülü yerel dosyadan çalıştırılıyor..."
        if ! PKG_MANAGER="$PKG_MANAGER" UPDATE_CMD="$UPDATE_CMD" INSTALL_CMD="$INSTALL_CMD" bash "$local_path" "$@"; then
            echo -e "${RED}[HATA]${NC} $module_name modülü çalıştırılırken bir hata oluştu."
            return 1
        fi
    else
        echo -e "${CYAN}[BİLGİ]${NC} $module_name modülü indiriliyor ve çalıştırılıyor..."
        if ! curl -fsSL "$module_url" | PKG_MANAGER="$PKG_MANAGER" UPDATE_CMD="$UPDATE_CMD" INSTALL_CMD="$INSTALL_CMD" bash -s -- "$@"; then
            echo -e "${RED}[HATA]${NC} $module_name modülü çalıştırılırken bir hata oluştu."
            return 1
        fi
    fi
    return 0
}

# AI Frameworks menüsü
install_ai_frameworks_menu() {

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

            read -r -p "Seçiminiz: " framework_choices </dev/tty
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

        read -r -p "Başka bir AI Framework kurmak ister misiniz? (e/h) [h]: " continue_choice </dev/tty
        if [[ "$continue_choice" != "e" && "$continue_choice" != "E" ]]; then
            break
        fi
    done
}

# Ana kurulum akışı
main() {
    install_ai_frameworks_menu "$@"
}

main "$@"
