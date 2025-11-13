#!/bin/bash

# Renkli çıktı için tanımlamalar
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
NC=$'\033[0m' # No Color
export RED GREEN YELLOW BLUE CYAN NC

# Dil ve yerelleştirme ayarları
SUPPORTED_LANGUAGES=(en tr)

nounset_is_enabled() {
    if set -o | grep -Eq '^nounset[[:space:]]+on$'; then
        return 0
    fi
    return 1
}

source_shell_config() {
    local file="$1"
    [ -f "$file" ] || return 1
    local nounset_restore=0
    if nounset_is_enabled; then
        nounset_restore=1
        set +u
    fi
    # shellcheck source=/dev/null
    . "$file"
    if [ $nounset_restore -eq 1 ]; then
        set -u
    fi
    return 0
}

detect_system_language() {
    local locale_value="${LC_ALL:-${LANG:-}}"
    if [[ "$locale_value" =~ ^tr ]]; then
        echo "tr"
    else
        echo "en"
    fi
}

refresh_language_tags() {
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        INFO_TAG="[BİLGİ]"
        WARN_TAG="[UYARI]"
        ERROR_TAG="[HATA]"
        SUCCESS_TAG="[BAŞARILI]"
        NOTE_TAG="[NOT]"
    else
        INFO_TAG="[INFO]"
        WARN_TAG="[WARNING]"
        ERROR_TAG="[ERROR]"
        SUCCESS_TAG="[SUCCESS]"
        NOTE_TAG="[NOTE]"
    fi
    export INFO_TAG WARN_TAG ERROR_TAG SUCCESS_TAG NOTE_TAG
}

set_language() {
    local target_lang="$1"
    for lang in "${SUPPORTED_LANGUAGES[@]}"; do
        if [ "$lang" = "$target_lang" ]; then
            LANGUAGE="$lang"
            export LANGUAGE
            refresh_language_tags
            return 0
        fi
    done
    return 1
}

if [ -z "${LANGUAGE:-}" ]; then
    LANGUAGE="$(detect_system_language)"
fi
export LANGUAGE
refresh_language_tags

get_language_label() {
    case "$1" in
        tr) echo "Türkçe" ;;
        *) echo "English" ;;
    esac
}

init_translation_tables() {
    declare -gA TEXT_EN=(
    ["menu_title"]="MAIN INSTALL MENU"
    ["menu_subtitle"]="Select an action"
    ["menu_option1"]="Update system packages and core tools"
    ["menu_option2"]="Install Python, Pip/Pipx, UV"
    ["menu_option3"]="Open Node.js tool sub-menu"
    ["menu_option4"]="Install AI CLI tools"
    ["menu_option5"]="Install AI frameworks"
    ["menu_option6"]="Configure Git"
    ["menu_option7"]="Configure Claude Code providers"
    ["menu_option8"]="Install PHP & Composer"
    ["menu_option9"]="Install GitHub CLI"
    ["menu_option10"]="Remove AI frameworks"
    ["menu_option11"]="Manage MCP servers"
    ["menu_optionA"]="Run everything sequentially"
    ["menu_option0"]="Exit"
    ["menu_language_option"]="Switch language"
    ["menu_current_language"]="Current language"
    ["menu_multi_hint"]="Use commas for multiple selections (e.g., 1,4,5)."
    ["prompt_choice"]="Your choice"
    ["prompt_press_enter"]="Press Enter to continue..."
    ["warning_no_selection"]="No selection detected, please try again."
    ["warning_invalid_choice"]="Invalid selection"
    ["info_returning"]="Returning to the previous menu."
    ["info_language_switched"]="Language updated."
    ["node_menu_title"]="Node.js Tooling Menu"
    ["node_menu_subtitle"]="Pick one or more components to install/update"
    ["node_option1"]="Install or update Node.js (NVM + latest LTS)"
    ["node_option2"]="Install or update Bun runtime"
    ["node_option3"]="Install Node CLI extras (Corepack, pnpm, yarn)"
    ["node_option4"]="Install every component"
    ["node_option0"]="Return to main menu"
    ["ai_menu_title"]="AI CLI Installation Menu"
    ["ai_menu_hint"]="Use commas for multiple selections (e.g., 1,3,7)."
    ["ai_option1"]="Claude Code CLI"
    ["ai_option2"]="Gemini CLI"
    ["ai_option3"]="OpenCode CLI"
    ["ai_option4"]="Qoder CLI"
    ["ai_option5"]="Qwen CLI"
    ["ai_option6"]="OpenAI Codex CLI"
    ["ai_option7"]="Cursor Agent CLI"
    ["ai_option8"]="Cline CLI"
    ["ai_option9"]="Aider CLI"
    ["ai_option10"]="GitHub Copilot CLI"
    ["ai_option11"]="Kilocode CLI"
    ["ai_option12"]="Auggie CLI"
    ["ai_option13"]="Droid CLI"
    ["ai_option14"]="OpenSpec CLI"
    ["ai_option15"]="Contains Studio Agents"
    ["ai_option16"]="Wes Hobson Agents"
    ["ai_option17"]="Install every CLI"
    ["ai_option_return"]="Return to main menu"
    ["ai_prompt_install_more"]="Install another AI CLI? (y/n) [n]:"
    ["ai_summary_title"]="Login tips for installed CLIs:"
    ["ai_summary_default_hint"]="Follow the CLI documentation for authentication."
    ["fw_menu_title"]="AI Framework Installation Menu"
    ["fw_menu_hint"]="Use commas for multiple selections (e.g., 1,2)."
    ["fw_option1"]="SuperGemini Framework"
    ["fw_option2"]="SuperQwen Framework"
    ["fw_option3"]="SuperClaude Framework"
    ["fw_option4"]="Install every framework"
    ["fw_option_return"]="Return to main menu"
    ["fw_prompt_install_more"]="Install another AI framework? (y/n) [n]:"
    ["log_module_local"]="Running %s module from local files..."
    ["log_module_remote"]="Downloading %s module and running it..."
    ["log_module_error"]="An error occurred while running %s."
    ["log_remote_prepare_failed"]="The remote module workspace could not be prepared."
    ["log_module_download_failed"]="The %s module could not be downloaded."
    ["log_shell_reload_success"]="Shell configurations auto-loaded (%s)."
    ["log_shell_reload_missing"]="Shell configuration files were not found; restart your terminal if needed."
    ["log_detect_pkg_manager"]="Detecting operating system and package manager..."
    ["log_pkg_manager_missing"]="No supported package manager was found!"
    ["log_pkg_manager_detected"]="Package manager: %s"
    ["log_system_update_start"]="Updating the system..."
    ["log_system_install_basics"]="Installing core tools, compression utilities, and build helpers..."
    ["log_install_packages"]="Installing: %s"
    ["log_install_devtools"]="Installing development tools: %s"
    ["log_system_update_done"]="System update and base package installation completed!"
    ["log_python_install_title"]="Starting Python installation..."
    ["log_python_already"]="Python already installed: %s"
    ["log_python_installing"]="Installing Python 3..."
    ["log_python_success"]="Python installation completed: %s"
    ["log_python_failed"]="Python installation failed!"
    ["log_pip_title"]="Starting Pip installation/update..."
    ["log_python_missing_for_pip"]="Python is missing, installing it first..."
    ["log_pip_upgrading"]="Upgrading pip..."
    ["log_pip_missing"]="Pip not found. Trying get-pip.py..."
    ["log_pip_getpip_failed"]="Pip installation via get-pip.py failed!"
    ["log_pip_getpip_success"]="Pip installed via get-pip.py."
    ["log_pip_external_retry"]="Externally-managed-environment detected, retrying with --break-system-packages..."
    ["log_pip_upgrade_failed"]="Pip upgrade failed!"
    ["log_pip_version"]="Pip version: %s"
    ["log_pip_tips_header"]="Pip usage tips:"
    ["log_pip_tip_install"]="  • Install package: pip install <name>"
    ["log_pip_tip_venv"]="  • Use virtual environments (recommended): python3 -m venv myenv && source myenv/bin/activate"
    ["log_pip_tip_system"]="  • System-wide install: pip install --break-system-packages <name>"
    ["log_pip_tip_note"]="  • Note: modern systems recommend using virtual environments (PEP 668)."
    ["log_pipx_title"]="Starting Pipx installation..."
    ["log_python_missing_for_pipx"]="Python is missing, installing it first..."
    ["log_pipx_pkg_install"]="Installing pipx via package manager..."
    ["log_pipx_pkg_missing"]="Package not found, falling back to manual installation..."
    ["log_pipx_external_retry"]="Externally-managed-environment detected, trying alternate method..."
    ["log_break_system_packages_retry"]="Retrying install with --break-system-packages..."
    ["log_pipx_success"]="Pipx installation completed: %s"
    ["log_pipx_manual_hint"]="Manual installation: sudo apt install pipx"
    ["log_pipx_failed"]="Pipx installation failed!"
    )

    declare -gA TEXT_TR=(
    ["menu_title"]="ANA KURULUM MENÜSÜ"
    ["menu_subtitle"]="Bir işlem seçin"
    ["menu_option1"]="Sistemi güncelle ve temel paketleri kur"
    ["menu_option2"]="Python, Pip/Pipx ve UV kur"
    ["menu_option3"]="Node.js araç alt menüsünü aç"
    ["menu_option4"]="AI CLI araçlarını kur"
    ["menu_option5"]="AI frameworklerini kur"
    ["menu_option6"]="Git yapılandırması"
    ["menu_option7"]="Claude Code sağlayıcı ayarları"
    ["menu_option8"]="PHP & Composer kurulumu"
    ["menu_option9"]="GitHub CLI kurulumu"
    ["menu_option10"]="AI frameworklerini kaldır"
    ["menu_option11"]="MCP sunucu yönetimi"
    ["menu_optionA"]="Hepsini sırayla çalıştır"
    ["menu_option0"]="Çıkış"
    ["menu_language_option"]="Dili değiştir"
    ["menu_current_language"]="Geçerli dil"
    ["menu_multi_hint"]="Birden fazla seçim için virgül kullanın (örn: 1,4,5)."
    ["prompt_choice"]="Seçiminiz"
    ["prompt_press_enter"]="Devam etmek için Enter'a basın..."
    ["warning_no_selection"]="Bir seçim yapılmadı, lütfen tekrar deneyin."
    ["warning_invalid_choice"]="Geçersiz seçim"
    ["info_returning"]="Önceki menüye dönülüyor."
    ["info_language_switched"]="Dil güncellendi."
    ["node_menu_title"]="Node.js Araç Menüsü"
    ["node_menu_subtitle"]="Kurmak/güncellemek istediğiniz bileşenleri seçin"
    ["node_option1"]="Node.js (NVM + son LTS) kur/güncelle"
    ["node_option2"]="Bun runtime kur/güncelle"
    ["node_option3"]="Node CLI ekstralarını kur (Corepack, pnpm, yarn)"
    ["node_option4"]="Tüm bileşenleri kur"
    ["node_option0"]="Ana menüye dön"
    ["ai_menu_title"]="AI CLI Kurulum Menüsü"
    ["ai_menu_hint"]="Virgülle ayrılmış seçimleri kullanabilirsiniz (örn: 1,3,7)."
    ["ai_option1"]="Claude Code CLI"
    ["ai_option2"]="Gemini CLI"
    ["ai_option3"]="OpenCode CLI"
    ["ai_option4"]="Qoder CLI"
    ["ai_option5"]="Qwen CLI"
    ["ai_option6"]="OpenAI Codex CLI"
    ["ai_option7"]="Cursor Agent CLI"
    ["ai_option8"]="Cline CLI"
    ["ai_option9"]="Aider CLI"
    ["ai_option10"]="GitHub Copilot CLI"
    ["ai_option11"]="Kilocode CLI"
    ["ai_option12"]="Auggie CLI"
    ["ai_option13"]="Droid CLI"
    ["ai_option14"]="OpenSpec CLI"
    ["ai_option15"]="Contains Studio ajanları"
    ["ai_option16"]="Wes Hobson ajanları"
    ["ai_option17"]="Tüm CLI araçlarını kur"
    ["ai_option_return"]="Ana menüye dön"
    ["ai_prompt_install_more"]="Başka bir AI CLI aracı kurmak ister misiniz? (e/h) [h]:"
    ["ai_summary_title"]="Kurulan CLI araçları için giriş komutları:"
    ["ai_summary_default_hint"]="Kimlik doğrulama adımları için ilgili CLI dokümanını izleyin."
    ["fw_menu_title"]="AI Framework Kurulum Menüsü"
    ["fw_menu_hint"]="Birden fazla seçim için virgül kullanın (örn: 1,2)."
    ["fw_option1"]="SuperGemini Framework"
    ["fw_option2"]="SuperQwen Framework"
    ["fw_option3"]="SuperClaude Framework"
    ["fw_option4"]="Tüm AI frameworklerini kur"
    ["fw_option_return"]="Ana menüye dön"
    ["fw_prompt_install_more"]="Başka bir AI framework kurmak ister misiniz? (e/h) [h]:"
    ["log_module_local"]="%s modülü yerel dosyadan çalıştırılıyor..."
    ["log_module_remote"]="%s modülü indiriliyor ve çalıştırılıyor..."
    ["log_module_error"]="%s modülü çalıştırılırken bir hata oluştu."
    ["log_remote_prepare_failed"]="Uzaktan modül çalışma alanı hazırlanamadı."
    ["log_module_download_failed"]="%s modülü indirilemedi."
    ["log_shell_reload_success"]="Shell yapılandırmaları otomatik olarak yüklendi (%s)."
    ["log_shell_reload_missing"]="Shell yapılandırma dosyaları bulunamadı; gerekirse terminalinizi yeniden başlatın."
    ["log_detect_pkg_manager"]="İşletim sistemi ve paket yöneticisi tespit ediliyor..."
    ["log_pkg_manager_missing"]="Desteklenen bir paket yöneticisi bulunamadı!"
    ["log_pkg_manager_detected"]="Paket yöneticisi: %s"
    ["log_system_update_start"]="Sistem güncelleniyor..."
    ["log_system_install_basics"]="Temel paketler, sıkıştırma ve geliştirme araçları kuruluyor..."
    ["log_install_packages"]="Kuruluyor: %s"
    ["log_install_devtools"]="Geliştirme araçları kuruluyor: %s"
    ["log_system_update_done"]="Sistem güncelleme ve temel paket kurulumu tamamlandı!"
    ["log_python_install_title"]="Python kurulumu başlatılıyor..."
    ["log_python_already"]="Python zaten kurulu: %s"
    ["log_python_installing"]="Python3 kuruluyor..."
    ["log_python_success"]="Python kurulumu tamamlandı: %s"
    ["log_python_failed"]="Python kurulumu başarısız!"
    ["log_pip_title"]="Pip kurulumu/güncellemesi başlatılıyor..."
    ["log_python_missing_for_pip"]="Python kurulu değil, önce Python kuruluyor..."
    ["log_pip_upgrading"]="Pip güncelleniyor..."
    ["log_pip_missing"]="Pip bulunamadı. get-pip.py ile kurulum deneniyor..."
    ["log_pip_getpip_failed"]="get-pip.py ile Pip kurulumu başarısız!"
    ["log_pip_getpip_success"]="Pip, get-pip.py ile kuruldu."
    ["log_pip_external_retry"]="Externally-managed-environment hatası, --break-system-packages ile deneniyor..."
    ["log_pip_upgrade_failed"]="Pip güncellemesi başarısız!"
    ["log_pip_version"]="Pip sürümü: %s"
    ["log_pip_tips_header"]="Pip kullanım ipuçları:"
    ["log_pip_tip_install"]="  • Paket kurma: pip install paket_adi"
    ["log_pip_tip_venv"]="  • Sanal ortam (önerilir): python3 -m venv myenv && source myenv/bin/activate"
    ["log_pip_tip_system"]="  • Sistem geneli kurulum: pip install --break-system-packages paket_adi"
    ["log_pip_tip_note"]="  • Not: Modern sistemlerde sanal ortam (PEP 668) önerilir."
    ["log_pipx_title"]="Pipx kurulumu başlatılıyor..."
    ["log_python_missing_for_pipx"]="Python kurulu değil, önce Python kuruluyor..."
    ["log_pipx_pkg_install"]="Sistem paket yöneticisi ile pipx kuruluyor..."
    ["log_pipx_pkg_missing"]="Sistem paketi bulunamadı, manuel kurulum yapılıyor..."
    ["log_pipx_external_retry"]="Externally-managed-environment hatası, alternatif yöntem deneniyor..."
    ["log_break_system_packages_retry"]="--break-system-packages ile kurulum deneniyor..."
    ["log_pipx_success"]="Pipx kurulumu tamamlandı: %s"
    ["log_pipx_manual_hint"]="Manuel kurulum için: sudo apt install pipx"
    ["log_pipx_failed"]="Pipx kurulumu başarısız!"
    )
}

init_translation_tables

_translate_value() {
    local key="$1"
    local default_value="${TEXT_EN[$key]:-$key}"
    if [ "$LANGUAGE" = "tr" ]; then
        printf "%s" "${TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

translate() {
    _translate_value "$1"
}

translate_fmt() {
    local key="$1"
    shift || true
    local template
    template="$(_translate_value "$key")"
    # shellcheck disable=SC2059
    printf "$template" "$@"
}

# Modül indirmeleri için temel URL (ortak kullanılır, gerekirse dışarıdan BASE_URL override edilebilir)
BASE_URL="${BASE_URL:-https://raw.githubusercontent.com/tamerkaraca/linux-ai-setup-script/main/modules}"

# Ortak yardımcı fonksiyonlar
reload_shell_configs() {
    local mode="${1:-verbose}"
    local candidates=()
    local shell_name
    shell_name=$(basename "${SHELL:-}")

    case "$shell_name" in
        zsh)
            candidates=("$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile")
            ;;
        bash)
            candidates=("$HOME/.bashrc" "$HOME/.profile" "$HOME/.zshrc")
            ;;
        *)
            candidates=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
            ;;
    esac

    local sourced_file=""
    for rc_file in "${candidates[@]}"; do
        if source_shell_config "$rc_file"; then
            sourced_file="$rc_file"
            break
        fi
    done

    if [ "$mode" = "silent" ]; then
        return
    fi

    if [ -n "$sourced_file" ]; then
        echo -e "${GREEN}${INFO_TAG}${NC} $(translate_fmt log_shell_reload_success "$sourced_file")"
    else
        echo -e "${YELLOW}${WARN_TAG}${NC} $(translate log_shell_reload_missing)"
    fi
}

detect_package_manager() {
    echo -e "${YELLOW}${INFO_TAG}${NC} $(translate log_detect_pkg_manager)"
    
    if command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        UPDATE_CMD="sudo dnf upgrade -y"
        INSTALL_CMD="sudo dnf install -y"
    elif command -v apt &> /dev/null; then
        PKG_MANAGER="apt"
        UPDATE_CMD="sudo DEBIAN_FRONTEND=noninteractive apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y"
        INSTALL_CMD="sudo DEBIAN_FRONTEND=noninteractive apt install -y"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        UPDATE_CMD="sudo yum update -y"
        INSTALL_CMD="sudo yum install -y"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
        UPDATE_CMD="sudo pacman -Syu --noconfirm"
        INSTALL_CMD="sudo pacman -S --noconfirm"
    else
        echo -e "${RED}${ERROR_TAG}${NC} $(translate log_pkg_manager_missing)"
        exit 1
    fi
    
    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(translate_fmt log_pkg_manager_detected "$PKG_MANAGER")"
}

dnf_group_install() {
    local group_name="$1"
    local dnf_bin="dnf"
    if command -v dnf &>/dev/null; then
        dnf_bin="dnf"
    elif command -v dnf5 &>/dev/null; then
        dnf_bin="dnf5"
    fi

    local group_cmd="groupinstall"
    if "$dnf_bin" --version 2>/dev/null | head -n1 | grep -qi "dnf5"; then
        group_cmd="group install"
    fi

    if [ "$group_cmd" = "groupinstall" ]; then
        sudo "$dnf_bin" groupinstall "$group_name" -y
    else
        sudo "$dnf_bin" group install -y "$group_name"
    fi
}

update_system() {
    echo -e "\n${YELLOW}${INFO_TAG}${NC} $(translate log_system_update_start)"
    eval "$UPDATE_CMD"
    
    echo -e "${YELLOW}${INFO_TAG}${NC} $(translate log_system_install_basics)"
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        echo -e "${YELLOW}${INFO_TAG}${NC} $(translate_fmt log_install_packages "curl, wget, git, jq, zip, unzip, p7zip-full")"
        eval "$INSTALL_CMD" curl wget git jq zip unzip p7zip-full
        echo -e "${YELLOW}${INFO_TAG}${NC} $(translate_fmt log_install_devtools "build-essential")"
        eval "$INSTALL_CMD" build-essential
        
    elif [ "$PKG_MANAGER" = "dnf" ]; then
        echo -e "${YELLOW}${INFO_TAG}${NC} $(translate_fmt log_install_packages "curl, wget, git, jq, zip, unzip, p7zip")"
        eval "$INSTALL_CMD" curl wget git jq zip unzip p7zip
        echo -e "${YELLOW}${INFO_TAG}${NC} $(translate_fmt log_install_devtools "Development Tools")"
        dnf_group_install "Development Tools"
        
    elif [ "$PKG_MANAGER" = "pacman" ]; then
        echo -e "${YELLOW}${INFO_TAG}${NC} $(translate_fmt log_install_packages "curl, wget, git, jq, zip, unzip, p7zip")"
        eval "$INSTALL_CMD" curl wget git jq zip unzip p7zip
        echo -e "${YELLOW}${INFO_TAG}${NC} $(translate_fmt log_install_devtools "base-devel")"
        sudo pacman -S base-devel --noconfirm
        
    elif [ "$PKG_MANAGER" = "yum" ]; then
        echo -e "${YELLOW}${INFO_TAG}${NC} $(translate_fmt log_install_packages "curl, wget, git, jq, zip, unzip, p7zip")"
        eval "$INSTALL_CMD" curl wget git jq zip unzip p7zip
        echo -e "${YELLOW}${INFO_TAG}${NC} $(translate_fmt log_install_devtools "Development Tools")"
        sudo yum groupinstall "Development Tools" -y
    fi
    
    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(translate log_system_update_done)"
}

mask_secret() {
    local secret="$1"
    local length=${#secret}
    if [ "$length" -le 8 ]; then
        echo "$secret"
        return
    fi
    local prefix=${secret:0:4}
    local suffix=${secret: -4}
    local middle_length=$((length - 8))
    local mask=""
    while [ ${#mask} -lt "$middle_length" ]; do
        mask="${mask}*"
    done
    echo "${prefix}${mask}${suffix}"
}

# Python kurulumu
install_python() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(translate log_python_install_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    if command -v python3 &> /dev/null; then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(translate_fmt log_python_already "$(python3 --version)")"
        return 0
    fi
    
    echo -e "${YELLOW}${INFO_TAG}${NC} $(translate log_python_installing)"
    eval "$INSTALL_CMD" python3 python3-pip python3-venv
    
    if command -v python3 &> /dev/null; then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(translate_fmt log_python_success "$(python3 --version)")"
    else
        echo -e "${RED}${ERROR_TAG}${NC} $(translate log_python_failed)"
        return 1
    fi
}

# Pip kurulumu/güncelleme
install_pip() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(translate log_pip_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    if ! command -v python3 &> /dev/null; then
        echo -e "${YELLOW}${WARN_TAG}${NC} $(translate log_python_missing_for_pip)"
        if ! install_python; then
            echo -e "${RED}${ERROR_TAG}${NC} $(translate log_python_failed)"
            return 1
        fi
    fi
    
    echo -e "${YELLOW}${INFO_TAG}${NC} $(translate log_pip_upgrading)"
    
    local pip_upgrade_cmd="python3 -m pip install --upgrade pip"
    local pip_install_fallback_cmd="curl -sS https://bootstrap.pypa.io/get-pip.py | python3"

    # Pip'in python3 modülü olarak mevcut olup olmadığını kontrol et
    if ! python3 -m pip --version &> /dev/null; then
        echo -e "${YELLOW}${WARN_TAG}${NC} $(translate log_pip_missing)"
        if ! $pip_install_fallback_cmd; then
            echo -e "${RED}${ERROR_TAG}${NC} $(translate log_pip_getpip_failed)"
            return 1
        fi
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(translate log_pip_getpip_success)"
    fi

    local pip_status=0
    # Pip'i güncelleme
    if ! $pip_upgrade_cmd 2>&1 | grep -q "externally-managed-environment"; then
        # Başarılı veya başka bir hata, externally-managed-environment değil
        if ! $pip_upgrade_cmd; then
            pip_status=$?
        fi
    else
        # externally-managed-environment hatası, --break-system-packages ile dene
        echo -e "${YELLOW}${INFO_TAG}${NC} $(translate log_pip_external_retry)"
        if ! $pip_upgrade_cmd --break-system-packages; then
            pip_status=$?
        fi
    fi

    # Eğer güncelleme başarısız olursa
    if [ $pip_status -ne 0 ]; then
        echo -e "${RED}${ERROR_TAG}${NC} $(translate log_pip_upgrade_failed)"
        return 1
    fi
    
    if [ $pip_status -eq 0 ]; then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(translate_fmt log_pip_version "$(python3 -m pip --version)")"
        echo -e "\n${CYAN}${INFO_TAG}${NC} $(translate log_pip_tips_header)"
        echo -e "${GREEN}$(translate log_pip_tip_install)${NC}"
        echo -e "${GREEN}$(translate log_pip_tip_venv)${NC}"
        echo -e "${GREEN}$(translate log_pip_tip_system)${NC}"
        echo -e "${YELLOW}$(translate log_pip_tip_note)${NC}"
    else
        echo -e "${RED}${ERROR_TAG}${NC} $(translate log_pip_upgrade_failed)"
        return 1
    fi
}

# Pipx kurulumu
install_pipx() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(translate log_pipx_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    if ! command -v python3 &> /dev/null; then
        echo -e "${YELLOW}${WARN_TAG}${NC} $(translate log_python_missing_for_pipx)"
        install_python
    fi
    
    echo -e "${YELLOW}${INFO_TAG}${NC} $(translate log_pipx_pkg_install)"
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        eval "$INSTALL_CMD" pipx
    elif [ "$PKG_MANAGER" = "dnf" ]; then
        eval "$INSTALL_CMD" pipx
    elif [ "$PKG_MANAGER" = "pacman" ]; then
        eval "$INSTALL_CMD" python-pipx
    elif [ "$PKG_MANAGER" = "yum" ]; then
        eval "$INSTALL_CMD" pipx
    fi
    
    if ! command -v pipx &> /dev/null; then
        echo -e "${YELLOW}${INFO_TAG}${NC} $(translate log_pipx_pkg_missing)"
        
        if python3 -m pip install --user pipx 2>&1 | grep -q "externally-managed-environment"; then
            echo -e "${YELLOW}${INFO_TAG}${NC} $(translate log_pipx_external_retry)"
            
            TEMP_VENV="/tmp/pipx_install_venv"
            rm -rf "$TEMP_VENV"
            python3 -m venv "$TEMP_VENV"
            
            "$TEMP_VENV/bin/pip" install pipx
            
            mkdir -p "$HOME/.local/bin"
            cp "$TEMP_VENV/bin/pipx" "$HOME/.local/bin/"
            
            mkdir -p "$HOME/.local/pipx"
            cp -r "$TEMP_VENV/lib/python"*"/site-packages/pipx" "$HOME/.local/pipx/" 2>/dev/null || true
            
            rm -rf "$TEMP_VENV"
            
            if ! command -v pipx &> /dev/null; then
                echo -e "${YELLOW}${WARN_TAG}${NC} $(translate log_break_system_packages_retry)"
                python3 -m pip install --user --break-system-packages pipx
            fi
        else
            python3 -m pip install --user pipx
        fi
        
        if command -v pipx &> /dev/null;
        then
            python3 -m pipx ensurepath 2>/dev/null || pipx ensurepath 2>/dev/null || true
        fi
    fi
    
    export PATH="$HOME/.local/bin:$PATH"
    
    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
        if [ -f "$rc_file" ]; then
            if ! grep -q '.local/bin' "$rc_file"; then
                echo '' >> "$rc_file"
                echo "export PATH=\"$HOME/.local/bin:$PATH\"" >> "$rc_file"
            fi
        fi
    done
    
    reload_shell_configs
    
    if command -v pipx &> /dev/null; then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(translate_fmt log_pipx_success "$(pipx --version 2>/dev/null || echo 'installed')")"
    else
        echo -e "${RED}${ERROR_TAG}${NC} $(translate log_pipx_failed)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(translate log_pipx_manual_hint)"
        return 1
    fi
}

# PATH yardımcıları ve npm kurulum fallback'i

# Belirli bir dizinin PATH'e eklendiğinden emin olur ve gerekli durumda shell rc dosyalarını günceller.
ensure_path_contains_dir() {
    local target_dir="$1"
    local reason="${2:-custom path entry}"
    local updated_files=()

    if [[ -z "${target_dir}" ]]; then
        return 0
    fi

    if [[ ":$PATH:" != *":${target_dir}:"* ]]; then
        export PATH="${target_dir}:$PATH"
    fi

    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
        if [ -f "$rc_file" ] && ! grep -Fq "$target_dir" "$rc_file"; then
            {
                echo ""
                echo "# Added by linux-ai-setup-script (${reason})"
                echo "export PATH=\"${target_dir}:\$PATH\""
            } >> "$rc_file"
            updated_files+=("$rc_file")
        fi
    done

    if [ ${#updated_files[@]} -gt 0 ]; then
        echo -e "${YELLOW}${INFO_TAG}${NC} '${target_dir}' PATH'e eklendi (${updated_files[*]}). Terminalinizi yeniden başlatın veya 'source ${updated_files[0]}' komutunu çalıştırın."
    fi

    hash -r 2>/dev/null || true
}

locate_npm_binary() {
    local bin_name="$1"
    if command -v "$bin_name" >/dev/null 2>&1; then
        command -v "$bin_name"
        return 0
    fi
    if [ -n "${NPM_LAST_INSTALL_PREFIX:-}" ] && [ -x "${NPM_LAST_INSTALL_PREFIX}/bin/$bin_name" ]; then
        echo "${NPM_LAST_INSTALL_PREFIX}/bin/$bin_name"
        return 0
    fi
    local user_prefix="${NPM_USER_PREFIX:-$HOME/.local}"
    if [ -x "${user_prefix}/bin/$bin_name" ]; then
        echo "${user_prefix}/bin/$bin_name"
        return 0
    fi
    return 1
}

# Kullanıcı bazlı npm prefix dizinini hazırlar ve yolunu döner.
npm_prepare_user_prefix() {
    local prefix="${NPM_USER_PREFIX:-$HOME/.local}"
    mkdir -p "${prefix}/bin" "${prefix}/lib/node_modules"
    echo "$prefix"
}

# npm global kurulumları için /usr/local gibi yazılamayan dizinlerde kullanıcı bazlı prefix'e düşer.
npm_install_global_with_fallback() {
    local package="$1"
    local display_name="${2:-$1}"
    local prefer_user_prefix="${3:-false}"
    local default_prefix=""
    local fallback_prefix

    NPM_LAST_INSTALL_PREFIX=""

    if [ "$prefer_user_prefix" != "true" ]; then
        default_prefix=$(npm config get prefix 2>/dev/null | tr -d '\r') || true
        if [ -z "$default_prefix" ]; then
            default_prefix=$(npm root -g 2>/dev/null | xargs dirname 2>/dev/null || true)
        fi
    fi

    if [ -n "$default_prefix" ] && [ -d "$default_prefix" ] && [ -w "$default_prefix" ]; then
        if npm install -g "$package"; then
            NPM_LAST_INSTALL_PREFIX="$default_prefix"
            ensure_path_contains_dir "${default_prefix}/bin" "npm global prefix"
            return 0
        fi
        echo -e "${YELLOW}${WARN_TAG}${NC} ${display_name} varsayılan prefixte kurulamadı. Kullanıcı dizinine düşülüyor..."
    elif [ -n "$default_prefix" ]; then
        echo -e "${YELLOW}${INFO_TAG}${NC} ${display_name} için varsayılan prefix (${default_prefix}) yazılamıyor; kullanıcı dizinine kurulacak."
    fi

    fallback_prefix=$(npm_prepare_user_prefix)
    echo -e "${YELLOW}${INFO_TAG}${NC} ${display_name} kullanıcı prefixine kuruluyor: ${fallback_prefix}"
    if npm install -g --prefix "$fallback_prefix" "$package"; then
        NPM_LAST_INSTALL_PREFIX="$fallback_prefix"
        ensure_path_contains_dir "${fallback_prefix}/bin" "npm user prefix"
        return 0
    fi

    echo -e "${RED}${ERROR_TAG}${NC} ${display_name} kullanıcı prefixine kurulamadı."
    return 1
}

NPM_LAST_INSTALL_PREFIX="${NPM_LAST_INSTALL_PREFIX:-}"

NODE_BOOTSTRAP_ATTEMPTED="${NODE_BOOTSTRAP_ATTEMPTED:-0}"

find_module_script() {
    local target="$1"
    local -a candidates=("./modules/${target}")
    if [ -n "${BASH_SOURCE[0]:-}" ]; then
        local util_dir
        util_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        candidates+=("${util_dir}/${target}")
    fi

    local candidate
    for candidate in "${candidates[@]}"; do
        if [ -f "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done

    return 1
}

bootstrap_node_runtime() {
    if [ "${NODE_BOOTSTRAP_ATTEMPTED}" = "1" ]; then
        return 1
    fi

    local installer_path
    if ! installer_path="$(find_module_script "install_nodejs_tools.sh")"; then
        echo -e "${YELLOW}${WARN_TAG}${NC} Node.js kurulumu için 'install_nodejs_tools.sh' bulunamadı."
        NODE_BOOTSTRAP_ATTEMPTED=1
        return 1
    fi

    NODE_BOOTSTRAP_ATTEMPTED=1
    echo -e "${YELLOW}${INFO_TAG}${NC} Node.js eksik; otomatik kurulum deneniyor (${installer_path})."
    if bash "$installer_path" --node-only; then
        reload_shell_configs silent
        hash -r 2>/dev/null || true
        return 0
    fi

    echo -e "${RED}${ERROR_TAG}${NC} Node.js otomatik kurulumu başarısız oldu. Lütfen 'Ana Menü -> 3' seçeneğini manuel çalıştırın."
    return 1
}

require_node_version() {
    local min_major="${1:-18}"
    local context_label="${2:-Node.js}"
    local attempt_bootstrap="${3:-true}"

    if command -v node >/dev/null 2>&1; then
        local current_major
        current_major=$(node -v | sed -E 's/^v([0-9]+).*/\1/')
        if [ "${current_major:-0}" -ge "${min_major}" ]; then
            return 0
        fi
        echo -e "${YELLOW}${WARN_TAG}${NC} ${context_label} için Node.js v${min_major}+ gerekiyor, mevcut sürüm: $(node -v)."
    else
        echo -e "${YELLOW}${WARN_TAG}${NC} ${context_label} için Node.js v${min_major}+ gerekiyor ancak sistemde Node.js bulunamadı."
    fi

    if [ "$attempt_bootstrap" = true ] && bootstrap_node_runtime; then
        if command -v node >/dev/null 2>&1; then
            local refreshed_major
            refreshed_major=$(node -v | sed -E 's/^v([0-9]+).*/\1/')
            if [ "${refreshed_major:-0}" -ge "${min_major}" ]; then
                echo -e "${GREEN}${SUCCESS_TAG}${NC} Node.js kurulumu tamamlandı: $(node -v)"
                return 0
            fi
        fi
        echo -e "${YELLOW}${WARN_TAG}${NC} Node.js kuruldu ancak sürüm gereksinimini karşılamıyor."
    fi

    echo -e "${RED}${ERROR_TAG}${NC} ${context_label} kurulumu Node.js ${min_major}+ olmadan devam edemez."
    return 1
}
