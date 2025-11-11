#!/bin/bash

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"
: "${BOLD:=$'\033[1m'}"

BANNER_AI=("=== AI CLI ARACLARI ===")
BANNER_DEV=("=== GELISTIRME ARACLARI ===")

print_banner_block() {
    local -n banner_ref="$1"
    for line in "${banner_ref[@]}"; do
        echo -e "${CYAN}${line}${NC}"
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
    panel_line "${BOLD}Script Bilgileri                                                    ${NC}"
    echo -e "${BLUE}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    panel_line "Versiyon      : ${GREEN}${version}                                               ${NC}"
    panel_line "Geliştirici   : ${GREEN}Tamer KARACA                                        ${NC}"
    panel_line "GitHub Hesabı : ${CYAN}@tamerkaraca                                        ${NC}"
    panel_line "Depo          : ${CYAN}${repo}${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
}

render_setup_banner() {
    local version="$1"
    local repo="$2"
    print_banner_block BANNER_AI
    print_banner_block BANNER_DEV
    print_info_panel "$version" "$repo"
    echo
}
