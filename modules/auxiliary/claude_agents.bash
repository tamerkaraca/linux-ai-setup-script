#!/bin/bash
set -euo pipefail

# This script installs various agent/template packs for Claude Code.

# --- Load Utilities ---
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$script_dir/../utils/utils.bash"
if [ -f "$utils_local" ]; then source "$utils_local"; fi
# --- End Load Utilities ---

# --- Text Definitions ---
declare -A AGENT_TEXT_EN=(
    ["git_missing"]="'git' command not found. Please install git first."
    ["installing"]="Installing '%s' agent/template pack..."
    ["cloning"]="Cloning repository: %s"
    ["copying"]="Copying files to: %s"
    ["success"]="Successfully installed the '%s' pack."
    ["repo_failed"]="Failed to clone repository: %s"
    ["file_missing"]="Source folder '%s' not found in the repository."
    ["unknown_target"]="Unknown target '%s'. Valid options are: 'contains', 'wshobson', 'agentskills', 'davila7'."
)
declare -A AGENT_TEXT_TR=(
    ["git_missing"]="'git' komutu bulunamadı. Lütfen önce git kurun."
    ["installing"]="'%s' ajan/şablon paketi kuruluyor..."
    ["cloning"]="Depo klonlanıyor: %s"
    ["copying"]="Dosyalar şu konuma kopyalanıyor: %s"
    ["success"]="'%s' paketi başarıyla kuruldu."
    ["repo_failed"]="Depo klonlanamadı: %s"
    ["file_missing"]="Kaynak klasörü '%s' depoda bulunamadı."
    ["unknown_target"]="Bilinmeyen hedef '%s'. Geçerli seçenekler: 'contains', 'wshobson', 'agentskills', 'davila7'."
)

agent_text() {
    local key="$1"; local arg1="${2:-}"; local lang="${LANGUAGE:-en}";
    local text_map_name="AGENT_TEXT_${lang^^}";
    eval "local text=\${${text_map_name}['$key']}";
    if [ -z "$text" ]; then text="${AGENT_TEXT_EN[$key]}"; fi
    printf "$text" "$arg1";
}
# --- End Text Definitions ---

# --- Core Installation Logic ---
install_pack() {
    local label="$1"
    local repo_url="$2"
    local source_subpath="$3" # The sub-directory inside the repo that contains the .md files
    local target_dir="$4"     # The local directory to copy files to (e.g., ~/.claude/agents)

    if ! command -v git >/dev/null 2>&1; then
        log_error_detail "$(agent_text 'git_missing')"; return 1;
    fi

    log_info_detail "$(agent_text 'installing' "$label")"
    
    local temp_dir; temp_dir="$(mktemp -d)"; trap 'rm -rf "$temp_dir"' RETURN

    log_info_detail "$(agent_text 'cloning' "$repo_url")"
    if ! git clone --depth 1 "$repo_url" "$temp_dir" >/dev/null 2>&1; then
        log_error_detail "$(agent_text 'repo_failed' "$repo_url")"; return 1;
    fi

    local source_dir="$temp_dir/$source_subpath"
    if [ ! -d "$source_dir" ]; then
        log_error_detail "$(agent_text 'file_missing' "$source_subpath")"; return 1;
    fi

    mkdir -p "$target_dir"
    log_info_detail "$(agent_text 'copying' "$target_dir")"
    # Copy all contents from the source directory to the target directory
    cp -r "$source_dir"/* "$target_dir/"
    
    log_success_detail "$(agent_text 'success' "$label")"
}

# --- Main Execution ---
main() {
    local target="${1:-contains}"
    case "$target" in
        contains|studio)
            install_pack "Contains Studio" "https://github.com/contains-studio/agents.git" "agents" "$HOME/.claude/agents"
            ;;
        wshobson|wes)
            install_pack "Wes Hobson" "https://github.com/wshobson/agents.git" "agents" "$HOME/.claude/agents"
            ;;
        agentskills)
            install_pack "AgentSkills" "https://github.com/agentskills/agentskills.git" "agents" "$HOME/.claude/agents"
            ;;
        davila7)
            # This repo has a much more complex structure, we'll copy the most relevant parts.
            install_pack "davila7 (Agents)" "https://github.com/davila7/claude-code-templates.git" "cli-tool/components/agents" "$HOME/.claude/agents"
            install_pack "davila7 (Commands)" "https://github.com/davila7/claude-code-templates.git" "cli-tool/components/commands" "$HOME/.claude/commands"
            install_pack "davila7 (Skills)" "https://github.com/davila7/claude-code-templates.git" "cli-tool/components/skills" "$HOME/.claude/skills"
            ;;
        *)
            log_error_detail "$(agent_text 'unknown_target' "$target")"
            return 1
            ;;
    esac
}

main "$@"
