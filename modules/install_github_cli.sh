#!/bin/bash

# Ortak yardımcı fonksiyonları yükle


# GitHub CLI kurulumu
install_github_cli() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} GitHub CLI (gh) kurulumu başlatılıyor (https://github.com/cli/cli)...
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"



    if command -v gh &> /dev/null; then
        echo -e "${GREEN}[BAŞARILI]${NC} GitHub CLI zaten kurulu: $(gh --version | head -n 1)"
        return 0
    fi

    echo -e "${YELLOW}[BİLGİ]${NC} GitHub CLI sistem paket yöneticisi ile kuruluyor..."

    case "$PKG_MANAGER" in
        apt)
            echo -e "${YELLOW}[BİLGİ]${NC} Debian/Ubuntu için GitHub CLI deposu ekleniyor..."
            (type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
                && sudo mkdir -p -m 755 /etc/apt/keyrings \
                && out=$(mktemp) && wget -nv -O"$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
                && sudo install -o root -g root -m 0644 "$out" /etc/apt/keyrings/githubcli-archive-keyring.gpg \
                && sudo mkdir -p -m 755 /etc/apt/sources.list.d \
                && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
                && sudo apt update \
                && sudo apt install gh -y
            ;;
        dnf|yum)
            echo -e "${YELLOW}[BİLGİ]${NC} Fedora/CentOS/RHEL için GitHub CLI deposu ekleniyor..."
            if [ "$PKG_MANAGER" = "dnf" ]; then
                sudo dnf install 'dnf-command(config-manager)' -y
                sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
                sudo dnf install gh -y
            else # yum
                sudo yum install 'yum-command(config-manager)' -y
                sudo yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
                sudo yum install gh -y
            fi
            ;;
        pacman)
            echo -e "${YELLOW}[BİLGİ]${NC} Arch Linux için GitHub CLI kuruluyor..."
            sudo pacman -S github-cli --noconfirm
            ;;
        *)
            echo -e "${RED}[HATA]${NC} Desteklenmeyen paket yöneticisi: $PKG_MANAGER. GitHub CLI manuel kurulmalı."
            return 1
            ;;
    esac

    if command -v gh &> /dev/null; then
        echo -e "${GREEN}[BAŞARILI]${NC} GitHub CLI kurulumu tamamlandı: $(gh --version | head -n 1)"
        echo -e "\n${CYAN}[BİLGİ]${NC} GitHub CLI Kullanım İpuçları:"
        echo -e "  ${GREEN}•${NC} Giriş yapmak için: ${GREEN}gh auth login${NC}"
        echo -e "  ${GREEN}•${NC} Mevcut durumu görmek için: ${GREEN}gh status${NC}"
        echo -e "  ${GREEN}•${NC} Daha fazla bilgi: ${GREEN}gh help${NC} veya https://cli.github.com/"
    else
        echo -e "${RED}[HATA]${NC} GitHub CLI kurulumu başarısız!"
        return 1
    fi
}

# Ana kurulum akışı
main() {
    install_github_cli
}

main
