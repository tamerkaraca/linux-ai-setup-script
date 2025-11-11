#!/bin/bash
set -euo pipefail

# Ortak yardımcı fonksiyonları yükle
UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"

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

    echo -e "${YELLOW}[BİLGİ]${NC} Paket yöneticisi ile pip kurulumu deneniyor (${PKG_MANAGER})."
    if eval "$INSTALL_CMD" "$pkg_name"; then
        return 0
    fi
    return 1
}

# Pip kurulumu/güncelleme
install_pip() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Pip kurulumu/güncelleme başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    if ! command -v python3 &> /dev/null; then
        echo -e "${YELLOW}[UYARI]${NC} Python kurulu değil, önce Python kuruluyor..."
        install_python
    fi
    
    local pip_bootstrap_success=false

    if ! python3 -m pip --version &> /dev/null; then
        echo -e "${YELLOW}[UYARI]${NC} Pip modülü bulunamadı, python3 -m ensurepip ile kuruluyor..."
        if python3 -m ensurepip --upgrade >/dev/null 2>&1; then
            echo -e "${GREEN}[BİLGİ]${NC} Pip, ensurepip ile kuruldu."
            pip_bootstrap_success=true
        else
            echo -e "${YELLOW}[UYARI]${NC} ensurepip başarısız oldu, paket yöneticisi ile kurulumu deneniyor..."
            if install_pip_via_package_manager && python3 -m pip --version &> /dev/null; then
                echo -e "${GREEN}[BİLGİ]${NC} Pip, paket yöneticisi ile kuruldu."
                pip_bootstrap_success=true
            else
                echo -e "${YELLOW}[UYARI]${NC} Paket yöneticisi ile kurulum başarısız oldu, get-pip.py ile deneniyor..."
                local get_pip_script
                get_pip_script=$(mktemp)
                if ! curl -fsSL https://bootstrap.pypa.io/get-pip.py -o "$get_pip_script"; then
                    echo -e "${RED}[HATA]${NC} get-pip.py indirilemedi; Pip kurulamadı."
                    rm -f "$get_pip_script"
                    return 1
                fi
                if python3 "$get_pip_script" --break-system-packages >/dev/null 2>&1; then
                    echo -e "${GREEN}[BİLGİ]${NC} Pip, get-pip.py ile kuruldu."
                    pip_bootstrap_success=true
                else
                    echo -e "${RED}[HATA]${NC} get-pip.py ile kurulum başarısız oldu."
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
        echo -e "${RED}[HATA]${NC} Pip kurulumu tamamlanamadı."
        return 1
    fi
    
    echo -e "${YELLOW}[BİLGİ]${NC} Pip güncelleniyor..."
    
    local upgrade_output=""
    local upgrade_status=0
    upgrade_output=$(python3 -m pip install --upgrade pip 2>&1) || upgrade_status=$?
    
    if [ $upgrade_status -ne 0 ]; then
        if echo "$upgrade_output" | grep -q "externally-managed-environment"; then
            echo -e "${YELLOW}[BİLGİ]${NC} Externally-managed-environment hatası, --break-system-packages ile yeniden deneniyor..."
            python3 -m pip install --upgrade pip --break-system-packages
        else
            echo -e "${RED}[HATA]${NC} Pip güncellemesi başarısız!"
            echo "$upgrade_output"
            return 1
        fi
    else
        # Başarılı çıktıyı da kullanıcıya göster
        [ -n "$upgrade_output" ] && echo "$upgrade_output"
    fi
    
    echo -e "${GREEN}[BAŞARILI]${NC} Pip sürümü: $(python3 -m pip --version)"
    echo -e "\n${CYAN}[BİLGİ]${NC} Pip Kullanım İpuçları:"
    echo -e "  ${GREEN}•${NC} Paket kurma: ${GREEN}pip install paket_adi${NC}"
    echo -e "  ${GREEN}•${NC} Sanal ortamda kurma (önerilen): ${GREEN}python3 -m venv myenv && source myenv/bin/activate${NC}"
    echo -e "  ${GREEN}•${NC} Sistem geneli kurma: ${GREEN}pip install --break-system-packages paket_adi${NC}"
    echo -e "  ${YELLOW}•${NC} Not: Modern sistemlerde sanal ortam kullanımı önerilir (PEP 668)"
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
        echo -e "${GREEN}[BAŞARILI]${NC} Pipx kurulumu tamamlandı: $(pipx --version 2>/dev/null || echo 'kuruldu')"
        echo -e "\n${CYAN}[BİLGİ]${NC} Pipx Kullanım İpuçları:"
        echo -e "  ${GREEN}•${NC} Paket kurma: ${GREEN}pipx install paket_adi${NC}"
        echo -e "  ${GREEN}•${NC} Paket listesi: ${GREEN}pipx list${NC}"
        echo -e "  ${GREEN}•${NC} Paket kaldırma: ${GREEN}pipx uninstall paket_adi${NC}"
        echo -e "  ${GREEN}•${NC} Tüm paketleri güncelle: ${GREEN}pipx upgrade-all${NC}"
    else
        echo -e "${RED}[HATA]${NC} Pipx kurulumu başarısız!"
        echo -e "${YELLOW}[BİLGİ]${NC} Manuel kurulum için: sudo apt install pipx"
        return 1
    fi
}

# UV kurulumu
install_uv() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} UV (Ultra-fast Python package installer) kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    echo -e "${YELLOW}[BİLGİ]${NC} UV kuruluyor..."
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
        echo -e "${GREEN}[BAŞARILI]${NC} UV kurulumu tamamlandı: $(uv --version)"
        echo -e "\n${CYAN}[BİLGİ]${NC} UV Kullanım İpuçları:"
        echo -e "  ${GREEN}•${NC} Paket kurma: ${GREEN}uv pip install paket_adi${NC}"
        echo -e "  ${GREEN}•${NC} Sanal ortam oluşturma: ${GREEN}uv venv${NC}"
    else
        echo -e "${RED}[HATA]${NC} UV kurulumu başarısız!"
        return 1
    fi
}

run_python_tools_menu() {
    while true; do
        clear
        echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║          Python Araçları Kurulum Menüsü        ║${NC}"
        echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
        echo -e "  ${GREEN}1${NC} - Python 3 Kur"
        echo -e "  ${GREEN}2${NC} - Pip Kur / Güncelle"
        echo -e "  ${GREEN}3${NC} - Pipx Kur"
        echo -e "  ${GREEN}4${NC} - UV Kur"
        echo -e "  ${GREEN}A${NC} - Hepsini Kur"
        echo -e "  ${RED}0${NC} - Ana Menü"
        echo -e "\n${YELLOW}[BİLGİ]${NC} Birden fazla seçim için virgülle ayırabilirsiniz (örn: 1,3)."
        echo
        read -r -p "${YELLOW}Seçiminiz:${NC} " raw_choice </dev/tty

        if [ -z "$(echo "$raw_choice" | tr -d '[:space:]')" ]; then
            echo -e "${YELLOW}[UYARI]${NC} Bir seçim yapmadınız, lütfen tekrar deneyin."
            sleep 1
            continue
        fi

        local choice_upper
        choice_upper=$(echo "$raw_choice" | tr '[:lower:]' '[:upper:]')

        if [[ "$choice_upper" == "0" ]]; then
            echo -e "${YELLOW}[BİLGİ]${NC} Ana menüye dönülüyor..."
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
                    echo -e "${YELLOW}[UYARI]${NC} Geçersiz seçim: ${selection}"
                    ;;
            esac
        done

        if [ "$action_performed" = false ]; then
            echo -e "${YELLOW}[UYARI]${NC} Geçerli bir seçim yapılmadı."
        fi

        echo -e "\n${YELLOW}Başka bir işlem yapmak ister misiniz? Devam için Enter'a basın, çıkmak için 0 yazın.${NC}"
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
    echo -e "${GREEN}[BAŞARILI]${NC} Python ve ilgili araçların tamamı kuruldu!"
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
