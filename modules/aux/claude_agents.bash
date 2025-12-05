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

# Resolve the directory this script lives in so sources work regardless of CWD
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$script_dir/../utils/utils.bash"
platform_local="$script_dir/../utils/platform_detection.bash"

# Prefer local direct source (relative to this file). If not available, fall back to
# the setup-provided `source_module` helper when running under the main `setup` script.
if [ -f "$utils_local" ]; then
    # shellcheck source=/dev/null
    source "$utils_local"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/utils.bash" "modules/utils/utils.bash"
else
    echo "[ERROR] Unable to load utils.bash (tried $utils_local)" >&2
    exit 1
fi

if [ -f "$platform_local" ]; then
    # shellcheck source=/dev/null
    source "$platform_local"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/platform_detection.bash" "modules/utils/platform_detection.bash"
fi

require_git() {
    if ! command -v git >/dev/null 2>&1; then
        log_error_detail "$(agent_text git_missing)"
        return 1
    fi
}

install_agents_repo() {
    local repo_url="$1"
    local label="$2"
    log_info_detail "$(agent_printf "msg" "installing" "$label" && echo "$msg")"

    require_git || return 1

    local temp_dir
    temp_dir="$(mktemp -d)"
    trap 'rm -rf "$temp_dir"' RETURN

    log_info_detail "$(agent_printf "msg" "cloning" "$repo_url" && echo "$msg")"
    if ! git clone --depth=1 "$repo_url" "$temp_dir/agents" >/dev/null 2>&1; then
        log_error_detail "Agents deposu klonlanamadı."
        return 1
    fi

    mkdir -p "$CLAUDE_AGENTS_DIR"
    if [ -n "$(ls -A "$CLAUDE_AGENTS_DIR" 2>/dev/null)" ]; then
        log_info_detail "$(agent_printf "msg" "updating" "$CLAUDE_AGENTS_DIR" && echo "$msg")"
    fi

    log_info_detail "$(agent_text copying)"
    if command -v rsync >/dev/null 2>&1; then
        rsync -a --delete "$temp_dir/agents"/ "$CLAUDE_AGENTS_DIR"/
    else
        find "$CLAUDE_AGENTS_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
        cp -R "$temp_dir/agents"/. "$CLAUDE_AGENTS_DIR"/
    fi

    local agent_count
    agent_count=$(find "$CLAUDE_AGENTS_DIR" -type f -name "*.md" | wc -l | tr -d ' ')

    log_success_detail "$(agent_printf "msg" "installed" "$label" "$agent_count" && echo "$msg")"
    log_info_detail "$(agent_printf "msg" "location" "$CLAUDE_AGENTS_DIR" && echo "$msg")"
    log_info_detail "$(agent_text restart)"
    log_info_detail "Referans: ${repo_url}"
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
            log_warn_detail "$(agent_printf "msg" "unknown_target" "$target" && echo "$msg")"
            return 1
            ;;
    esac
}

main "$@"
