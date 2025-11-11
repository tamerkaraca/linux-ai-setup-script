#!/bin/bash

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"
: "${BOLD:=$'\033[1m'}"

HEADING_WIDTH=70
BANNER_AI_TITLE="AI CLI ARACLARI"
BANNER_DEV_TITLE="GELISTIRME ARACLARI"

center_text() {
    local text="$1"
    local width="$2"
    local plain
    plain=$(printf '%s' "$text" | sed -r 's/\x1B\[[0-9;]*[A-Za-z]//g')
    local len=${#plain}
    if [ "$len" -ge "$width" ]; then
        printf "%s" "$text"
        return
    fi
    local padding=$((width - len))
    local left=$((padding / 2))
    local right=$((padding - left))
    printf "%*s%s%*s" "$left" "" "$text" "$right" ""
}

panel_line_raw() {
    local content="$1"
    local plain
    plain=$(printf '%s' "$content" | sed -r 's/\x1B\[[0-9;]*[A-Za-z]//g')
    local len=${#plain}
    local pad=$((HEADING_WIDTH - len + 1))
    [ "$pad" -lt 1 ] && pad=1
    printf "%s %s%*s%s\n" "${BLUE}║${NC}" "$content" "$pad" "" "${BLUE}║${NC}"
}

print_heading_panel() {
    local -a titles=("$@")
    local border_top="╔════════════════════════════════════════════════════════════════════════╗"
    local border_bottom="╚════════════════════════════════════════════════════════════════════════╝"
    echo -e "${BLUE}${border_top}${NC}"
    for title in "${titles[@]}"; do
        panel_line_raw "$(center_text "${BOLD}${title}${NC}" "$HEADING_WIDTH")"
    done
    echo -e "${BLUE}${border_bottom}${NC}"
}

print_info_panel() {
    local version="$1"
    local repo="$2"

    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════╗${NC}"
    panel_line_raw "${BOLD}Script Bilgileri${NC}"
    echo -e "${BLUE}╠════════════════════════════════════════════════════════════════════════╣${NC}"
    panel_line_raw "Versiyon      : ${GREEN}${version}${NC}"
    panel_line_raw "Geliştirici   : ${GREEN}Tamer KARACA${NC}"
    panel_line_raw "GitHub Hesabı : ${CYAN}@tamerkaraca${NC}"
    panel_line_raw "Depo          : ${CYAN}${repo}${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════╝${NC}"
}

render_setup_banner() {
    local version="$1"
    local repo="$2"
    print_heading_panel "$BANNER_AI_TITLE" "$BANNER_DEV_TITLE"
    print_info_panel "$version" "$repo"
    echo
}
