#!/bin/bash

# Ortak yardımcı fonksiyonları yükle
# shellcheck source=/dev/null
source "./modules/utils.sh"

# Git yapılandırması
configure_git() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Git Global Yapılandırması Başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    detect_package_manager # Ensure PKG_MANAGER, INSTALL_CMD are set

    if ! command -v git &> /dev/null; then
        echo -e "${RED}[HATA]${NC} 'git' komutu bulunamadı. Lütfen önce sistem güncellemesini çalıştırın."
        return 1
    fi

    # Mevcut değerleri al
    local current_name
    current_name=$(git config --global user.name)
    local current_email
    current_email=$(git config --global user.email)

    echo -e "${YELLOW}[BİLGİ]${NC} Lütfen global .gitconfig için bilgilerinizi girin."
    echo -e "${CYAN}Not: Bu bilgiler commit atarken kullanılacaktır. (Mevcut değeri korumak için Enter'a basın)${NC}"

    # Yeni kullanıcı adını sor
    read -r -p "Git Kullanıcı Adınız [${current_name:-örn: Tamer KARACA}]: " GIT_USER_NAME
    
    # Yeni e-postayı sor
    read -r -p "Git E-posta Adresiniz [${current_email:-örn: tamer@smedyazilim.com}]: " GIT_USER_EMAIL

    # Eğer yeni bir değer girildiyse güncelle
    if [ -n "$GIT_USER_NAME" ]; then
        git config --global user.name "$GIT_USER_NAME"
        echo -e "${GREEN}[BAŞARILI]${NC} Git kullanıcı adı ayarlandı: $GIT_USER_NAME"
    else
        echo -e "${YELLOW}[BİLGİ]${NC} Kullanıcı adı değiştirilmedi, mevcut değer korunuyor: ${current_name:-'Ayarlanmamış'}"
    fi

    # Eğer yeni bir değer girildiyse güncelle
    if [ -n "$GIT_USER_EMAIL" ]; then
        git config --global user.email "$GIT_USER_EMAIL"
        echo -e "${GREEN}[BAŞARILI]${NC} Git e-posta adresi ayarlandı: $GIT_USER_EMAIL"
    else
        echo -e "${YELLOW}[BİLGİ]${NC} E-posta adresi değiştirilmedi, mevcut değer korunuyor: ${current_email:-'Ayarlanmamış'}"
    fi

    echo -e "${GREEN}[BAŞARILI]${NC} Git yapılandırması tamamlandı."
}

# Ana kurulum akışı
main() {
    configure_git
}

main
