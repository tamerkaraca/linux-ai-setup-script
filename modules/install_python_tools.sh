#!/bin/bash
set -euo pipefail

# Ortak yardımcı fonksiyonları yükle
UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"

CURRENT_LANG="${LANGUAGE:-en}"
if [ "$CURRENT_LANG" = "tr" ]; then
    INFO_TAG="${INFO_TAG}"
    WARN_TAG="${WARN_TAG}"
    ERROR_TAG="${ERROR_TAG}"
    SUCCESS_TAG="${SUCCESS_TAG}"
else
    INFO_TAG="[INFO]"
    WARN_TAG="[WARNING]"
    ERROR_TAG="[ERROR]"
    SUCCESS_TAG="[SUCCESS]"
fi

declare -A PY_TEXT_EN=(
    ["menu_title"]="Python Tooling Menu"
    ["menu_option1"]="Install Python 3"
    ["menu_option2"]="Install or update Pip"
    ["menu_option3"]="Install Pipx"
    ["menu_option4"]="Install UV"
    ["menu_option_all"]="Install everything"
    ["menu_option0"]="Return to main menu"
    ["menu_hint"]="Use commas for multiple selections (e.g., 1,3)."
    ["menu_prompt"]="Your choice"
    ["menu_returning"]="Returning to the main menu..."
    ["menu_invalid"]="Invalid selection"
    ["menu_none"]="No valid selection detected."
    ["menu_continue"]="Press Enter to continue, or type 0 to exit."
    ["python_title"]="Starting Python installation..."
    ["python_already"]="Python is already installed"
    ["python_install"]="Installing Python 3..."
    ["python_success"]="Python installation completed"
    ["python_failed"]="Python installation failed!"
    ["pip_title"]="Starting Pip installation/update..."
    ["pip_python_missing"]="Python is not installed, installing Python first..."
    ["pip_missing"]="Pip module not found, installing via python3 -m ensurepip..."
    ["pip_ensurepip_success"]="Pip installed via ensurepip."
    ["pip_ensurepip_fail"]="ensurepip failed, trying package manager..."
    ["pip_pkg_attempt"]="Installing pip via package manager."
    ["pip_pkg_success"]="Pip installed via package manager."
    ["pip_pkg_fail"]="Package manager attempt failed, trying get-pip.py..."
    ["pip_getpip_download_fail"]="Failed to download get-pip.py; pip installation aborted."
    ["pip_getpip_success"]="Pip installed via get-pip.py."
    ["pip_getpip_fail"]="get-pip.py installation failed."
    ["pip_bootstrap_fail"]="Pip installation could not be completed."
    ["pip_upgrading"]="Upgrading pip..."
    ["pip_break"]="Encountered externally-managed environment; retrying with --break-system-packages..."
    ["pip_up_fail"]="Pip upgrade failed!"
    ["pip_version"]="Current pip version"
    ["pip_tips"]="Pip usage tips:"
    ["pip_tip_install"]="• Install a package: pip install <name>"
    ["pip_tip_venv"]="• Use virtual environments (recommended): python3 -m venv myenv && source myenv/bin/activate"
    ["pip_tip_system"]="• System-wide install: pip install --break-system-packages <name>"
    ["pip_tip_note"]="• Note: modern systems recommend virtual environments (PEP 668)."
    ["pipx_title"]="Starting Pipx installation..."
    ["pipx_python_missing"]="Python is not installed, installing Python first..."
    ["pipx_pkg_attempt"]="Installing pipx via package manager..."
    ["pipx_pkg_missing"]="Package not found, falling back to manual installation..."
    ["pipx_venv_fail"]="Manual pipx installation failed."
    ["pipx_manual_hint"]="Manual install hint: sudo apt install pipx"
    ["pipx_break"]="Externally-managed environment detected, trying an alternate method..."
    ["pipx_success"]="Pipx installation completed"
    ["pipx_tips"]="Pipx usage tips:"
    ["pipx_tip_install"]="• Install: pipx install <name>"
    ["pipx_tip_list"]="• List: pipx list"
    ["pipx_tip_remove"]="• Remove: pipx uninstall <name>"
    ["pipx_tip_upgrade"]="• Update all: pipx upgrade-all"
    ["pipx_fail"]="Pipx installation failed!"
    ["uv_title"]="Starting UV installation..."
    ["uv_install"]="Installing UV..."
    ["uv_success"]="UV installation completed"
    ["uv_fail"]="UV installation failed!"
    ["uv_tips"]="UV usage tips:"
    ["uv_tip_install"]="• Install packages: uv pip install <name>"
    ["uv_tip_venv"]="• Create a virtual environment: uv venv"
    ["stack_success"]="Python, pip, pipx, and UV installed successfully!"
)

declare -A PY_TEXT_TR=(
    ["menu_title"]="Python Araçları Kurulum Menüsü"
    ["menu_option1"]="Python 3 kur"
    ["menu_option2"]="Pip kur / güncelle"
    ["menu_option3"]="Pipx kur"
    ["menu_option4"]="UV kur"
    ["menu_option_all"]="Hepsini kur"
    ["menu_option0"]="Ana menü"
    ["menu_hint"]="Birden fazla seçim için virgülle ayırabilirsiniz (örn: 1,3)."
    ["menu_prompt"]="Seçiminiz"
    ["menu_returning"]="Ana menüye dönülüyor..."
    ["menu_invalid"]="Geçersiz seçim"
    ["menu_none"]="Geçerli bir seçim yapılmadı."
    ["menu_continue"]="Devam için Enter'a basın, çıkmak için 0 yazın."
    ["python_title"]="Python kurulumu başlatılıyor..."
    ["python_already"]="Python zaten kurulu"
    ["python_install"]="Python3 kuruluyor..."
    ["python_success"]="Python kurulumu tamamlandı"
    ["python_failed"]="Python kurulumu başarısız!"
    ["pip_title"]="Pip kurulumu/güncelleme başlatılıyor..."
    ["pip_python_missing"]="Python kurulu değil, önce Python kuruluyor..."
    ["pip_missing"]="Pip modülü bulunamadı, python3 -m ensurepip ile kuruluyor..."
    ["pip_ensurepip_success"]="Pip, ensurepip ile kuruldu."
    ["pip_ensurepip_fail"]="ensurepip başarısız oldu, paket yöneticisi ile kurulumu deneniyor..."
    ["pip_pkg_attempt"]="Paket yöneticisi ile pip kurulumu deneniyor."
    ["pip_pkg_success"]="Pip, paket yöneticisi ile kuruldu."
    ["pip_pkg_fail"]="Paket yöneticisi başarısız oldu, get-pip.py ile deneniyor..."
    ["pip_getpip_download_fail"]="get-pip.py indirilemedi; Pip kurulamadı."
    ["pip_getpip_success"]="Pip, get-pip.py ile kuruldu."
    ["pip_getpip_fail"]="get-pip.py ile kurulum başarısız oldu."
    ["pip_bootstrap_fail"]="Pip kurulumu tamamlanamadı."
    ["pip_upgrading"]="Pip güncelleniyor..."
    ["pip_break"]="Externally-managed-environment hatası, --break-system-packages ile yeniden deneniyor..."
    ["pip_up_fail"]="Pip güncellemesi başarısız!"
    ["pip_version"]="Pip sürümü"
    ["pip_tips"]="Pip kullanım ipuçları:"
    ["pip_tip_install"]="• Paket kurma: pip install paket_adi"
    ["pip_tip_venv"]="• Sanal ortam (önerilen): python3 -m venv myenv && source myenv/bin/activate"
    ["pip_tip_system"]="• Sistem geneli kurulum: pip install --break-system-packages paket_adi"
    ["pip_tip_note"]="• Not: Modern sistemlerde sanal ortam kullanımı önerilir (PEP 668)."
    ["pipx_title"]="Pipx kurulumu başlatılıyor..."
    ["pipx_python_missing"]="Python kurulu değil, önce Python kuruluyor..."
    ["pipx_pkg_attempt"]="Sistem paket yöneticisi ile pipx kuruluyor..."
    ["pipx_pkg_missing"]="Paket bulunamadı, manuel kurulum yapılıyor..."
    ["pipx_venv_fail"]="Pipx manuel kurulumu başarısız oldu."
    ["pipx_manual_hint"]="Manuel kurulum için: sudo apt install pipx"
    ["pipx_break"]="Externally-managed-environment hatası, alternatif yöntem deneniyor..."
    ["pipx_success"]="Pipx kurulumu tamamlandı"
    ["pipx_tips"]="Pipx kullanım ipuçları:"
    ["pipx_tip_install"]="• Paket kurma: pipx install paket_adi"
    ["pipx_tip_list"]="• Paket listesi: pipx list"
    ["pipx_tip_remove"]="• Paket kaldırma: pipx uninstall paket_adi"
    ["pipx_tip_upgrade"]="• Tüm paketleri güncelle: pipx upgrade-all"
    ["pipx_fail"]="Pipx kurulumu başarısız!"
    ["uv_title"]="UV kurulumu başlatılıyor..."
    ["uv_install"]="UV kuruluyor..."
    ["uv_success"]="UV kurulumu tamamlandı"
    ["uv_fail"]="UV kurulumu başarısız!"
    ["uv_tips"]="UV kullanım ipuçları:"
    ["uv_tip_install"]="• Paket kurma: uv pip install paket_adi"
    ["uv_tip_venv"]="• Sanal ortam oluşturma: uv venv"
    ["stack_success"]="Python ve ilgili araçların tamamı kuruldu!"
)

py_text() {
    local key="$1"
    local default_value="${PY_TEXT_EN[$key]:-$key}"
    if [ "$CURRENT_LANG" = "tr" ]; then
        echo "${PY_TEXT_TR[$key]:-$default_value}"
    else
        echo "$default_value"
    fi
}

# Python kurulumu
install_python() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(py_text python_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    if command -v python3 &> /dev/null; then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(py_text python_already): $(python3 --version)"
        return 0
    fi
    
    echo -e "${YELLOW}${INFO_TAG}${NC} $(py_text python_install)"
    eval "$INSTALL_CMD" python3 python3-pip python3-venv
    
    if command -v python3 &> /dev/null; then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(py_text python_success): $(python3 --version)"
    else
        echo -e "${RED}${ERROR_TAG}${NC} $(py_text python_failed)"
        return 1
    fi
}

install_pip_via_package_manager() {
    if [ -z "${PKG_MANAGER:-}" ]; then
        return 1
    fi

    local pkg_name=""
    case "$PKG_MANAGER" in
        apt|dnf|yum) pkg_name="python3-pip" ;;
        pacman) pkg_name="python-pip" ;;
        *) return 1 ;;
    esac

    echo -e "${YELLOW}${INFO_TAG}${NC} $(py_text pip_pkg_attempt) (${PKG_MANAGER})."
    if eval "$INSTALL_CMD" "$pkg_name"; then
        return 0
    fi
    return 1
}

# Pip kurulumu/güncelleme
install_pip() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(py_text pip_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    if ! command -v python3 &> /dev/null; then
        echo -e "${YELLOW}${WARN_TAG}${NC} $(py_text pip_python_missing)"
        install_python
    fi
    
    local pip_bootstrap_success=false

    if ! python3 -m pip --version &> /dev/null; then
        echo -e "${YELLOW}${WARN_TAG}${NC} $(py_text pip_missing)"
        if python3 -m ensurepip --upgrade >/dev/null 2>&1; then
            echo -e "${GREEN}${INFO_TAG}${NC} $(py_text pip_ensurepip_success)"
            pip_bootstrap_success=true
        else
            echo -e "${YELLOW}${WARN_TAG}${NC} $(py_text pip_ensurepip_fail)"
            if install_pip_via_package_manager && python3 -m pip --version &> /dev/null; then
                echo -e "${GREEN}${INFO_TAG}${NC} $(py_text pip_pkg_success)"
                pip_bootstrap_success=true
            else
                echo -e "${YELLOW}${WARN_TAG}${NC} $(py_text pip_pkg_fail)"
                local get_pip_script
                get_pip_script=$(mktemp)
                if ! curl -fsSL https://bootstrap.pypa.io/get-pip.py -o "$get_pip_script"; then
                    echo -e "${RED}${ERROR_TAG}${NC} $(py_text pip_getpip_download_fail)"
                    rm -f "$get_pip_script"
                    return 1
                fi
                if python3 "$get_pip_script" --break-system-packages >/dev/null 2>&1; then
                    echo -e "${GREEN}${INFO_TAG}${NC} $(py_text pip_getpip_success)"
                    pip_bootstrap_success=true
                else
                    echo -e "${RED}${ERROR_TAG}${NC} $(py_text pip_getpip_fail)"
                    rm -f "$get_pip_script"
                    return 1
                fi
                rm -f "$get_pip_script"
            fi
        fi
    else
        pip_bootstrap_success=true
    fi

    if [ "$pip_bootstrap_success" != true ]; then
        echo -e "${RED}${ERROR_TAG}${NC} $(py_text pip_bootstrap_fail)"
        return 1
    fi
    
    echo -e "${YELLOW}${INFO_TAG}${NC} $(py_text pip_upgrading)"
    
    local upgrade_output=""
    local upgrade_status=0
    upgrade_output=$(python3 -m pip install --upgrade pip 2>&1) || upgrade_status=$?
    
    if [ $upgrade_status -ne 0 ]; then
        if echo "$upgrade_output" | grep -q "externally-managed-environment"; then
            echo -e "${YELLOW}${INFO_TAG}${NC} $(py_text pip_break)"
            python3 -m pip install --upgrade pip --break-system-packages
        else
            echo -e "${RED}${ERROR_TAG}${NC} $(py_text pip_up_fail)"
            echo "$upgrade_output"
            return 1
        fi
    else
        # Başarılı çıktıyı da kullanıcıya göster
        [ -n "$upgrade_output" ] && echo "$upgrade_output"
    fi
    
    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(py_text pip_version): $(python3 -m pip --version)"
    echo -e "\n${CYAN}${INFO_TAG}${NC} $(py_text pip_tips)"
    echo -e "  ${GREEN}$(py_text pip_tip_install)${NC}"
    echo -e "  ${GREEN}$(py_text pip_tip_venv)${NC}"
    echo -e "  ${GREEN}$(py_text pip_tip_system)${NC}"
    echo -e "  ${YELLOW}$(py_text pip_tip_note)${NC}"
}

# Pipx kurulumu
install_pipx() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(py_text pipx_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    if ! command -v python3 &> /dev/null; then
        echo -e "${YELLOW}${WARN_TAG}${NC} $(py_text pipx_python_missing)"
        install_python
    fi
    
    echo -e "${YELLOW}${INFO_TAG}${NC} $(py_text pipx_pkg_attempt)"
    
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
        echo -e "${YELLOW}${INFO_TAG}${NC} $(py_text pipx_pkg_missing)"
        
        if python3 -m pip install --user pipx 2>&1 | grep -q "externally-managed-environment"; then
            echo -e "${YELLOW}${INFO_TAG}${NC} $(py_text pipx_break)"
            
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
                echo -e "${YELLOW}${WARN_TAG}${NC} --break-system-packages"
                python3 -m pip install --user --break-system-packages pipx
            fi
        else
            python3 -m pip install --user pipx
        fi
        
        if command -v pipx &> /dev/null; then
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
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(py_text pipx_success): $(pipx --version 2>/dev/null || echo 'pipx')"
        echo -e "\n${CYAN}${INFO_TAG}${NC} $(py_text pipx_tips)"
        echo -e "  ${GREEN}$(py_text pipx_tip_install)${NC}"
        echo -e "  ${GREEN}$(py_text pipx_tip_list)${NC}"
        echo -e "  ${GREEN}$(py_text pipx_tip_remove)${NC}"
        echo -e "  ${GREEN}$(py_text pipx_tip_upgrade)${NC}"
    else
        echo -e "${RED}${ERROR_TAG}${NC} $(py_text pipx_fail)"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(py_text pipx_manual_hint)"
        return 1
    fi
}

# UV kurulumu
install_uv() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(py_text uv_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    echo -e "${YELLOW}${INFO_TAG}${NC} $(py_text uv_install)"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    export PATH="$HOME/.cargo/bin:$PATH"
    
    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
        if [ -f "$rc_file" ]; then
            if ! grep -q '.cargo/bin' "$rc_file"; then
                echo '' >> "$rc_file"
                echo "export PATH=\"$HOME/.cargo/bin:$PATH\"" >> "$rc_file"
            fi
        fi
    done
    
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env" 2>/dev/null || true
    
    if command -v uv &> /dev/null; then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} $(py_text uv_success): $(uv --version)"
        echo -e "\n${CYAN}${INFO_TAG}${NC} $(py_text uv_tips)"
        echo -e "  ${GREEN}$(py_text uv_tip_install)${NC}"
        echo -e "  ${GREEN}$(py_text uv_tip_venv)${NC}"
    else
        echo -e "${RED}${ERROR_TAG}${NC} $(py_text uv_fail)"
        return 1
    fi
}

run_python_tools_menu() {
    while true; do
        clear
        echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
        printf "${BLUE}║%*s║${NC}\n" -43 " $(py_text menu_title) "
        echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
        echo -e "  ${GREEN}1${NC} - $(py_text menu_option1)"
        echo -e "  ${GREEN}2${NC} - $(py_text menu_option2)"
        echo -e "  ${GREEN}3${NC} - $(py_text menu_option3)"
        echo -e "  ${GREEN}4${NC} - $(py_text menu_option4)"
        echo -e "  ${GREEN}A${NC} - $(py_text menu_option_all)"
        echo -e "  ${RED}0${NC} - $(py_text menu_option0)"
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(py_text menu_hint)"
        echo
        read -r -p "${YELLOW}$(py_text menu_prompt):${NC} " raw_choice </dev/tty

        if [ -z "$(echo "$raw_choice" | tr -d '[:space:]')" ]; then
            echo -e "${YELLOW}${WARN_TAG}${NC} $(py_text menu_none)"
            sleep 1
            continue
        fi

        local choice_upper
        choice_upper=$(echo "$raw_choice" | tr '[:lower:]' '[:upper:]')

        if [[ "$choice_upper" == "0" ]]; then
            echo -e "${YELLOW}${INFO_TAG}${NC} $(py_text menu_returning)"
            break
        fi

        if [[ "$choice_upper" == "A" ]]; then
            install_python_stack
            break
        fi

        local action_performed=false
        IFS=',' read -ra selections <<< "$choice_upper"
        for selection in "${selections[@]}"; do
            selection=$(echo "$selection" | tr -d '[:space:]')
            [ -z "$selection" ] && continue
            case "$selection" in
                1)
                    install_python
                    action_performed=true
                    ;;
                2)
                    install_pip
                    action_performed=true
                    ;;
                3)
                    install_pipx
                    action_performed=true
                    ;;
                4)
                    install_uv
                    action_performed=true
                    ;;
                *)
                    echo -e "${YELLOW}${WARN_TAG}${NC} $(py_text menu_invalid): ${selection}"
                    ;;
            esac
        done

        if [ "$action_performed" = false ]; then
            echo -e "${YELLOW}${WARN_TAG}${NC} $(py_text menu_none)"
        fi

        echo -e "\n${YELLOW}$(py_text menu_continue)${NC}"
        read -r continue_choice </dev/tty
        if [[ "$(echo "$continue_choice" | tr -d '[:space:]')" == "0" ]]; then
            break
        fi
    done
}

install_python_stack() {
    install_python
    install_pip
    install_pipx
    install_uv
    reload_shell_configs
    echo -e "${GREEN}${SUCCESS_TAG}${NC} $(py_text stack_success)"
}

# Ana kurulum akışı
main() {
    detect_package_manager
    if [[ "${1:-}" =~ ^(all|ALL|a)$ ]]; then
        install_python_stack
        return
    fi
    run_python_tools_menu
}

main "$@"
