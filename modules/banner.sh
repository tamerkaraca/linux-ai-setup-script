#!/bin/bash

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"
: "${BOLD:=$'\033[1m'}"

HEADING_WIDTH=70

declare -A BANNER_TEXT_EN=(
    ["ai_title"]="AI CLI TOOLS"
    ["dev_title"]="DEVELOPMENT TOOLS"
    ["info_title"]="Script Information"
    ["version"]="Version"
    ["developer"]="Developer"
    ["github_account"]="GitHub Account"
    ["repository"]="Repository"
)

declare -A BANNER_TEXT_TR=(
    ["ai_title"]="AI CLI ARAÇLARI"
    ["dev_title"]="GELİŞTİRME ARAÇLARI"
    ["info_title"]="Script Bilgileri"
    ["version"]="Versiyon"
    ["developer"]="Geliştirici"
    ["github_account"]="GitHub Hesabı"
    ["repository"]="Depo"
)

banner_text() {
    local key="$1"
    local default_value="${BANNER_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${BANNER_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

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
    panel_line_raw "${BOLD}$(banner_text info_title)${NC}"
    echo -e "${BLUE}╠════════════════════════════════════════════════════════════════════════╣${NC}"
    panel_line_raw "$(banner_text version)      : ${GREEN}${version}${NC}"
    panel_line_raw "$(banner_text developer)   : ${GREEN}Tamer KARACA${NC}"
    panel_line_raw "$(banner_text github_account) : ${CYAN}@tamerkaraca${NC}"
    panel_line_raw "$(banner_text repository)          : ${CYAN}${repo}${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════╝${NC}"
}

render_setup_banner() {
    local version="$1"
    local repo="$2"
    print_heading_panel "$(banner_text ai_title)" "$(banner_text dev_title)"
    print_info_panel "$version" "$repo"
    echo
}
