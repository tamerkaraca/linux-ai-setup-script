#!/bin/bash
set -euo pipefail

DOC_URL="https://docs.factory.ai/cli/getting-started/quickstart"
INSTALL_SCRIPT_URL="https://app.factory.ai/cli"

UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"

CURRENT_LANG="${LANGUAGE:-en}"
if [ "$CURRENT_LANG" = "tr" ]; then
    INFO_TAG="[BİLGİ]"
    WARN_TAG="[UYARI]"
    ERROR_TAG="[HATA]"
    SUCCESS_TAG="[BAŞARILI]"
else
    INFO_TAG="[INFO]"
    WARN_TAG="[WARNING]"
    ERROR_TAG="[ERROR]"
    SUCCESS_TAG="[SUCCESS]"
fi

declare -A DROID_TEXT_EN=(
    [title]="Starting Droid CLI installation..."
    [already_installed]="Droid CLI is already installed"
    [curl_note]="Downloading and running the official Factory installer:"
    [install_failed]="Droid CLI installation failed. Please retry or follow the manual steps:"
    [success]="Droid CLI installation completed"
    [tips_header]="Quick usage tips:"
    [tip_launch]="• Launch the interactive UI: droid"
    [tip_exec]="• Headless/CI mode: droid exec \"<command>\""
    [tip_docs]="• Docs: https://docs.factory.ai/cli/getting-started/quickstart"
    [path_warn]="Droid CLI executable not found on PATH. Please reopen your terminal or follow the official docs."
    [xdg_check]="Checking for xdg-utils (required on Linux)..."
    [xdg_install]="Installing xdg-utils automatically..."
    [xdg_manual]="xdg-utils is missing. Please install it manually (e.g., sudo apt-get install xdg-utils) and rerun this option."
)

declare -A DROID_TEXT_TR=(
    [title]="Droid CLI kurulumu başlatılıyor..."
    [already_installed]="Droid CLI zaten kurulu"
    [curl_note]="Resmi Factory kurulum betiği indiriliyor ve çalıştırılıyor:"
    [install_failed]="Droid CLI kurulumu başarısız oldu. Lütfen tekrar deneyin veya dokümanı izleyin:"
    [success]="Droid CLI kurulumu tamamlandı"
    [tips_header]="Hızlı kullanım ipuçları:"
    [tip_launch]="• Etkileşimli arayüz: droid"
    [tip_exec]="• Headless/CI modu: droid exec \"<komut>\""
    [tip_docs]="• Doküman: https://docs.factory.ai/cli/getting-started/quickstart"
    [path_warn]="Droid CLI komutu PATH içinde bulunamadı. Terminalinizi kapatıp açın veya resmi dokümandaki adımları izleyin."
    [xdg_check]="Linux ortamında xdg-utils paketi kontrol ediliyor..."
    [xdg_install]="xdg-utils paketi otomatik kuruluyor..."
    [xdg_manual]="xdg-utils bulunamadı. Lütfen manuel olarak kurun (örn: sudo apt-get install xdg-utils) ve menüyü tekrar çalıştırın."
)

droid_text() {
    local key="$1"
    local default_value="${DROID_TEXT_EN[$key]:-$key}"
    if [ "$CURRENT_LANG" = "tr" ]; then
        echo "${DROID_TEXT_TR[$key]:-$default_value}"
    else
        echo "$default_value"
    fi
}

droid_ensure_xdg_utils() {
    if command -v xdg-open >/dev/null 2>&1; then
        return 0
    fi

    echo -e "${YELLOW}${INFO_TAG}${NC} $(droid_text xdg_check)"

    case "${PKG_MANAGER:-}" in
        apt|dnf|yum|pacman)
            echo -e "${YELLOW}${INFO_TAG}${NC} $(droid_text xdg_install)"
            if ! eval "$INSTALL_CMD xdg-utils"; then
                echo -e "${YELLOW}${WARN_TAG}${NC} $(droid_text xdg_manual)"
                return 1
            fi
            ;;
        *)
            echo -e "${YELLOW}${WARN_TAG}${NC} $(droid_text xdg_manual)"
            return 1
            ;;
    esac

    return 0
}

install_droid_cli() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(droid_text title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if command -v droid >/dev/null 2>&1; then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(droid_text already_installed): $(droid --version 2>/dev/null || echo \"unknown version\")"
        return 0
    fi

    droid_ensure_xdg_utils || true

    echo -e "\n${YELLOW}${INFO_TAG}${NC} $(droid_text curl_note)"
    echo -e "  ${GREEN}curl -fsSL ${INSTALL_SCRIPT_URL} | sh${NC}\n"

    if ! curl -fsSL "$INSTALL_SCRIPT_URL" | sh; then
        echo -e "${RED}${ERROR_TAG}${NC} $(droid_text install_failed) ${DOC_URL}"
        return 1
    fi

    hash -r 2>/dev/null || true

    if ! command -v droid >/dev/null 2>/dev/null; then
        echo -e "${YELLOW}${WARN_TAG}${NC} $(droid_text path_warn)"
        return 1
    fi

    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(droid_text success): $(droid --version 2>/dev/null || echo \"unknown version\")"
    echo -e "\n${CYAN}${INFO_TAG}${NC} $(droid_text tips_header)"
    echo -e "  ${GREEN}$(droid_text tip_launch)${NC}"
    echo -e "  ${GREEN}$(droid_text tip_exec)${NC}"
    echo -e "  ${GREEN}$(droid_text tip_docs)${NC}"
}

main() {
    install_droid_cli
}

main
