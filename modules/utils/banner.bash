#!/bin/bash

export SCRIPT_VERSION="V2.0.1"

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"
: "${BOLD:=$'\033[1m'}"

HEADING_WIDTH=71

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
    local version_value="${GREEN}${version}${NC}"
    local version_plain
    version_plain=$(printf '%s' "$version_value" | sed -r 's/\x1B\[[0-9;]*[A-Za-z]//g')
    local version_pad=$((50 - ${#version_plain}))
    printf "%s %-20s: %s%*s%s\n" "${BLUE}║${NC}" "${version_label}" "$version_value" "$version_pad" "" "${BLUE}║${NC}"
    local developer_value="${GREEN}Tamer KARACA${NC}"
    local developer_plain
    developer_plain=$(printf '%s' "$developer_value" | sed -r 's/\x1B\[[0-9;]*[A-Za-z]//g')
    local developer_pad=$((50 - ${#developer_plain}))
    printf "%s %-20s: %s%*s%s\n" "${BLUE}║${NC}" "${developer_label}" "$developer_value" "$developer_pad" "" "${BLUE}║${NC}"
    local github_value="${CYAN}@tamerkaraca${NC}"
    local github_plain
    github_plain=$(printf '%s' "$github_value" | sed -r 's/\x1B\[[0-9;]*[A-Za-z]//g')
    local github_pad=$((50 - ${#github_plain}))
    printf "%s %-20s: %s%*s%s\n" "${BLUE}║${NC}" "${github_label}" "$github_value" "$github_pad" "" "${BLUE}║${NC}"
    local repo_value="${CYAN}${repo}${NC}"
    local repo_plain
    repo_plain=$(printf '%s' "$repo_value" | sed -r 's/\x1B\[[0-9;]*[A-Za-z]//g')
    local repo_pad=$((50 - ${#repo_plain}))
    printf "%s %-20s: %s%*s%s\n" "${BLUE}║${NC}" "${repo_label}" "$repo_value" "$repo_pad" "" "${BLUE}║${NC}"
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