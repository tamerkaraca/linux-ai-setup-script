#!/bin/bash
set -euo pipefail

: "${CLAUDE_AGENTS_DIR:=$HOME/.claude/agents}"
: "${CLAUDE_AGENTS_REPO:=https://github.com/contains-studio/agents.git}"

declare -A AGENT_TEXT_EN=(
    ["git_missing"]="'git' command not found. Please install git first."
    ["installing"]="Installing %s agent package..."
    ["cloning"]="Cloning git repository: %s"
    ["updating"]="Existing agents in %s will be replaced."
    ["copying"]="Copying agent files..."
    ["installed"]="%s agents installed (%s files)."
    ["location"]="Location: %s"
    ["restart"]="Restart Claude Code to see the new agents."
    ["unknown_target"]="Unknown target '%s'. Use 'contains' or 'wshobson'."
)

declare -A AGENT_TEXT_TR=(
    ["git_missing"]="'git' komutu bulunamadı. Lütfen önce git kurun."
    ["installing"]="%s ajan paketi kuruluyor..."
    ["cloning"]="Git deposu indiriliyor: %s"
    ["updating"]="%s klasöründeki mevcut ajanlar güncellenecek."
    ["copying"]="Ajan dosyaları kopyalanıyor..."
    ["installed"]="%s ajanları yüklendi (%s dosya)."
    ["location"]="Konum: %s"
    ["restart"]="Değişikliklerin görünmesi için Claude Code'u yeniden başlatın."
    ["unknown_target"]="Bilinmeyen hedef '%s'. 'contains' veya 'wshobson' kullanın."
)

agent_text() {
    local key="$1"
    local default_value="${AGENT_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${AGENT_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

agent_printf() {
    local __out="$1"
    local __key="$2"
    shift 2
    local __fmt
    __fmt="$(agent_text "$__key")"
    # shellcheck disable=SC2059
    printf -v "$__out" "$__fmt" "$@"
}

UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"

require_git() {
    if ! command -v git >/dev/null 2>&1; then
        echo -e "${RED}${ERROR_TAG}${NC} $(agent_text git_missing)"
        return 1
    fi
}

install_agents_repo() {
    local repo_url="$1"
    local label="$2"
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    local install_msg
    agent_printf install_msg installing "$label"
    echo -e "${YELLOW}${INFO_TAG}${NC} ${install_msg}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    require_git || return 1

    local temp_dir
    temp_dir="$(mktemp -d)"
    trap 'rm -rf "$temp_dir"' RETURN

    local clone_msg
    agent_printf clone_msg cloning "$repo_url"
    echo -e "${YELLOW}${INFO_TAG}${NC} ${clone_msg}"
    if ! git clone --depth=1 "$repo_url" "$temp_dir/agents" >/dev/null 2>&1; then
        echo -e "${RED}${ERROR_TAG}${NC} Agents deposu klonlanamadı."
        return 1
    fi

    mkdir -p "$CLAUDE_AGENTS_DIR"
    if [ -n "$(ls -A "$CLAUDE_AGENTS_DIR" 2>/dev/null)" ]; then
        local update_msg
        agent_printf update_msg updating "$CLAUDE_AGENTS_DIR"
        echo -e "${YELLOW}${INFO_TAG}${NC} ${update_msg}"
    fi

    echo -e "${YELLOW}${INFO_TAG}${NC} $(agent_text copying)"
    if command -v rsync >/dev/null 2>&1; then
        rsync -a --delete "$temp_dir/agents"/ "$CLAUDE_AGENTS_DIR"/
    else
        find "$CLAUDE_AGENTS_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
        cp -R "$temp_dir/agents"/. "$CLAUDE_AGENTS_DIR"/
    fi

    local agent_count
    agent_count=$(find "$CLAUDE_AGENTS_DIR" -type f -name "*.md" | wc -l | tr -d ' ')

    local installed_msg location_msg
    agent_printf installed_msg installed "$label" "$agent_count"
    agent_printf location_msg location "$CLAUDE_AGENTS_DIR"
    echo -e "\n${GREEN}${SUCCESS_TAG}${NC} ${installed_msg}"
    echo -e "${YELLOW}${INFO_TAG}${NC} ${location_msg}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(agent_text restart)"
    echo -e "${CYAN}Referans:${NC} ${repo_url}"
    trap - RETURN
}

install_claude_agents() {
    install_agents_repo "https://github.com/contains-studio/agents.git" "Contains Studio"
}

install_wshobson_agents() {
    install_agents_repo "https://github.com/wshobson/agents.git" "Wes Hobson"
}

main() {
    local target="${1:-contains}"
    case "$target" in
        contains|studio)
            install_claude_agents
            ;;
        wshobson|wes)
            install_wshobson_agents
            ;;
        *)
            local unknown_msg
            agent_printf unknown_msg unknown_target "$target"
            echo -e "${YELLOW}${INFO_TAG}${NC} ${unknown_msg}"
            return 1
            ;;
    esac
}

main "$@"
