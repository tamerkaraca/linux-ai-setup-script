#!/bin/bash
set -euo pipefail

: "${CLAUDE_AGENTS_DIR:=$HOME/.claude/agents}"
: "${CLAUDE_AGENTS_REPO:=https://github.com/contains-studio/agents.git}"

UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"

require_git() {
    if ! command -v git >/dev/null 2>&1; then
        echo -e "${RED}[HATA]${NC} 'git' komutu bulunamadı. Lütfen önce git kurun."
        return 1
    fi
}

install_agents_repo() {
    local repo_url="$1"
    local label="$2"
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} ${label} ajan paketi kuruluyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    require_git || return 1

    local temp_dir
    temp_dir="$(mktemp -d)"
    trap 'rm -rf "$temp_dir"' RETURN

    echo -e "${YELLOW}[BİLGİ]${NC} Git deposu indiriliyor: ${repo_url}"
    if ! git clone --depth=1 "$repo_url" "$temp_dir/agents" >/dev/null 2>&1; then
        echo -e "${RED}[HATA]${NC} Agents deposu klonlanamadı."
        return 1
    fi

    mkdir -p "$CLAUDE_AGENTS_DIR"
    if [ -n "$(ls -A "$CLAUDE_AGENTS_DIR" 2>/dev/null)" ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} ${CLAUDE_AGENTS_DIR} klasöründeki mevcut ajanlar güncellenecek."
    fi

    echo -e "${YELLOW}[BİLGİ]${NC} Ajan dosyaları kopyalanıyor..."
    if command -v rsync >/dev/null 2>&1; then
        rsync -a --delete "$temp_dir/agents"/ "$CLAUDE_AGENTS_DIR"/
    else
        find "$CLAUDE_AGENTS_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
        cp -R "$temp_dir/agents"/. "$CLAUDE_AGENTS_DIR"/
    fi

    local agent_count
    agent_count=$(find "$CLAUDE_AGENTS_DIR" -type f -name "*.md" | wc -l | tr -d ' ')

    echo -e "\n${GREEN}[BAŞARILI]${NC} ${label} ajanları yüklendi (${agent_count} dosya)."
    echo -e "${YELLOW}[BİLGİ]${NC} Konum: ${CLAUDE_AGENTS_DIR}"
    echo -e "${YELLOW}[BİLGİ]${NC} Değişikliklerin görünmesi için Claude Code'u yeniden başlatın."
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
            echo -e "${YELLOW}[BİLGİ]${NC} Bilinmeyen hedef '${target}'. 'contains' veya 'wshobson' kullanın."
            return 1
            ;;
    esac
}

main "$@"
