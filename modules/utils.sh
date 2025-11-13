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

detect_system_language() {
    local locale_value="${LC_ALL:-${LANG:-}}"
    if [[ "$locale_value" =~ ^tr ]]; then
        echo "tr"
    else
        echo "en"
    fi
}

set_language() {
    local target_lang="$1"
    for lang in "${SUPPORTED_LANGUAGES[@]}"; do
        if [ "$lang" = "$target_lang" ]; then
            LANGUAGE="$lang"
            export LANGUAGE
            return 0
        fi
    done
    return 1
}

if [ -z "${LANGUAGE:-}" ]; then
    LANGUAGE="$(detect_system_language)"
fi
export LANGUAGE

get_language_label() {
    case "$1" in
        tr) echo "Türkçe" ;;
        *) echo "English" ;;
    esac
}

declare -A TEXT_EN=(
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
    ["fw_menu_title"]="AI Framework Installation Menu"
    ["fw_menu_hint"]="Use commas for multiple selections (e.g., 1,2)."
    ["fw_option1"]="SuperGemini Framework"
    ["fw_option2"]="SuperQwen Framework"
    ["fw_option3"]="SuperClaude Framework"
    ["fw_option4"]="Install every framework"
    ["fw_option_return"]="Return to main menu"
    ["fw_prompt_install_more"]="Install another AI framework? (y/n) [n]:"
)

declare -A TEXT_TR=(
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
    ["fw_menu_title"]="AI Framework Kurulum Menüsü"
    ["fw_menu_hint"]="Birden fazla seçim için virgül kullanın (örn: 1,2)."
    ["fw_option1"]="SuperGemini Framework"
    ["fw_option2"]="SuperQwen Framework"
    ["fw_option3"]="SuperClaude Framework"
    ["fw_option4"]="Tüm AI frameworklerini kur"
    ["fw_option_return"]="Ana menüye dön"
    ["fw_prompt_install_more"]="Başka bir AI framework kurmak ister misiniz? (e/h) [h]:"
)

translate() {
    local key="$1"
    local default_value="${TEXT_EN[$key]:-$key}"
    if [ "$LANGUAGE" = "tr" ]; then
        echo "${TEXT_TR[$key]:-$default_value}"
    else
        echo "$default_value"
    fi
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
        if [ -f "$rc_file" ]; then
            # shellcheck source=/dev/null
            . "$rc_file" && sourced_file="$rc_file" && break
        fi
    done

    if [ "$mode" = "silent" ]; then
        return
    fi

    if [ -n "$sourced_file" ]; then
        echo -e "${GREEN}[BİLGİ]${NC} Shell yapılandırmaları otomatik olarak yüklendi (${sourced_file})."
    else
        echo -e "${YELLOW}[UYARI]${NC} Shell yapılandırma dosyaları bulunamadı; gerekirse terminalinizi yeniden başlatın."
    fi
}

detect_package_manager() {
    echo -e "${YELLOW}[BİLGİ]${NC} İşletim sistemi ve paket yöneticisi tespit ediliyor..."
    
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
        echo -e "${RED}[HATA]${NC} Desteklenen bir paket yöneticisi bulunamadı!"
        exit 1
    fi
    
    echo -e "${GREEN}[BAŞARILI]${NC} Paket yöneticisi: $PKG_MANAGER"
}

update_system() {
    echo -e "\n${YELLOW}[BİLGİ]${NC} Sistem güncelleniyor..."
    eval "$UPDATE_CMD"
    
    echo -e "${YELLOW}[BİLGİ]${NC} Temel paketler, sıkıştırma ve geliştirme araçları kuruluyor..."
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} Kuruluyor: curl, wget, git, jq, zip, unzip, p7zip-full"
        eval "$INSTALL_CMD" curl wget git jq zip unzip p7zip-full
        echo -e "${YELLOW}[BİLGİ]${NC} Geliştirme araçları (build-essential) kuruluyor..."
        eval "$INSTALL_CMD" build-essential
        
    elif [ "$PKG_MANAGER" = "dnf" ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} Kuruluyor: curl, wget, git, jq, zip, unzip, p7zip"
        eval "$INSTALL_CMD" curl wget git jq zip unzip p7zip
        echo -e "${YELLOW}[BİLGİ]${NC} Geliştirme araçları (Development Tools) kuruluyor..."
        sudo dnf groupinstall "Development Tools" -y
        
    elif [ "$PKG_MANAGER" = "pacman" ]; then
        eval "$INSTALL_CMD" curl wget git jq zip unzip p7zip
        echo -e "${YELLOW}[BİLGİ]${NC} Geliştirme araçları (base-devel) kuruluyor..."
        sudo pacman -S base-devel --noconfirm
        
    elif [ "$PKG_MANAGER" = "yum" ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} Kuruluyor: curl, wget, git, jq, zip, unzip, p7zip"
        eval "$INSTALL_CMD" curl wget git jq zip unzip p7zip
        echo -e "${YELLOW}[BİLGİ]${NC} Geliştirme araçları (Development Tools) kuruluyor..."
        sudo yum groupinstall "Development Tools" -y
    fi
    
    echo -e "${GREEN}[BAŞARILI]${NC} Sistem güncelleme ve temel paket kurulumu tamamlandı!"
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
    echo -e "${YELLOW}[BİLGİ]${NC} Python kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    if command -v python3 &> /dev/null; then
        echo -e "${GREEN}[BAŞARILI]${NC} Python zaten kurulu: $(python3 --version)"
        return 0
    fi
    
    echo -e "${YELLOW}[BİLGİ]${NC} Python3 kuruluyor..."
    eval "$INSTALL_CMD" python3 python3-pip python3-venv
    
    if command -v python3 &> /dev/null; then
        echo -e "${GREEN}[BAŞARILI]${NC} Python kurulumu tamamlandı: $(python3 --version)"
    else
        echo -e "${RED}[HATA]${NC} Python kurulumu başarısız!"
        return 1
    fi
}

# Pip kurulumu/güncelleme
install_pip() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Pip kurulumu/güncelleme başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    if ! command -v python3 &> /dev/null; then
        echo -e "${YELLOW}[UYARI]${NC} Python kurulu değil, önce Python kuruluyor..."
        install_python
        if [ $? -ne 0 ]; then
            echo -e "${RED}[HATA]${NC} Python kurulumu başarısız oldu, Pip kurulamıyor."
            return 1
        fi
    fi
    
    echo -e "${YELLOW}[BİLGİ]${NC} Pip güncelleniyor..."
    
    local pip_upgrade_cmd="python3 -m pip install --upgrade pip"
    local pip_install_fallback_cmd="curl -sS https://bootstrap.pypa.io/get-pip.py | python3"

    # Pip'in python3 modülü olarak mevcut olup olmadığını kontrol et
    if ! python3 -m pip --version &> /dev/null; then
        echo -e "${YELLOW}[UYARI]${NC} Pip bulunamadı. get-pip.py ile kurulum deneniyor..."
        if ! $pip_install_fallback_cmd; then
            echo -e "${RED}[HATA]${NC} get-pip.py ile Pip kurulumu başarısız!"
            return 1
        fi
        echo -e "${GREEN}[BAŞARILI]${NC} Pip, get-pip.py ile kuruldu."
    fi

    # Pip'i güncelleme
    if ! $pip_upgrade_cmd 2>&1 | grep -q "externally-managed-environment"; then
        # Başarılı veya başka bir hata, externally-managed-environment değil
        $pip_upgrade_cmd
    else
        # externally-managed-environment hatası, --break-system-packages ile dene
        echo -e "${YELLOW}[BİLGİ]${NC} Externally-managed-environment hatası, --break-system-packages ile deneniyor..."
        $pip_upgrade_cmd --break-system-packages
    fi

    # Eğer güncelleme başarısız olursa
    if [ $? -ne 0 ]; then
        echo -e "${RED}[HATA]${NC} Pip güncellemesi başarısız!"
        return 1
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[BAŞARILI]${NC} Pip sürümü: $(python3 -m pip --version)"
        echo -e "\n${CYAN}[BİLGİ]${NC} Pip Kullanım İpuçları:"
        echo -e "  ${GREEN}•${NC} Paket kurma: ${GREEN}pip install paket_adi${NC}"
        echo -e "  ${GREEN}•${NC} Sanal ortamda kurma (önerilen): ${GREEN}python3 -m venv myenv && source myenv/bin/activate${NC}"
        echo -e "  ${GREEN}•${NC} Sistem geneli kurma: ${GREEN}pip install --break-system-packages paket_adi${NC}"
        echo -e "  ${YELLOW}•${NC} Not: Modern sistemlerde sanal ortam kullanımı önerilir (PEP 668)"
    else
        echo -e "${RED}[HATA]${NC} Pip güncellemesi başarısız!"
        return 1
    fi
}

# Pipx kurulumu
install_pipx() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Pipx kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    if ! command -v python3 &> /dev/null; then
        echo -e "${YELLOW}[UYARI]${NC} Python kurulu değil, önce Python kuruluyor..."
        install_python
    fi
    
    echo -e "${YELLOW}[BİLGİ]${NC} Sistem paket yöneticisi ile pipx kuruluyor..."
    
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
        echo -e "${YELLOW}[BİLGİ]${NC} Sistem paketi bulunamadı, manuel kurulum yapılıyor..."
        
        if python3 -m pip install --user pipx 2>&1 | grep -q "externally-managed-environment"; then
            echo -e "${YELLOW}[BİLGİ]${NC} Externally-managed-environment hatası, alternatif yöntem deneniyor..."
            
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
                echo -e "${YELLOW}[UYARI]${NC} --break-system-packages ile kurulum deneniyor..."
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
        echo -e "${GREEN}[BAŞARILI]${NC} Pipx kurulumu tamamlandı: $(pipx --version 2>/dev/null || echo 'kuruldu')"
    else
        echo -e "${RED}[HATA]${NC} Pipx kurulumu başarısız!"
        echo -e "${YELLOW}[BİLGİ]${NC} Manuel kurulum için: sudo apt install pipx"
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
        echo -e "${YELLOW}[BİLGİ]${NC} '${target_dir}' PATH'e eklendi (${updated_files[*]}). Terminalinizi yeniden başlatın veya 'source ${updated_files[0]}' komutunu çalıştırın."
    fi

    hash -r 2>/dev/null || true
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
            return 0
        fi
        echo -e "${YELLOW}[UYARI]${NC} ${display_name} varsayılan prefixte kurulamadı. Kullanıcı dizinine düşülüyor..."
    elif [ -n "$default_prefix" ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} ${display_name} için varsayılan prefix (${default_prefix}) yazılamıyor; kullanıcı dizinine kurulacak."
    fi

    fallback_prefix=$(npm_prepare_user_prefix)
    echo -e "${YELLOW}[BİLGİ]${NC} ${display_name} kullanıcı prefixine kuruluyor: ${fallback_prefix}"
    if npm install -g --prefix "$fallback_prefix" "$package"; then
        NPM_LAST_INSTALL_PREFIX="$fallback_prefix"
        ensure_path_contains_dir "${fallback_prefix}/bin" "npm user prefix"
        return 0
    fi

    echo -e "${RED}[HATA]${NC} ${display_name} kullanıcı prefixine kurulamadı."
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
        echo -e "${YELLOW}[UYARI]${NC} Node.js kurulumu için 'install_nodejs_tools.sh' bulunamadı."
        NODE_BOOTSTRAP_ATTEMPTED=1
        return 1
    fi

    NODE_BOOTSTRAP_ATTEMPTED=1
    echo -e "${YELLOW}[BİLGİ]${NC} Node.js eksik; otomatik kurulum deneniyor (${installer_path})."
    if bash "$installer_path" --node-only; then
        reload_shell_configs silent
        hash -r 2>/dev/null || true
        return 0
    fi

    echo -e "${RED}[HATA]${NC} Node.js otomatik kurulumu başarısız oldu. Lütfen 'Ana Menü -> 3' seçeneğini manuel çalıştırın."
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
        echo -e "${YELLOW}[UYARI]${NC} ${context_label} için Node.js v${min_major}+ gerekiyor, mevcut sürüm: $(node -v)."
    else
        echo -e "${YELLOW}[UYARI]${NC} ${context_label} için Node.js v${min_major}+ gerekiyor ancak sistemde Node.js bulunamadı."
    fi

    if [ "$attempt_bootstrap" = true ] && bootstrap_node_runtime; then
        if command -v node >/dev/null 2>&1; then
            local refreshed_major
            refreshed_major=$(node -v | sed -E 's/^v([0-9]+).*/\1/')
            if [ "${refreshed_major:-0}" -ge "${min_major}" ]; then
                echo -e "${GREEN}[BAŞARILI]${NC} Node.js kurulumu tamamlandı: $(node -v)"
                return 0
            fi
        fi
        echo -e "${YELLOW}[UYARI]${NC} Node.js kuruldu ancak sürüm gereksinimini karşılamıyor."
    fi

    echo -e "${RED}[HATA]${NC} ${context_label} kurulumu Node.js ${min_major}+ olmadan devam edemez."
    return 1
}
