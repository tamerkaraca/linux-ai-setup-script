#!/bin/bash
set -euo pipefail

: "${AIDER_MIN_NODE_VERSION:=18}"

UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

: "${AIDER_SUPPORTED_PYTHONS:=python3.11 python3.10 python3.9}"

declare -A AIDER_TEXT_EN=(
    ["install_title"]="Starting Aider CLI installation..."
    ["dry_run_requirement"]="Will verify Node.js >= %s and run 'pipx install aider-chat'."
    ["dry_run_skip"]="Dry-run mode skips the actual installation and login steps."
    ["pipx_missing"]="Pipx installation failed; cannot install Aider CLI."
    ["pipx_install"]="Installing 'aider-chat' via pipx..."
    ["install_fail"]="Aider CLI installation failed."
    ["command_missing"]="'aider' command not found. Check your PATH."
    ["version_info"]="Aider CLI version: %s"
    ["interactive_intro"]="Aider requires provider API keys (e.g., OPENAI_API_KEY). Configure them and press Enter."
    ["batch_skip"]="Authentication skipped in batch mode."
    ["batch_note"]="Before running '%s', export the necessary API keys."
    ["install_done"]="Aider CLI installation completed!"
    ["python_install"]="Installing %s for Aider (supports numpy builds)."
    ["python_install_fail"]="Unable to install %s automatically. Please ensure an older Python (≤3.11) exists."
    ["python_select"]="Using %s for pipx."
)

declare -A AIDER_TEXT_TR=(
    ["install_title"]="Aider CLI kurulumu başlatılıyor..."
    ["dry_run_requirement"]="Node.js >= %s doğrulanacak ve 'pipx install aider-chat' komutu çalıştırılacak."
    ["dry_run_skip"]="Dry-run modunda gerçek kurulum ve oturum açma adımları atlanır."
    ["pipx_missing"]="Pipx kurulamadı; Aider CLI yüklenemiyor."
    ["pipx_install"]="'aider-chat' paketi pipx ile kuruluyor..."
    ["install_fail"]="Aider CLI kurulumu başarısız oldu."
    ["command_missing"]="'aider' komutu bulunamadı. PATH ayarlarınızı kontrol edin."
    ["version_info"]="Aider CLI sürümü: %s"
    ["interactive_intro"]="Aider, sağlayıcınıza göre API anahtarları ister (ör. OPENAI_API_KEY). Ayarladıktan sonra Enter'a basın."
    ["batch_skip"]="Toplu kurulumda kimlik doğrulama ve anahtarlar atlandı."
    ["batch_note"]="'%s' komutunu çalıştırmadan önce gerekli API anahtarlarını export etmeyi unutmayın."
    ["install_done"]="Aider CLI kurulumu tamamlandı!"
    ["python_install"]="%s sürümü Aider için kuruluyor (numpy derlemelerini destekler)."
    ["python_install_fail"]="%s otomatik kurulamadı. Lütfen 3.11 veya daha düşük bir Python sürümü yükleyin."
    ["python_select"]="%s pipx için kullanılacak."
)

aider_text() {
    local key="$1"
    local default_value="${AIDER_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${AIDER_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

aider_printf() {
    local __out="$1"
    local __key="$2"
    shift 2
    local __fmt
    __fmt="$(aider_text "$__key")"
    # shellcheck disable=SC2059
    printf -v "$__out" "$__fmt" "$@"
}

ensure_pipx_available() {
    if command -v pipx >/dev/null 2>&1; then
        return 0
    fi
    echo -e "${YELLOW}${WARN_TAG}${NC} Aider için Pipx gerekli; kuruluma başlanıyor..."
    if ! command -v python3 >/dev/null 2>&1; then
        echo -e "${YELLOW}${WARN_TAG}${NC} Python bulunamadı, Python kurulumu tetikleniyor..."
        install_python
    fi
    install_pipx
}

ensure_aider_build_prereqs() {
    if [ -z "${PKG_MANAGER:-}" ]; then
        detect_package_manager
    fi

    local packages=()
    case "${PKG_MANAGER}" in
        apt)
            packages=(build-essential python3-dev python3-venv)
            ;;
        dnf|dnf5)
            packages=(gcc gcc-c++ make python3-devel)
            ;;
        yum)
            packages=(gcc gcc-c++ make python3-devel)
            ;;
        pacman)
            packages=(base-devel python)
            ;;
        *)
            return 0
            ;;
    esac

    local missing=()
    for pkg in "${packages[@]}"; do
        case "${PKG_MANAGER}" in
            apt)
                dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
                ;;
            dnf|dnf5|yum)
                rpm -q "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
                ;;
            pacman)
                pacman -Qi "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
                ;;
        esac
    done

    if [ ${#missing[@]} -eq 0 ]; then
        return 0
    fi

    local install_cmd="${INSTALL_CMD:-}"
    if [ -z "$install_cmd" ]; then
        case "${PKG_MANAGER}" in
            apt)
                install_cmd="sudo apt install -y"
                ;;
            dnf|dnf5)
                install_cmd="sudo ${PKG_MANAGER} install -y"
                ;;
            yum)
                install_cmd="sudo yum install -y"
                ;;
            pacman)
                install_cmd="sudo pacman -S --noconfirm"
                ;;
        esac
    fi

    if [ "${LANGUAGE:-en}" = "tr" ]; then
        echo -e "${YELLOW}${INFO_TAG}${NC} Aider için gerekli derleme paketleri yükleniyor: ${missing[*]}"
    else
        echo -e "${YELLOW}${INFO_TAG}${NC} Installing required build packages for Aider: ${missing[*]}"
    fi
    if [ -n "$install_cmd" ]; then
        $install_cmd "${missing[@]}" >/dev/null 2>&1 || $install_cmd "${missing[@]}"
    fi
}

install_python_candidate() {
    local py_cmd="$1"
    if command -v "$py_cmd" >/dev/null 2>&1; then
        return 0
    fi
    if [ -z "${PKG_MANAGER:-}" ]; then
        detect_package_manager
    fi
    local pkg_name=""
    case "$py_cmd" in
        python3.11) pkg_name="python3.11 python3.11-venv" ;;
        python3.10) pkg_name="python3.10 python3.10-venv" ;;
        python3.9) pkg_name="python3.9 python3.9-venv" ;;
    esac
    [ -z "$pkg_name" ] && return 1
    read -r -a pkg_array <<< "$pkg_name"
    local install_cmd=""
    case "$PKG_MANAGER" in
        apt) install_cmd="sudo apt install -y" ;;
        dnf|dnf5) install_cmd="sudo ${PKG_MANAGER} install -y" ;;
        yum) install_cmd="sudo yum install -y" ;;
        pacman) install_cmd="sudo pacman -S --noconfirm" ;;
    esac
    [ -z "$install_cmd" ] && return 1
    local install_msg
    aider_printf install_msg python_install "$py_cmd"
    echo -e "${YELLOW}${INFO_TAG}${NC} ${install_msg}"
    if $install_cmd "${pkg_array[@]}" >/dev/null 2>&1; then
        return 0
    fi
    local fail_msg
    aider_printf fail_msg python_install_fail "$py_cmd"
    echo -e "${YELLOW}${WARN_TAG}${NC} ${fail_msg}"
    return 1
}

select_aider_python() {
    local default_py
    default_py="$(command -v python3 || true)"
    if [ -n "$default_py" ]; then
        local py_ver
        py_ver="$("$default_py" -c 'import sys;print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>/dev/null || true)"
        if [[ "$py_ver" =~ ^3\.([0-9]+)$ ]]; then
            local minor="${BASH_REMATCH[1]}"
            if [ "$minor" -le 11 ]; then
                AIDER_PYTHON_BIN="$default_py"
                return 0
            fi
        fi
    fi
    for candidate in $AIDER_SUPPORTED_PYTHONS; do
        if command -v "$candidate" >/dev/null 2>&1; then
            AIDER_PYTHON_BIN="$candidate"
            return 0
        fi
    done
    for candidate in $AIDER_SUPPORTED_PYTHONS; do
        if install_python_candidate "$candidate"; then
            AIDER_PYTHON_BIN="$candidate"
            return 0
        fi
    done
    AIDER_PYTHON_BIN="${default_py:-python3}"
    return 0
}

install_aider_cli() {
    local interactive_mode="true"
    local dry_run="false"

    if [[ $# -gt 0 && "$1" != --* ]]; then
        interactive_mode="$1"
        shift
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                dry_run="true"
                ;;
            *)
                echo -e "${YELLOW}${WARN_TAG}${NC} Bilinmeyen argüman: $1"
                ;;
        esac
        shift || true
    done

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(aider_text install_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if [ "$dry_run" = true ]; then
        local aider_req
        aider_printf aider_req dry_run_requirement "$AIDER_MIN_NODE_VERSION"
        echo -e "${YELLOW}[DRY-RUN]${NC} ${aider_req}"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(aider_text dry_run_skip)"
        return 0
    fi

    require_node_version "$AIDER_MIN_NODE_VERSION" "Aider CLI" || return 1
    ensure_pipx_available || {
        echo -e "${RED}${ERROR_TAG}${NC} $(aider_text pipx_missing)"
        return 1
    }

    ensure_aider_build_prereqs || true
    select_aider_python
    if [ -n "${AIDER_PYTHON_BIN:-}" ]; then
        local python_msg
        aider_printf python_msg python_select "$AIDER_PYTHON_BIN"
        echo -e "${YELLOW}${INFO_TAG}${NC} ${python_msg}"
    fi

    echo -e "${YELLOW}${INFO_TAG}${NC} $(aider_text pipx_install)"
    if ! pipx install ${AIDER_PYTHON_BIN:+--python "$AIDER_PYTHON_BIN"} aider-chat >/dev/null 2>&1 && \
       ! pipx install ${AIDER_PYTHON_BIN:+--python "$AIDER_PYTHON_BIN"} aider-chat; then
        echo -e "${RED}${ERROR_TAG}${NC} $(aider_text install_fail)"
        return 1
    fi

    reload_shell_configs silent
    hash -r 2>/dev/null || true

    if ! command -v aider >/dev/null 2>&1; then
        echo -e "${RED}${ERROR_TAG}${NC} $(aider_text command_missing)"
        return 1
    fi

    local aider_version
    aider_printf aider_version version_info "$(aider --version 2>/dev/null)"
    echo -e "${GREEN}${SUCCESS_TAG}${NC} ${aider_version}"

    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(aider_text interactive_intro)"
        read -r -p "" </dev/tty || true
    else
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(aider_text batch_skip)"
        local batch_msg
        aider_printf batch_msg batch_note "${GREEN}aider --help${NC}"
        echo -e "${YELLOW}${INFO_TAG}${NC} ${batch_msg}"
    fi

    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(aider_text install_done)"
}

main() {
    install_aider_cli "$@"
}

main "$@"
