#!/bin/bash
set -euo pipefail

# Ortak yardımcı fonksiyonları yükle
UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

declare -A GIT_CONFIG_TEXT_EN=(
    ["title"]="Starting Git Global Configuration..."
    ["git_not_found"]="'git' command not found. Please run the system update first."
    ["prompt_intro"]="Please enter your information for the global .gitconfig."
    ["prompt_note"]="Note: This information will be used for your commits. (Press Enter to keep the current value)"
    ["prompt_name"]="Your Git Username"
    ["prompt_email"]="Your Git Email Address"
    ["name_example"]="e.g., Tamer KARACA"
    ["email_example"]="e.g., tamer@smedyazilim.com"
    ["name_set"]="Git username set: %s"
    ["name_kept"]="Username not changed, keeping current value: %s"
    ["email_set"]="Git email address set: %s"
    ["email_kept"]="Email address not changed, keeping current value: %s"
    ["not_set"]="Not set"
    ["config_done"]="Git configuration completed."
)

declare -A GIT_CONFIG_TEXT_TR=(
    ["title"]="Git Global Yapılandırması Başlatılıyor..."
    ["git_not_found"]="'git' komutu bulunamadı. Lütfen önce sistem güncellemesini çalıştırın."
    ["prompt_intro"]="Lütfen global .gitconfig için bilgilerinizi girin."
    ["prompt_note"]="Not: Bu bilgiler commit atarken kullanılacaktır. (Mevcut değeri korumak için Enter'a basın)"
    ["prompt_name"]="Git Kullanıcı Adınız"
    ["prompt_email"]="Git E-posta Adresiniz"
    ["name_example"]="örn: Tamer KARACA"
    ["email_example"]="örn: tamer@smedyazilim.com"
    ["name_set"]="Git kullanıcı adı ayarlandı: %s"
    ["name_kept"]="Kullanıcı adı değiştirilmedi, mevcut değer korunuyor: %s"
    ["email_set"]="Git e-posta adresi ayarlandı: %s"
    ["email_kept"]="E-posta adresi değiştirilmedi, mevcut değer korunuyor: %s"
    ["not_set"]="Ayarlanmamış"
    ["config_done"]="Git yapılandırması tamamlandı."
)

git_config_text() {
    local key="$1"
    local default_value="${GIT_CONFIG_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${GIT_CONFIG_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

# Git yapılandırması
configure_git() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(git_config_text title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if ! command -v git &> /dev/null; then
        echo -e "${RED}${ERROR_TAG}${NC} $(git_config_text git_not_found)"
        return 1
    fi

    # Mevcut değerleri al
    local current_name
    current_name=$(git config --global user.name)
    local current_email
    current_email=$(git config --global user.email)

    echo -e "${YELLOW}${INFO_TAG}${NC} $(git_config_text prompt_intro)"
    echo -e "${CYAN}$(git_config_text prompt_note)${NC}"

    # Yeni kullanıcı adını sor
    read -r -p "$(git_config_text prompt_name) [${current_name:-$(git_config_text name_example)}]: " GIT_USER_NAME </dev/tty
    
    # Yeni e-postayı sor
    read -r -p "$(git_config_text prompt_email) [${current_email:-$(git_config_text email_example)}]: " GIT_USER_EMAIL </dev/tty

    # Eğer yeni bir değer girildiyse güncelle
    if [ -n "$GIT_USER_NAME" ]; then
        git config --global user.name "$GIT_USER_NAME"
        printf -v msg "$(git_config_text name_set)" "$GIT_USER_NAME"
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $msg"
    else
        printf -v msg "$(git_config_text name_kept)" "${current_name:-$(git_config_text not_set)}"
        echo -e "${YELLOW}${INFO_TAG}${NC} $msg"
    fi

    # Eğer yeni bir değer girildiyse güncelle
    if [ -n "$GIT_USER_EMAIL" ]; then
        git config --global user.email "$GIT_USER_EMAIL"
        printf -v msg "$(git_config_text email_set)" "$GIT_USER_EMAIL"
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $msg"
    else
        printf -v msg "$(git_config_text email_kept)" "${current_email:-$(git_config_text not_set)}"
        echo -e "${YELLOW}${INFO_TAG}${NC} $msg"
    fi

    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(git_config_text config_done)"
}

# Ana kurulum akışı
main() {
    configure_git
}

main
