#!/bin/bash

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"
: "${BOLD:=$'\033[1m'}"

HEADING_WIDTH=70

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
    local info_title="Script Bilgileri"
    local version_label="Versiyon"
    local developer_label="Geliştirici"
    local github_label="GitHub Hesabı"
    local repo_label="Depo"

    if [ "${LANGUAGE:-en}" = "en" ]; then
        info_title="Script Information"
        version_label="Version"
        developer_label="Developer"
        github_label="GitHub Account"
        repo_label="Repository"
    fi

    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════╗${NC}"
    panel_line_raw "$(center_text "${BOLD}${info_title}${NC}" "$HEADING_WIDTH")"
    echo -e "${BLUE}╠════════════════════════════════════════════════════════════════════════╣${NC}"
    printf "%s %-15s: %s%*s%s\n" "${BLUE}║${NC}" "${version_label}" "${GREEN}${version}${NC}" "45" "" "${BLUE}║${NC}"
    printf "%s %-15s: %s%*s%s\n" "${BLUE}║${NC}" "${developer_label}" "${GREEN}Tamer KARACA${NC}" "41" "" "${BLUE}║${NC}"
    printf "%s %-15s: %s%*s%s\n" "${BLUE}║${NC}" "${github_label}" "${CYAN}@tamerkaraca${NC}" "43" "" "${BLUE}║${NC}"
    printf "%s %-15s: %s%*s%s\n" "${BLUE}║${NC}" "${repo_label}" "${CYAN}${repo}${NC}" "8" "" "${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════╝${NC}"
}

render_setup_banner() {
    local version="$1"
    local repo="$2"
    local ai_title="AI CLI ARACLARI"
    local dev_title="GELISTIRME ARACLARI"

    if [ "${LANGUAGE:-en}" = "en" ]; then
        ai_title="AI CLI TOOLS"
        dev_title="DEVELOPMENT TOOLS"
    fi

    print_heading_panel "$ai_title" "$dev_title"
    print_info_panel "$version" "$repo"
    echo
}