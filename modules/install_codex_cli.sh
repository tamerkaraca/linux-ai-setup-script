#!/bin/bash

# Ortak yardımcı fonksiyonları yükle
# shellcheck source=/dev/null
source "/mnt/d/ai/modules/utils.sh"

# OpenAI Codex CLI kurulumu
install_codex_cli() {
    local interactive_mode=${1:-true}
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} OpenAI Codex CLI kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    detect_package_manager # Ensure PKG_MANAGER, INSTALL_CMD are set

    npm install -g @openai/codex
    
    echo -e "${GREEN}[BAŞARILI]${NC} Codex CLI sürümü: $(codex --version)"
    
    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}╔═══════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}   Codex CLI Kimlik Doğrulama Seçenekleri:${NC}"
        echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}"
        echo -e "${GREEN}Seçenek 1:${NC} ChatGPT hesabı ile giriş (Önerilen)"
        echo -e "  • ChatGPT Plus, Pro, Business, Edu veya Enterprise planı gereklidir"
        echo -e "  • Kullanım kredileri dahildir"
        echo -e "  • Komut: ${GREEN}codex${NC} çalıştırın ve 'Sign in with ChatGPT' seçeneğini seçin"
        echo -e "\n${GREEN}Seçenek 2:${NC} OpenAI API Key ile giriş"
        echo -e "  • https://platform.openai.com/api-keys adresinden API key alın"
        echo -e "  • Environment variable olarak ayarlayın: ${GREEN}export OPENAI_API_KEY=\"your-key\"${NC}"
        echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}\n"
        
        echo -e "${YELLOW}[BİLGİ]${NC} Hangi yöntemi kullanmak istersiniz?"
        echo -e "  ${GREEN}1${NC} - ChatGPT hesabı ile giriş (Önerilen)"
        echo -e "  ${GREEN}2${NC} - OpenAI API Key ile giriş"
        echo -e "  ${GREEN}3${NC} - Manuel olarak daha sonra yapacağım"
        read -r -p "Seçiminiz (1/2/3): " auth_choice
        
        case $auth_choice in
            1)
                echo -e "\n${YELLOW}[BİLGİ]${NC} Codex başlatılıyor, ChatGPT ile giriş yapın..."
                echo -e "${YELLOW}[BİLGİ]${NC} Tarayıcıda açılan sayfadan giriş yapın."
                echo -e "${YELLOW}[BİLGİ]${NC} Giriş tamamlandıktan sonra buraya dönün.\n"
                codex --auth-only 2>/dev/null || codex
                ;;
            2)
                echo -e "\n${YELLOW}[BİLGİ]${NC} OpenAI API Key girişi"
                read -r -p "OpenAI API Key'inizi girin: " OPENAI_KEY
                
                if [ -n "$OPENAI_KEY" ]; then
                    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
                        if [ -f "$rc_file" ]; then
                            if ! grep -q 'OPENAI_API_KEY' "$rc_file"; then
                                echo '' >> "$rc_file"
                                echo "export OPENAI_API_KEY=\"$OPENAI_KEY\"" >> "$rc_file"
                                echo -e "${GREEN}[BAŞARILI]${NC} API Key $rc_file dosyasına eklendi"
                            fi
                        fi
                    done
                    
                    export OPENAI_API_KEY="$OPENAI_KEY"
                    echo -e "${GREEN}[BAŞARILI]${NC} API Key ayarlandı"
                else
                    echo -e "${RED}[HATA]${NC} API Key boş olamaz!"
                fi
                ;;
            3)
                echo -e "${YELLOW}[BİLGİ]${NC} Kimlik doğrulama atlandı. Daha sonra yapabilirsiniz."
                ;;
            *)
                echo -e "${RED}[HATA]${NC} Geçersiz seçim!"
                ;;
        esac
    else
        echo -e "\n${YELLOW}[BİLGİ]${NC} 'Tümünü Kur' modunda kimlik doğrulama atlandı."
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen daha sonra manuel olarak '${GREEN}codex${NC}' komutunu çalıştırarak kimlik doğrulama yapın."
    fi
    
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Codex CLI Kullanım İpuçları:"
    echo -e "  ${GREEN}•${NC} Başlatmak için: ${GREEN}codex${NC}"
    echo -e "  ${GREEN}•${NC} Suggest modu: ${GREEN}codex --suggest${NC}"
    echo -e "  ${GREEN}•${NC} Auto Edit modu: ${GREEN}codex --auto-edit${NC}"
    echo -e "  ${GREEN}•${NC} Full Auto modu: ${GREEN}codex --full-auto${NC}"
    echo -e "  ${GREEN}•${NC} Model değiştirme: ${GREEN}codex -m o3${NC}"
    echo -e "  ${GREEN}•${NC} Güncelleme: ${GREEN}codex --upgrade${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${GREEN}[BAŞARILI]${NC} OpenAI Codex CLI kurulumu tamamlandı!"
}

# Ana kurulum akışı
main() {
    install_codex_cli "$@"
}

main
