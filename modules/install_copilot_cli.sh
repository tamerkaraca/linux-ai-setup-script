#!/bin/bash

# Ortak yardımcı fonksiyonları yükle


# GitHub Copilot CLI kurulumu
install_copilot_cli() {
    local interactive_mode=${1:-true}
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} GitHub Copilot CLI kurulumu (https://github.com/github/copilot-cli talimatları) başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"



    if ! npm install -g @github/copilot; then
        echo -e "${RED}[HATA]${NC} 'npm install -g @githubnext/github-copilot-cli' komutu başarısız oldu."
        return 1
    fi

    if ! command -v copilot &> /dev/null; then
        echo -e "${RED}[HATA]${NC} GitHub Copilot CLI komutu bulunamadı. PATH ayarlarını kontrol edin."
        return 1
    fi

    echo -e "${GREEN}[BAŞARILI]${NC} GitHub Copilot CLI sürümü: $(copilot --version)"

    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}╔═══════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}   Resmi GitHub yönergelerine göre kimlik doğrulama:${NC}"
        echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}"
        echo -e "  ${GREEN}1.${NC} ${GREEN}copilot auth login${NC} komutunu çalıştırın."
        echo -e "  ${GREEN}2.${NC} Tarayıcıda açılan GitHub Copilot sayfasından erişimi onaylayın."
        echo -e "  ${GREEN}3.${NC} ${GREEN}copilot auth activate${NC} ile kabuk entegrasyonunu tamamlayın."
        echo -e "\n${YELLOW}[BİLGİ]${NC} İşlemleri sizin yerinize başlatıyoruz; gerekirse komutları manuel tekrarlayabilirsiniz.\n"



        read -r -p "Devam etmek için Enter'a basın..." </dev/tty
    else
        echo -e "\n${YELLOW}[BİLGİ]${NC} 'Tümünü Kur' modunda kimlik doğrulama atlandı."
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen '${GREEN}copilot auth login${NC}' ve '${GREEN}copilot auth activate${NC}' komutlarını daha sonra çalıştırın."
    fi

    local detected_shell
    detected_shell=$(basename "${SHELL:-bash}")
    case "$detected_shell" in
        bash|zsh) ;; 
        *) detected_shell="bash" ;; 
    esac

    local rc_file
    if [ "$detected_shell" = "zsh" ]; then
        rc_file="$HOME/.zshrc"
    else
        rc_file="$HOME/.bashrc"
    fi
    touch "$rc_file"

    local alias_line
    alias_line=$(printf "eval \"\\\$(copilot alias -- %s)\"" "$detected_shell")

    if copilot alias -- "$detected_shell" >/dev/null 2>&1; then
        eval "$(copilot alias -- "$detected_shell")" 2>/dev/null || true

        if ! grep -Fq 'copilot alias' "$rc_file"; then
            {
                echo ''
                echo '# GitHub Copilot CLI aliasları'
                echo "$alias_line"
            } >> "$rc_file"
            echo -e "${GREEN}[BAŞARILI]${NC} Copilot CLI aliasları ${rc_file} dosyasına eklendi."
        else
            echo -e "${YELLOW}[BİLGİ]${NC} Copilot CLI aliasları zaten ${rc_file} dosyasında mevcut."
        fi
    else
        echo -e "${YELLOW}[UYARI]${NC} 'copilot alias -- ${detected_shell}' komutu başarısız oldu. Aliasları manuel oluşturun."
    fi

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} GitHub Copilot CLI Kullanım İpuçları:"
    echo -e "  ${GREEN}•${NC} Kod isteği: ${GREEN}copilot suggest \"read a csv\"${NC}"
    echo -e "  ${GREEN}•${NC} Komut açıklaması: ${GREEN}copilot explain \"what does ls -la do\"${NC}"
    echo -e "  ${GREEN}•${NC} Aliasları tekrar yükleme: ${GREEN}eval \"\\]$(copilot alias -- ${detected_shell})\"${NC}"
    echo -e "  ${GREEN}•${NC} Daha fazla bilgi: https://github.com/github/copilot-cli${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    echo -e "\n${GREEN}[BAŞARILI]${NC} GitHub Copilot CLI kurulumu tamamlandı!"
}

# Ana kurulum akışı
main() {
    install_copilot_cli "$@"
}

main
