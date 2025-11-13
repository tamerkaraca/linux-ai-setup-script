#!/bin/bash

UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"

CURRENT_LANG="${LANGUAGE:-en}"


declare -A GH_TEXT_EN=(
    [title]="Starting GitHub CLI (gh) installation (see https://github.com/cli/cli)"
    [already_installed]="GitHub CLI is already installed"
    [installing]="Installing GitHub CLI via system package manager..."
    [apt_repo]="Adding the official GitHub CLI repository for Debian/Ubuntu..."
    [dnf_repo]="Adding the official GitHub CLI repository for Fedora/RHEL/CentOS..."
    [pacman_repo]="Installing GitHub CLI via pacman..."
    [unsupported_pm]="Unsupported package manager. Please install GitHub CLI manually."
    [success]="GitHub CLI installation completed"
    [tips_header]="GitHub CLI tips:"
    [tip_login]="• Authenticate: gh auth login"
    [tip_status]="• Check status: gh status"
    [tip_help]="• More info: gh help or https://cli.github.com/"
    [failed]="GitHub CLI installation failed"
    [wget_hint]="Ensuring wget and keyring prerequisites are present..."
)

declare -A GH_TEXT_TR=(
    [title]="GitHub CLI (gh) kurulumu başlatılıyor (https://github.com/cli/cli)"
    [already_installed]="GitHub CLI zaten kurulu"
    [installing]="GitHub CLI sistem paket yöneticisi ile kuruluyor..."
    [apt_repo]="Debian/Ubuntu için resmi GitHub CLI deposu ekleniyor..."
    [dnf_repo]="Fedora/CentOS/RHEL için resmi GitHub CLI deposu ekleniyor..."
    [pacman_repo]="GitHub CLI pacman ile kuruluyor..."
    [unsupported_pm]="Desteklenmeyen paket yöneticisi. Lütfen GitHub CLI'yi manuel kurun."
    [success]="GitHub CLI kurulumu tamamlandı"
    [tips_header]="GitHub CLI kullanım ipuçları:"
    [tip_login]="• Giriş: gh auth login"
    [tip_status]="• Durum: gh status"
    [tip_help]="• Daha fazla bilgi: gh help veya https://cli.github.com/"
    [failed]="GitHub CLI kurulumu başarısız"
    [wget_hint]="wget ve anahtar gereksinimleri kontrol ediliyor..."
)

gh_text() {
    local key="$1"
    local default_value="${GH_TEXT_EN[$key]:-$key}"
    if [ "$CURRENT_LANG" = "tr" ]; then
        echo "${GH_TEXT_TR[$key]:-$default_value}"
    else
        echo "$default_value"
    fi
}


# GitHub CLI kurulumu
install_github_cli() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(gh_text title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if command -v gh &> /dev/null; then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(gh_text already_installed): $(gh --version | head -n 1)"
        return 0
    fi

    echo -e "${YELLOW}${INFO_TAG}${NC} $(gh_text installing)"

    case "$PKG_MANAGER" in
        apt)
            echo -e "${YELLOW}${INFO_TAG}${NC} $(gh_text apt_repo)"
            echo -e "${YELLOW}${INFO_TAG}${NC} $(gh_text wget_hint)"
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
            echo -e "${YELLOW}${INFO_TAG}${NC} $(gh_text dnf_repo)"
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
            echo -e "${YELLOW}${INFO_TAG}${NC} $(gh_text pacman_repo)"
            sudo pacman -S github-cli --noconfirm
            ;;
        *)
            echo -e "${RED}${ERROR_TAG}${NC} $(gh_text unsupported_pm)"
            return 1
            ;;
    esac

    if command -v gh &> /dev/null; then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(gh_text success): $(gh --version | head -n 1)"
        echo -e "\n${CYAN}${INFO_TAG}${NC} $(gh_text tips_header)"
        echo -e "  ${GREEN}$(gh_text tip_login)${NC}"
        echo -e "  ${GREEN}$(gh_text tip_status)${NC}"
        echo -e "  ${GREEN}$(gh_text tip_help)${NC}"
    else
        echo -e "${RED}${ERROR_TAG}${NC} $(gh_text failed)"
        return 1
    fi
}

# Ana kurulum akışı
main() {
    install_github_cli
}

main
