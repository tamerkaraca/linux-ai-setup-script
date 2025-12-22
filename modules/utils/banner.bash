#!/bin/bash

export SCRIPT_VERSION="V3.1.0"

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
    local len
    len=$(get_visible_length "$text")
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
    local len
    len=$(get_visible_length "$content")
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

# Function to get the visible length of a string, stripping ANSI escape codes
get_visible_length() {
    printf '%s' "$1" | sed -r 's/\x1B\[[0-9;]*[A-Za-z]//g' | wc -m
}

print_info_panel() {
    local version="$1"
    local repo="$2"
    local info_title
    local version_label
    local developer_label
    local github_label
    local repo_label

    if [ "${LANGUAGE:-en}" = "en" ]; then
        info_title="Script Information"
        version_label="Version"
        developer_label="Developer"
        github_label="GitHub Account"
        repo_label="Repository"
    else
        info_title="Script Bilgileri"
        version_label="Versiyon"
        developer_label="Geliştirici"
        github_label="GitHub Hesabı"
        repo_label="Depo"
    fi

    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════╗${NC}"
    panel_line_raw "$(center_text "${BOLD}${info_title}${NC}" "$HEADING_WIDTH")"
    echo -e "${BLUE}╠════════════════════════════════════════════════════════════════════════╣${NC}"

    local col1_width=20 # Width for labels like "Version"
    local col2_width=$((HEADING_WIDTH - col1_width - 2)) # Remaining width for values

    # Version Line
    local version_line="${version_label}"
    local version_value="${GREEN}${version}${NC}"
    local version_formatted=$(printf "%-*s: %s" "$col1_width" "$version_line" "$version_value")
    panel_line_raw "$(center_text "$version_formatted" "$HEADING_WIDTH")"
    
    # Developer Line
    local developer_line="${developer_label}"
    local developer_value="${GREEN}Tamer KARACA${NC}"
    local developer_formatted=$(printf "%-*s: %s" "$col1_width" "$developer_line" "$developer_value")
    panel_line_raw "$(center_text "$developer_formatted" "$HEADING_WIDTH")"

    # GitHub Line
    local github_line="${github_label}"
    local github_value="${CYAN}@tamerkaraca${NC}"
    local github_formatted=$(printf "%-*s: %s" "$col1_width" "$github_line" "$github_value")
    panel_line_raw "$(center_text "$github_formatted" "$HEADING_WIDTH")"

    # Repo Line
    local repo_line="${repo_label}"
    local repo_value="${CYAN}${repo}${NC}"
    local repo_formatted=$(printf "%-*s: %s" "$col1_width" "$repo_line" "$repo_value")
    panel_line_raw "$(center_text "$repo_formatted" "$HEADING_WIDTH")"
    
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