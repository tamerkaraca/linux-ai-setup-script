#!/bin/bash
set -euo pipefail

# Resolve the directory this script lives in so sources work regardless of CWD
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$script_dir/utils.bash"
platform_local="$script_dir/platform_detection.bash"

# Load remote helper if available
if [ -f "./utils/remote_helper.bash" ]; then
    source "./utils/remote_helper.bash"
fi

# Prefer local direct source (relative to this file). If not available, fall back to
# the setup-provided `source_module` helper when running under the main `setup` script.
if [ -f "$utils_local" ]; then
    # shellcheck source=/dev/null
    source "$utils_local"
elif [ -f "./utils.bash" ]; then
    # shellcheck source=/dev/null
    source "./utils.bash"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/utils.bash" "modules/utils/utils.bash"
else
    log_error "Unable to load utils.bash (tried $utils_local)"
    exit 1
fi

if [ -f "$platform_local" ]; then
    # shellcheck source=/dev/null
    source "$platform_local"
elif [ -f "./platform_detection.bash" ]; then
    # shellcheck source=/dev/null
    source "./platform_detection.bash"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/platform_detection.bash" "modules/utils/platform_detection.bash"
fi

: "${REMOTE_MODULE_DIR:=}"

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

CURRENT_LANG="${LANGUAGE:-en}"

declare -A NODE_TEXT_EN=(
    ["nvm_title"]="Starting NVM installation..."
    ["node_lts_install"]="Installing latest Node.js LTS release..."
    ["node_version"]="Node.js version: %s"
    ["npm_version"]="npm version: %s"
    ["bun_title"]="Starting Bun runtime installation..."
    ["bun_script"]="Installing Bun via official script..."
    ["bun_success"]="Bun installed: %s"
    ["bun_failed"]="Bun installation failed."
    ["extras_title"]="Installing Node CLI extras..."
    ["extras_missing_node"]="Node.js not found. Please run the NVM/Node installation first."
    ["extras_corepack"]="Enabling corepack..."
    ["extras_pnpm"]="Installing pnpm and yarn globally..."
    ["extras_warning"]="Encountered an issue while installing pnpm/yarn."
    ["extras_success"]="Node CLI extras configured."
    ["unknown_arg"]="Unknown argument: %s"
    ["env_apply"]="Applying updated environment variables: source %s"
    ["stack_success"]="Node.js tooling installation completed!"
)

declare -A NODE_TEXT_TR=(
    ["nvm_title"]="NVM kurulumu başlatılıyor..."
    ["node_lts_install"]="Node.js LTS sürümü kuruluyor..."
    ["node_version"]="Node.js sürümü: %s"
    ["npm_version"]="npm sürümü: %s"
    ["bun_title"]="Bun runtime kurulumu başlatılıyor..."
    ["bun_script"]="Bun resmi scripti ile kuruluyor..."
    ["bun_success"]="Bun kuruldu: %s"
    ["bun_failed"]="Bun kurulumu başarısız oldu."
    ["extras_title"]="Node CLI ek paketleri yükleniyor..."
    ["extras_missing_node"]="Node.js bulunamadı. Lütfen önce NVM/Node kurulumunu çalıştırın."
    ["extras_corepack"]="Corepack etkinleştiriliyor..."
    ["extras_pnpm"]="pnpm ve yarn global olarak kuruluyor..."
    ["extras_warning"]="pnpm/yarn kurulurken bir hata oluştu."
    ["extras_success"]="Ek Node araçları yapılandırıldı."
    ["unknown_arg"]="Bilinmeyen argüman: %s"
    ["env_apply"]="Güncellenen ortam değişkenleri uygulanıyor: source %s"
    ["stack_success"]="Node.js ve ilgili araçların kurulumu tamamlandı!"
)

node_text_raw() {
    local key="$1"
    local default_value="${NODE_TEXT_EN[$key]:-$key}"
    if [ "$CURRENT_LANG" = "tr" ]; then
        printf "%s" "${NODE_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

node_text() {
    node_text_raw "$1"
}

node_text_fmt() {
    local key="$1"
    shift || true
    local template
    template="$(node_text_raw "$key")"
    # shellcheck disable=SC2059
    printf "$template" "$@"
}

install_nvm() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(node_text nvm_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

    if [ -z "${XDG_CONFIG_HOME-}" ]; then
        NVM_DIR="${HOME}/.nvm"
    else
        NVM_DIR="${XDG_CONFIG_HOME}/nvm"
    fi
    export NVM_DIR
    # shellcheck source=/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
        if [ -f "$rc_file" ] && ! grep -q 'NVM_DIR' "$rc_file"; then
            {
                echo ""
                echo "# NVM PATH (linux-ai-setup-script)"
                echo "export NVM_DIR=\"$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")\""
                echo "[ -s \"$NVM_DIR/nvm.sh\" ] && \\. \"$NVM_DIR/nvm.sh\""
            } >> "$rc_file"
        fi
    done

    # shellcheck source=/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    echo -e "${YELLOW}${INFO_TAG}${NC} $(node_text node_lts_install)"
    (
        set +u
        nvm install --lts
        nvm use --lts >/dev/null
    )

    echo -e "\n${GREEN}${SUCCESS_TAG}${NC} $(node_text_fmt node_version "$(node -v)")"
    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(node_text_fmt npm_version "$(npm -v)")"
}

install_bun() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(node_text bun_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    echo -e "${YELLOW}${INFO_TAG}${NC} $(node_text bun_script)"
    curl -fsSL https://bun.sh/install | bash

    export BUN_INSTALL="$HOME/.bun"
    ensure_path_contains_dir "$BUN_INSTALL/bin" "bun runtime"

    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
        if [ -f "$rc_file" ] && ! grep -q '.bun/bin' "$rc_file"; then
            {
                echo ""
                echo "# Bun PATH (linux-ai-setup-script)"
                echo "export BUN_INSTALL=\"$HOME/.bun\""
                echo "export PATH=\"$BUN_INSTALL/bin:\$PATH\""
            } >> "$rc_file"
        fi
    done

    reload_shell_configs silent

    if command -v bun >/dev/null 2>&1; then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(node_text_fmt bun_success "$(bun --version)")"
    else
        echo -e "${RED}${ERROR_TAG}${NC} $(node_text bun_failed)"
        return 1
    fi
}

install_node_extras() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(node_text extras_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if ! command -v node >/dev/null 2>&1; then
        echo -e "${RED}${ERROR_TAG}${NC} $(node_text extras_missing_node)"
        return 1
    fi

    echo -e "${YELLOW}${INFO_TAG}${NC} $(node_text extras_corepack)"
    corepack enable || true

    echo -e "${YELLOW}${INFO_TAG}${NC} $(node_text extras_pnpm)"
    if ! npm install -g pnpm yarn >/dev/null 2>&1; then
        echo -e "${YELLOW}${WARN_TAG}${NC} $(node_text extras_warning)"
    fi

    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(node_text extras_success)"
}

main() {
    local install_node="true"
    local install_bun_flag="true"
    local install_extras_flag="true"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --node-only)
                install_bun_flag="false"
                install_extras_flag="false"
                ;;
            --bun-only)
                install_node="false"
                install_extras_flag="false"
                ;;
            --extras-only)
                install_node="false"
                install_bun_flag="false"
                install_extras_flag="true"
                ;;
            --with-extras)
                install_extras_flag="true"
                ;;
            --skip-extras)
                install_extras_flag="false"
                ;;
            --skip-bun)
                install_bun_flag="false"
                ;;
            *)
                echo -e "${YELLOW}${WARN_TAG}${NC} $(node_text_fmt unknown_arg "$1")"
                ;;
        esac
        shift || true
    done

    if [ "$install_node" = "true" ]; then
        install_nvm
    fi

    if [ "$install_bun_flag" = "true" ]; then
        install_bun
    fi

    if [ "$install_extras_flag" = "true" ]; then
        install_node_extras || true
    fi

    reload_shell_configs

    local rc_files=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.profile")
    for rc_file in "${rc_files[@]}"; do
        if [ -f "$rc_file" ]; then
            echo -e "${YELLOW}${INFO_TAG}${NC} $(node_text_fmt env_apply "$rc_file")"
            source_shell_config "$rc_file" || true
        fi
    done

    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(node_text stack_success)"
}

main "$@"
