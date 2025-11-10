#!/bin/bash

# Ortak yardımcı fonksiyonları yükle
# shellcheck source=/dev/null
source "./modules/utils.sh"

# Script çalıştırma fonksiyonu (setup script'indeki ile aynı)
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

# MCP Sunucu Yönetimi menüsü
manage_mcp_servers_menu() {
    while true; do
        clear
        echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║            MCP Sunucu Yönetim Menüsü          ║${NC}"
        echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}\n"
        echo -e "  ${GREEN}1${NC} - SuperGemini MCP Sunucu Yönetimi"
        echo -e "  ${GREEN}2${NC} - SuperQwen MCP Sunucu Yönetimi"
        echo -e "  ${GREEN}3${NC} - SuperClaude MCP Sunucu Yönetimi"
        echo -e "  ${GREEN}4${NC} - Tüm Sunucuları Yönet"
        echo -e "  ${RED}0${NC} - Ana Menüye Dön"
        echo -e "\n${YELLOW}[BİLGİ]${NC} Birden fazla seçim için virgülle ayırın (örn: 1,2)"

        read -r -p "Seçiminiz: " mcp_choices </dev/tty
        if [ "$mcp_choices" = "0" ] || [ -z "$mcp_choices" ]; then
            echo -e "${YELLOW}[BİLGİ]${NC} Ana menüye dönülüyor..."
            break
        fi

        local all_managed=false
        IFS=',' read -ra SELECTED_MCP <<< "$mcp_choices"

        for choice in "${SELECTED_MCP[@]}"; do
            choice=$(echo "$choice" | tr -d ' ')
            case $choice in
                1) run_module "cleanup_magic_mcp" ;;
                2) run_module "cleanup_qwen_mcp" ;;
                3) run_module "cleanup_claude_mcp" ;;
                4) 
                    run_module "cleanup_magic_mcp"
                    run_module "cleanup_qwen_mcp"
                    run_module "cleanup_claude_mcp"
                    all_managed=true
                    ;;
                *) echo -e "${RED}[HATA]${NC} Geçersiz seçim: $choice" ;;
            esac
        done
        
        if [ "$all_managed" = true ]; then
            break
        fi

        read -r -p "Başka bir sunucu yönetmek ister misiniz? (e/h) [h]: " continue_choice </dev/tty
        if [[ "$continue_choice" != "e" && "$continue_choice" != "E" ]]; then
            break
        fi
    done
}

# Ana yönetim akışı
main() {
    manage_mcp_servers_menu
}

main
