#!/bin/bash
set -euo pipefail

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
    echo "[HATA/ERROR] utils.bash yüklenemedi / Unable to load utils.bash (tried $utils_local)" >&2
    exit 1
fi

if [ -f "$platform_local" ]; then
    # shellcheck source=/dev/null
    source "$platform_local"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/platform_detection.bash" "modules/utils/platform_detection.bash"
fi

# AI CLI Tools for macOS using Homebrew
declare -A MACOS_AI_TOOLS=(
    ["claude-code"]="cask"
    ["codex"]="cask"
    ["gemini"]="cask"
    ["cursor-cli"]="cask"
    ["droid"]="cask"
    ["opencode"]="formula"
    ["qwen-code"]="formula"
    ["aider"]="formula"
    ["copilot"]="formula"
    ["node"]="formula"
    ["github"]="cask"
)

install_tool_homebrew() {

    local tool="
"

    local type="${MACOS_AI_TOOLS[$tool]}"

    

    log_info_detail "Installing $tool via Homebrew ($type)..."

    

    case "$type" in

        "cask")

            if brew install --cask "$tool"; then

                log_success_detail "$tool installed successfully"

                return 0

            else

                log_error_detail "Failed to install $tool"

                return 1

            fi

            ;;

        "formula")

            if brew install "$tool"; then

                log_success_detail "$tool installed successfully"

                return 0

            else

                log_error_detail "Failed to install $tool"

                return 1

            fi

            ;;

        *)

            log_error_detail "Unknown installation type for $tool: $type"

            return 1

            ;;

    esac

}



install_bun_manually() {

    log_info_detail "Installing Bun runtime manually..."

    if curl -fsSL https://bun.sh/install | bash; then

        log_success_detail "Bun installed successfully"

        

        # Add Bun to PATH

        # shellcheck disable=SC2016

        echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.zshrc

        # shellcheck disable=SC2016

        echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.bash_profile

        

        # Source for current session

        export PATH="$HOME/.bun/bin:$PATH"

        

        log_info_detail "Bun added to PATH"

        return 0

    else

        log_error_detail "Failed to install Bun"

        return 1

    fi

}



show_macos_ai_menu() {

    while true; do

        clear

        render_setup_banner "$SCRIPT_VERSION" "https://github.com/tamerkaraca/linux-ai-setup-script"

        

        log_info_detail "macOS AI CLI Tools Installation Menu"

        

        log_info_detail "  1 - Claude Code (Cask)"

        log_info_detail "  2 - Codex CLI (Cask)"

        log_info_detail "  3 - Gemini CLI (Cask)"

        log_info_detail "  4 - Cursor CLI (Cask)"

        log_info_detail "  5 - Droid CLI (Cask)"

        log_info_detail "  6 - OpenCode CLI (Formula)"

        log_info_detail "  7 - QwenCode CLI (Formula)"

        log_info_detail "  8 - Aider CLI (Formula)"

        log_info_detail "  9 - GitHub Copilot CLI (Formula)"

        log_info_detail "  10 - Node.js (Formula)"

        log_info_detail "  11 - GitHub CLI (Cask)"

        log_info_detail "  12 - Bun Runtime (Manual Install)"

        log_info_detail "  A - Install All Tools"

        log_info_detail "  0 - Return to Main Menu"

        log_info_detail "You can make multiple selections with commas (e.g., 1,3,7)."

        

        read -r -p "Your choice: " choice_input </dev/tty

        

        if [ -z "$(echo "$choice_input" | tr -d '[:space:]')" ]; then

            log_warn_detail "No selection made. Please try again."

            sleep 1

            continue

        fi

        

        IFS=',' read -ra USER_CHOICES <<< "$choice_input"

        

        for raw_choice in "${USER_CHOICES[@]}"; do

            choice=$(echo "$raw_choice" | tr -d '[:space:]')

            [ -z "$choice" ] && continue

            choice=$(echo "$choice" | tr '[:lower:]' '[:upper:]')

            

            case "$choice" in

                1) install_tool_homebrew "claude-code" ;;

                2) install_tool_homebrew "codex" ;;

                3) install_tool_homebrew "gemini" ;;

                4) install_tool_homebrew "cursor-cli" ;;

                5) install_tool_homebrew "droid" ;;

                6) install_tool_homebrew "opencode" ;;

                7) install_tool_homebrew "qwen-code" ;;

                8) install_tool_homebrew "aider" ;;

                9) install_tool_homebrew "copilot" ;;

                10) install_tool_homebrew "node" ;;

                11) install_tool_homebrew "github" ;;

                12) install_bun_manually ;;

                A)

                    install_tool_homebrew "claude-code"

                    install_tool_homebrew "codex"

                    install_tool_homebrew "gemini"

                    install_tool_homebrew "cursor-cli"

                    install_tool_homebrew "droid"

                    install_tool_homebrew "opencode"

                    install_tool_homebrew "qwen-code"

                    install_tool_homebrew "aider"

                    install_tool_homebrew "copilot"

                    install_tool_homebrew "node"

                    install_tool_homebrew "github"

                    install_bun_manually

                    ;;

                0)

                    return 0

                    ;;

                *)

                    log_error_detail "Invalid choice: $raw_choice"

                    ;;

            esac

        done

        

        read -r -p "Press Enter to continue..." </dev/tty

    done

}



# Main execution

if is_macos; then

    if ! command -v brew &> /dev/null; then

        log_error_detail "Homebrew is not installed. Please install Homebrew first."

        read -r -p "Would you like to install Homebrew now? (y/n)" install_brew_choice </dev/tty

        if [[ "$install_brew_choice" =~ ^[Yy]$ ]]; then

            if ! bash -c "$(curl -fsSL https://raw.githubusercontent.com/tamerkaraca/linux-ai-setup-script/main/modules/install_homebrew.sh)"; then

                log_error_detail "Homebrew installation failed. Cannot proceed with AI frameworks installation."

                exit 1

            fi

        else

            log_info_detail "Homebrew installation skipped. Cannot proceed with AI frameworks installation."

            exit 0

        fi

    fi

    

    show_macos_ai_menu

else

    log_error_detail "This module is designed for macOS only"

    exit 1

fi
