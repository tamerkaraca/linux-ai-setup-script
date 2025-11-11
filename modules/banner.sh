#!/bin/bash

# Banner rendering helpers
: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${MAGENTA:=$'\033[0;35m'}"
: "${NC:=$'\033[0m'}"
: "${BOLD:=$'\033[1m'}"

BANNER_READY="${BANNER_READY:-false}"
# shellcheck disable=SC2034
RAINBOW_COLORS=("$RED" "$YELLOW" "$GREEN" "$CYAN" "$BLUE" "$MAGENTA")
# shellcheck disable=SC2034
BANNER_AI=(
"  ______   ______         ______   __        ______         ______   _______    ______    ______   __         ______   _______   ______ "
" /      \\ /      |       /      \\ /  |      /      |       /      \\ /       \\  /      \\  /      \\ /  |       /      \\ /       \\ /      |"
"/$$$$$$  |$$$$$$/       /$$$$$$  |$$ |      $$$$$$/       /$$$$$$  |$$$$$$$  |/$$$$$$  |/$$$$$$  |$$ |      /$$$$$$  |$$$$$$$  |$$$$$$/ "
"$$ |__$$ |  $$ |        $$ |  $$/ $$ |        $$ |        $$ |__$$ |$$ |__$$ |$$ |__$$ |$$ |  $$/ $$ |      $$ |__$$ |$$ |__$$ |  $$ |  "
"$$    $$ |  $$ |        $$ |      $$ |        $$ |        $$    $$ |$$    $$< $$    $$ |$$ |      $$ |      $$    $$ |$$    $$<   $$ |  "
"$$$$$$$$ |  $$ |        $$ |   __ $$ |        $$ |        $$$$$$$$ |$$$$$$$  |$$$$$$$$ |$$ |   __ $$ |      $$$$$$$$ |$$$$$$$  |  $$ |  "
"$$ |  $$ | _$$ |_       $$ \\__/  |$$ |_____  _$$ |_       $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ \\__/  |$$ |_____ $$ |  $$ |$$ |  $$ | _$$ |_ "
"$$ |  $$ |/ $$   |      $$    $$/ $$       |/ $$   |      $$ |  $$ |$$ |  $$ |$$ |  $$ |$$    $$/ $$       |$$ |  $$ |$$ |  $$ |/ $$   |"
"$$/   $$/ $$$$$$/        $$$$$$/  $$$$$$$$/ $$$$$$/       $$/   $$/ $$/   $$/ $$/   $$/  $$$$$$/  $$$$$$$$/ $$/   $$/ $$/   $$/ $$$$$$/ "
"                                                                                                                                       "
"                                                                                                                                       "
"                                                                                                                                       "
)
# shellcheck disable=SC2034
BANNER_AUTHOR=(
" ________                                                 __    __   ______   _______    ______    ______    ______                     "
"/        |                                               /  |  /  | /      \\ /       \\  /      \\  /      \\  /      \\                    "
"$$$$$$$$/______   _____  ____    ______    ______        $$ | /$$/ /$$$$$$  |$$$$$$$  |/$$$$$$  |/$$$$$$  |/$$$$$$  |                   "
"   $$ | /      \\ /     \\/    \\  /      \\  /      \\       $$ |/$$/  $$ |__$$ |$$ |__$$ |$$ |__$$ |$$ |  $$/ $$ |__$$ |                   "
"   $$ | $$$$$$  |$$$$$$ $$$$  |/$$$$$$  |/$$$$$$  |      $$  $$<   $$    $$ |$$    $$< $$    $$ |$$ |      $$    $$ |                   "
"   $$ | /    $$ |$$ | $$ | $$ |$$    $$ |$$ |  $$/       $$$$$  \\  $$$$$$$$ |$$$$$$$  |$$$$$$$$ |$$ |   __ $$$$$$$$ |                   "
"   $$ |/$$$$$$$ |$$ | $$ | $$ |$$$$$$$$/ $$ |            $$ |$$  \\ $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ \\__/  |$$ |  $$ |                   "
"   $$ |$$    $$ |$$ | $$ | $$ |$$       |$$ |            $$ | $$  |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$    $$/ $$ |  $$ |                   "
"   $$/  $$$$$$$/ $$/  $$/  $$/  $$$$$$$/ $$/             $$/   $$/ $$/   $$/ $$/   $$/ $$/   $$/  $$$$$$/  $$/   $$/                    "
"                                                                                                                                       "
"                                                                                                                                       "
"                                                                                                                                       "
)

print_banner_block() {
    local -n ref="$1"
    local idx=0
    local total=${#RAINBOW_COLORS[@]}
    for line in "${ref[@]}"; do
        local color="${RAINBOW_COLORS[$((idx % total))]}"
        echo -e "${color}${line}${NC}"
        idx=$((idx + 1))
    done
}

print_info_panel() {
    local version="$1"
    local repo="$2"
    local inner_width=66

    panel_line() {
        local content="$1"
        printf "%s %-${inner_width}s %s\n" "${BLUE}║${NC}" "$content" "${BLUE}║${NC}"
    }

    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    panel_line "${BOLD}Script Bilgileri${NC}"
    echo -e "${BLUE}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    panel_line "Versiyon : ${GREEN}${version}${NC}"
    panel_line "GitHub   : ${CYAN}${repo}${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
}

render_setup_banner() {
    local version="$1"
    local repo="$2"
    if ensure_toilet; then
        toilet -f mini "AI CLI ARACLARI KURULUMU" --gay
        toilet -f mini "TAMER KARACA" --metal
    else
        print_banner_block BANNER_AI
        print_banner_block BANNER_AUTHOR
    fi
    print_info_panel "$version" "$repo"
    echo
}

ensure_toilet() {
    if command -v toilet &> /dev/null; then
        return 0
    fi

    if [ -z "${PKG_MANAGER:-}" ] || [ -z "${INSTALL_CMD:-}" ]; then
        echo -e "${YELLOW}[UYARI]${NC} 'toilet' komutu bulunamadı ve paket yöneticisi tespit edilemedi."
        return 1
    fi

    echo -e "${YELLOW}[BİLGİ]${NC} 'toilet' aracı kuruluyor..."
    case "$PKG_MANAGER" in
        apt|dnf|yum|pacman)
            if eval "$INSTALL_CMD" toilet; then
                return 0
            fi
            ;;
        *)
            echo -e "${RED}[HATA]${NC} $PKG_MANAGER paket yöneticisi için otomatik 'toilet' kurulumu desteklenmiyor."
            return 1
            ;;
    esac

    echo -e "${RED}[HATA]${NC} 'toilet' kurulumu başarısız oldu."
    return 1
}
