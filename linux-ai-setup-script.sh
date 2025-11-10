#!/bin/bash

# Windows CRLF düzeltme kontrolü
if [ -f "$0" ]; then
    if file "$0" | grep -q "CRLF"; then
        echo "Windows satır sonu karakterleri tespit edildi, düzeltiliyor..."
        
        if command -v dos2unix &> /dev/null; then
            dos2unix "$0"
        elif command -v sed &> /dev/null; then
            sed -i 's/\r$//' "$0"
        elif command -v tr &> /dev/null; then
            tr -d '\r' < "$0" > "$0.tmp" && mv "$0.tmp" "$0"
        fi
        
        chmod +x "$0"
        
        echo "Düzeltme tamamlandı, script yeniden başlatılıyor..."
        exec bash "$0" "$@"
    fi
fi

# Renkli çıktı için tanımlamalar
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# PHP sürüm listeleri
PHP_SUPPORTED_VERSIONS=("7.4" "8.1" "8.2" "8.3" "8.4" "8.5")
PHP_EXTENSION_PACKAGES=("mbstring" "zip" "gd" "tokenizer" "curl" "xml" "bcmath" "intl" "sqlite3" "pgsql" "mysql" "fpm")

# Başlık
clear
echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   AI CLI Araçları Otomatik Kurulum Script    ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}\n"

# İşletim sistemi ve paket yöneticisi tespiti
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

# Sistem güncelleme ve temel paketler
update_system() {
    echo -e "\n${YELLOW}[BİLGİ]${NC} Sistem güncelleniyor..."
    eval $UPDATE_CMD
    
    echo -e "${YELLOW}[BİLGİ]${NC} Temel paketler, sıkıştırma ve geliştirme araçları kuruluyor..."
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} Kuruluyor: curl, wget, git, jq, zip, unzip, p7zip-full"
        eval $INSTALL_CMD curl wget git jq zip unzip p7zip-full
        echo -e "${YELLOW}[BİLGİ]${NC} Geliştirme araçları (build-essential) kuruluyor..."
        eval $INSTALL_CMD build-essential
        
    elif [ "$PKG_MANAGER" = "dnf" ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} Kuruluyor: curl, wget, git, jq, zip, unzip, p7zip"
        eval $INSTALL_CMD curl wget git jq zip unzip p7zip
        echo -e "${YELLOW}[BİLGİ]${NC} Geliştirme araçları (Development Tools) kuruluyor..."
        sudo dnf groupinstall "Development Tools" -y
        
    elif [ "$PKG_MANAGER" = "pacman" ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} Kuruluyor: curl, wget, git, jq, zip, unzip, p7zip"
        eval $INSTALL_CMD curl wget git jq zip unzip p7zip
        echo -e "${YELLOW}[BİLGİ]${NC} Geliştirme araçları (base-devel) kuruluyor..."
        sudo pacman -S base-devel --noconfirm
        
    elif [ "$PKG_MANAGER" = "yum" ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} Kuruluyor: curl, wget, git, jq, zip, unzip, p7zip"
        eval $INSTALL_CMD curl wget git jq zip unzip p7zip
        echo -e "${YELLOW}[BİLGİ]${NC} Geliştirme araçları (Development Tools) kuruluyor..."
        sudo yum groupinstall "Development Tools" -y
    fi
    
    echo -e "${GREEN}[BAŞARILI]${NC} Sistem güncelleme ve temel paket kurulumu tamamlandı!"
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
    eval $INSTALL_CMD python3 python3-pip python3-venv
    
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
    fi
    
    echo -e "${YELLOW}[BİLGİ]${NC} Pip güncelleniyor..."
    
    if python3 -m pip install --upgrade pip 2>&1 | grep -q "externally-managed-environment"; then
        echo -e "${YELLOW}[BİLGİ]${NC} Externally-managed-environment hatası, --break-system-packages ile deneniyor..."
        python3 -m pip install --upgrade pip --break-system-packages
    else
        python3 -m pip install --upgrade pip
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
        eval $INSTALL_CMD pipx
    elif [ "$PKG_MANAGER" = "dnf" ]; then
        eval $INSTALL_CMD pipx
    elif [ "$PKG_MANAGER" = "pacman" ]; then
        eval $INSTALL_CMD python-pipx
    elif [ "$PKG_MANAGER" = "yum" ]; then
        eval $INSTALL_CMD pipx
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
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc_file"
            fi
        fi
    done
    
    source "$HOME/.bashrc" 2>/dev/null || source "$HOME/.zshrc" 2>/dev/null || true
    
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
                echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$rc_file"
            fi
        fi
    done
    
    source "$HOME/.cargo/env" 2>/dev/null || true
    
    if command -v uv &> /dev/null; then
        echo -e "${GREEN}[BAŞARILI]${NC} UV kurulumu tamamlandı: $(uv --version)"
        echo -e "\n${CYAN}[BİLGİ]${NC} UV Kullanım İpuçları:"
        echo -e "  ${GREEN}•${NC} Paket kurma: ${GREEN}uv pip install paket_adi${NC}"
        echo -e "  ${GREEN}•${NC} Sanal ortam oluşturma: ${GREEN}uv venv${NC}"
        echo -e "  ${GREEN}•${NC} Python kurma: ${GREEN}uv python install 3.12${NC}"
    else
        echo -e "${RED}[HATA]${NC} UV kurulumu başarısız!"
        return 1
    fi
}

# NVM kurulumu
install_nvm() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} NVM kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
        if [ -f "$rc_file" ]; then
            if ! grep -q 'NVM_DIR' "$rc_file"; then
                echo -e "${YELLOW}[BİLGİ]${NC} NVM $rc_file dosyasına ekleniyor..."
                echo '' >> "$rc_file"
                echo 'export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"' >> "$rc_file"
                echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$rc_file"
            fi
        fi
    done
    
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    echo -e "${YELLOW}[BİLGİ]${NC} Node.js LTS sürümü kuruluyor..."
    nvm install --lts
    nvm use --lts
    
    echo -e "\n${GREEN}[BAŞARILI]${NC} Node.js sürümü: $(node -v)"
    echo -e "${GREEN}[BAŞARILI]${NC} NPM sürümü: $(npm -v)"
}

# Bun.js kurulumu
install_bun() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Bun.js kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    echo -e "${YELLOW}[BİLGİ]${NC} Bun.js (curl) ile kuruluyor..."
    curl -fsSL https://bun.sh/install | bash
    
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
    
    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
        if [ -f "$rc_file" ]; then
            if ! grep -q '.bun/bin' "$rc_file"; then
                echo '' >> "$rc_file"
                echo '# Bun.js PATH' >> "$rc_file"
                echo 'export BUN_INSTALL="$HOME/.bun"' >> "$rc_file"
                echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> "$rc_file"
            fi
        fi
    done
    
    source "$HOME/.bashrc" 2>/dev/null || source "$HOME/.zshrc" 2>/dev/null || true

    if command -v bun &> /dev/null; then
        echo -e "${GREEN}[BAŞARILI]${NC} Bun.js kurulumu tamamlandı: $(bun --version)"
        echo -e "\n${CYAN}[BİLGİ]${NC} Bun.js Kullanım İpuçları:"
        echo -e "  ${GREEN}•${NC} Proje başlatma: ${GREEN}bun init${NC}"
        echo -e "  ${GREEN}•${NC} Paket kurma: ${GREEN}bun add paket_adi${NC}"
        echo -e "  ${GREEN}•${NC} Script çalıştırma: ${GREEN}bun run start${NC}"
        echo -e "  ${GREEN}•${NC} Güncelleme: ${GREEN}bun upgrade${NC}"
    else
        echo -e "${RED}[HATA]${NC} Bun.js kurulumu başarısız!"
        return 1
    fi
}

# SuperGemini Framework kurulumu (Pipx ile)
install_supergemini() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} SuperGemini Framework (Pipx) kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    if ! command -v pipx &> /dev/null; then
        echo -e "${YELLOW}[UYARI]${NC} SuperGemini için önce Pipx kuruluyor..."
        install_pipx
        if ! command -v pipx &> /dev/null; then
            echo -e "${RED}[HATA]${NC} Pipx kurulumu başarısız, SuperGemini kurulamaz."
            return 1
        fi
    fi
    
    source "$HOME/.bashrc" 2>/dev/null || source "$HOME/.zshrc" 2>/dev/null || true
    export PATH="$HOME/.local/bin:$PATH"

    echo -e "${YELLOW}[BİLGİ]${NC} SuperGemini indiriliyor ve kuruluyor (pipx)..."
    pipx install SuperGemini
    
    export PATH="$HOME/.local/bin:$PATH"
    
    if ! command -v SuperGemini &> /dev/null; then
        echo -e "${RED}[HATA]${NC} SuperGemini (pipx) kurulumu başarısız!"
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen terminali yeniden başlatıp tekrar deneyin."
        return 1
    fi
    
    echo -e "${GREEN}[BAŞARILI]${NC} SuperGemini (pipx) kurulumu tamamlandı."

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}   SuperGemini Yapılandırma Profili Seçin:${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "  ${GREEN}1${NC} - Express (Önerilen, hızlı kurulum)"
    echo -e "  ${GREEN}2${NC} - Minimal (Sadece çekirdek, en hızlı)"
    echo -e "  ${GREEN}3${NC} - Full (Tüm özellikler)"
    read -p "Seçiminiz (1/2/3) [Varsayılan: 1]: " setup_choice
    
    SETUP_CMD=""
    case $setup_choice in
        2)
            echo -e "${YELLOW}[BİLGİ]${NC} Minimal profil ile kurulum yapılıyor..."
            SETUP_CMD="SuperGemini install --profile minimal --yes"
            ;;
        3)
            echo -e "${YELLOW}[BİLGİ]${NC} Full profil ile kurulum yapılıyor..."
            SETUP_CMD="SuperGemini install --profile full --yes"
            ;;
        *)
            echo -e "${YELLOW}[BİLGİ]${NC} Express (önerilen) profil ile kurulum yapılıyor..."
            SETUP_CMD="SuperGemini install --yes"
            ;;
    esac
    
    echo -e "${YELLOW}[BİLGİ]${NC} $SETUP_CMD komutu çalıştırılıyor..."
    echo -e "${YELLOW}[BİLGİ]${NC} Bu aşamada API anahtarlarınız istenebilir. Lütfen ekranı takip edin.${NC}"
    
    if [ "$setup_choice" = "2" ]; then
        SuperGemini install --profile minimal --yes
    elif [ "$setup_choice" = "3" ]; then
        SuperGemini install --profile full --yes
    else
        SuperGemini install --yes
    fi
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}[HATA]${NC} SuperGemini 'install' komutu başarısız!"
        echo -e "${YELLOW}[BİLGİ]${NC} Gerekli API anahtarlarını daha sonra manuel olarak '${GREEN}SuperGemini install${NC}' komutuyla yapılandırabilirsiniz."
    else
        echo -e "${GREEN}[BAŞARILI]${NC} SuperGemini yapılandırması tamamlandı!"
    fi

    echo -e "\n${CYAN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}   SuperGemini Framework Kullanım İpuçları:${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "  ${GREEN}•${NC} Başlatma: ${GREEN}SuperGemini${NC} (veya ${GREEN}sg${NC})"
    echo -e "  ${GREEN}•${NC} Güncelleme: ${GREEN}pipx upgrade SuperGemini${NC}"
    echo -e "  ${GREEN}•${NC} Kaldırma: ${GREEN}pipx uninstall SuperGemini${NC}"
    echo -e "  ${GREEN}•${NC} Yeniden yapılandırma: ${GREEN}SuperGemini install${NC}"
    echo -e "  ${GREEN}•${NC} Daha fazla bilgi: https://github.com/SuperClaude-Org/SuperGemini"
    
    echo -e "\n${YELLOW}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}   API Anahtarı Alma Rehberi:${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}1.${NC} Gemini API Key: ${CYAN}https://makersuite.google.com/app/apikey${NC}"
    echo -e "${GREEN}2.${NC} Anthropic API Key: ${CYAN}https://console.anthropic.com/${NC}"
    echo -e "${GREEN}3.${NC} OpenAI API Key: ${CYAN}https://platform.openai.com/api-keys${NC}"
    echo -e "\n${YELLOW}[BİLGİ]${NC} 'SuperGemini install' komutu sizden bu anahtarları isteyecektir."
}

# SuperQwen Framework kurulumu (Pipx ile)
install_superqwen() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} SuperQwen Framework (Pipx) kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    if ! command -v pipx &> /dev/null; then
        echo -e "${YELLOW}[UYARI]${NC} SuperQwen için önce Pipx kuruluyor..."
        install_pipx
        if ! command -v pipx &> /dev/null; then
            echo -e "${RED}[HATA]${NC} Pipx kurulumu başarısız, SuperQwen kurulamaz."
            return 1
        fi
    fi
    
    source "$HOME/.bashrc" 2>/dev/null || source "$HOME/.zshrc" 2>/dev/null || true
    export PATH="$HOME/.local/bin:$PATH"

    echo -e "${YELLOW}[BİLGİ]${NC} SuperQwen indiriliyor ve kuruluyor (pipx)..."
    pipx install SuperQwen
    
    export PATH="$HOME/.local/bin:$PATH"
    
    if ! command -v SuperQwen &> /dev/null; then
        echo -e "${RED}[HATA]${NC} SuperQwen (pipx) kurulumu başarısız!"
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen terminali yeniden başlatıp tekrar deneyin."
        return 1
    fi
    
    echo -e "${GREEN}[BAŞARILI]${NC} SuperQwen (pipx) kurulumu tamamlandı."

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}   SuperQwen Yapılandırması Başlatılıyor...${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    echo -e "${YELLOW}[BİLGİ]${NC} SuperQwen install komutu çalıştırılıyor..."
    echo -e "${YELLOW}[BİLGİ]${NC} Bu aşamada API anahtarlarınız istenebilir. Lütfen ekranı takip edin.${NC}"

    SuperQwen install
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}[HATA]${NC} SuperQwen 'install' komutu başarısız!"
        echo -e "${YELLOW}[BİLGİ]${NC} Gerekli API anahtarlarını daha sonra manuel olarak '${GREEN}SuperQwen install${NC}' komutuyla yapılandırabilirsiniz."
    else
        echo -e "${GREEN}[BAŞARILI]${NC} SuperQwen yapılandırması tamamlandı!"
    fi

    echo -e "\n${CYAN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}   SuperQwen Framework Kullanım İpuçları:${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "  ${GREEN}•${NC} Başlatma: ${GREEN}SuperQwen${NC} (veya ${GREEN}sq${NC})"
    echo -e "  ${GREEN}•${NC} Güncelleme: ${GREEN}pipx upgrade SuperQwen${NC}"
    echo -e "  ${GREEN}•${NC} Kaldırma: ${GREEN}pipx uninstall SuperQwen${NC}"
    echo -e "  ${GREEN}•${NC} Yeniden yapılandırma: ${GREEN}SuperQwen install${NC}"
    echo -e "  ${GREEN}•${NC} Daha fazla bilgi: https://github.com/SuperClaude-Org/SuperQwen_Framework"
}

# SuperClaude Framework kurulumu (Pipx ile)
install_superclaude() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} SuperClaude Framework (Pipx) kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    if ! command -v pipx &> /dev/null; then
        echo -e "${YELLOW}[UYARI]${NC} SuperClaude için önce Pipx kuruluyor..."
        install_pipx
        if ! command -v pipx &> /dev/null; then
            echo -e "${RED}[HATA]${NC} Pipx kurulumu başarısız, SuperClaude kurulamaz."
            return 1
        fi
    fi
    
    source "$HOME/.bashrc" 2>/dev/null || source "$HOME/.zshrc" 2>/dev/null || true
    export PATH="$HOME/.local/bin:$PATH"

    echo -e "${YELLOW}[BİLGİ]${NC} SuperClaude indiriliyor ve kuruluyor (pipx)..."
    pipx install SuperClaude
    
    export PATH="$HOME/.local/bin:$PATH"
    
    if ! command -v SuperClaude &> /dev/null; then
        echo -e "${RED}[HATA]${NC} SuperClaude (pipx) kurulumu başarısız!"
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen terminali yeniden başlatıp tekrar deneyin."
        return 1
    fi
    
    echo -e "${GREEN}[BAŞARILI]${NC} SuperClaude (pipx) kurulumu tamamlandı."

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}   SuperClaude Yapılandırması Başlatılıyor...${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    echo -e "${YELLOW}[BİLGİ]${NC} SuperClaude install komutu çalıştırılıyor..."
    echo -e "${YELLOW}[BİLGİ]${NC} Bu aşamada API anahtarlarınız istenebilir. Lütfen ekranı takip edin.${NC}"

    SuperClaude install
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}[HATA]${NC} SuperClaude 'install' komutu başarısız!"
        echo -e "${YELLOW}[BİLGİ]${NC} Gerekli API anahtarlarını daha sonra manuel olarak '${GREEN}SuperClaude install${NC}' komutuyla yapılandırabilirsiniz."
    else
        echo -e "${GREEN}[BAŞARILI]${NC} SuperClaude yapılandırması tamamlandı!"
    fi

    echo -e "\n${CYAN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}   SuperClaude Framework Kullanım İpuçları:${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "  ${GREEN}•${NC} Başlatma: ${GREEN}SuperClaude${NC} (veya ${GREEN}sc${NC})"
    echo -e "  ${GREEN}•${NC} Güncelleme: ${GREEN}pipx upgrade SuperClaude${NC}"
    echo -e "  ${GREEN}•${NC} Kaldırma: ${GREEN}pipx uninstall SuperClaude${NC}"
    echo -e "  ${GREEN}•${NC} Yeniden yapılandırma: ${GREEN}SuperClaude install${NC}"
    echo -e "  ${GREEN}•${NC} Daha fazla bilgi: https://github.com/SuperClaude-Org/SuperClaude_Framework"
}

# Claude Code kurulumu
install_claude_code() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Claude Code kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    npm install -g @anthropic-ai/claude-code
    
    echo -e "${GREEN}[BAŞARILI]${NC} Claude Code sürümü: $(claude --version)"
    
    echo -e "\n${YELLOW}[BİLGİ]${NC} Şimdi Claude Code'a giriş yapmanız gerekiyor."
    echo -e "${YELLOW}[BİLGİ]${NC} Lütfen 'claude login' komutunu çalıştırın ve oturum açın."
    echo -e "${YELLOW}[BİLGİ]${NC} Oturum açma tamamlandığında buraya dönün ve Enter'a basın.\n"
    
    claude login
    
    echo -e "\n${YELLOW}[BİLGİ]${NC} Oturum açma işlemi tamamlandı mı? (Enter'a basarak devam edin)"
    read -p "Devam etmek için Enter'a basın..."
    
    echo -e "${GREEN}[BAŞARILI]${NC} Claude Code kurulumu tamamlandı!"
}

# Gemini CLI kurulumu
install_gemini_cli() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Gemini CLI kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    npm install -g @google/gemini-cli
    
    echo -e "${GREEN}[BAŞARILI]${NC} Gemini CLI sürümü: $(gemini --version)"
    
    echo -e "\n${YELLOW}[BİLGİ]${NC} Şimdi Gemini CLI'ya giriş yapmanız gerekiyor."
    echo -e "${YELLOW}[BİLGİ]${NC} Lütfen 'gemini auth' veya ilgili oturum açma komutunu çalıştırın."
    echo -e "${YELLOW}[BİLGİ]${NC} Oturum açma tamamlandığında buraya dönün ve Enter'a basın.\n"
    
    gemini auth 2>/dev/null || echo -e "${YELLOW}[BİLGİ]${NC} Manuel oturum açma gerekebilir."
    
    echo -e "\n${YELLOW}[BİLGİ]${NC} Oturum açma işlemi tamamlandı mı? (Enter'a basarak devam edin)"
    read -p "Devam etmek için Enter'a basın..."
    
    echo -e "${GREEN}[BAŞARILI]${NC} Gemini CLI kurulumu tamamlandı!"
}

# OpenCode CLI kurulumu
install_opencode_cli() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} OpenCode CLI kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    npm i -g opencode-ai
    
    echo -e "${GREEN}[BAŞARILI]${NC} OpenCode CLI sürümü: $(opencode --version)"
    
    echo -e "\n${YELLOW}[BİLGİ]${NC} Şimdi OpenCode CLI'ya giriş yapmanız gerekiyor."
    echo -e "${YELLOW}[BİLGİ]${NC} Lütfen 'opencode login' veya ilgili oturum açma komutunu çalıştırın."
    echo -e "${YELLOW}[BİLGİ]${NC} Oturum açma tamamlandığında buraya dönün ve Enter'a basın.\n"
    
    opencode login 2>/dev/null || echo -e "${YELLOW}[BİLGİ]${NC} Manuel oturum açma gerekebilir."
    
    echo -e "\n${YELLOW}[BİLGİ]${NC} Oturum açma işlemi tamamlandı mı? (Enter'a basarak devam edin)"
    read -p "Devam etmek için Enter'a basın..."
    
    echo -e "${GREEN}[BAŞARILI]${NC} OpenCode CLI kurulumu tamamlandı!"
}

# Qoder CLI kurulumu
install_qoder_cli() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Qoder CLI kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    npm install -g @qoder-ai/qodercli
    
    echo -e "${GREEN}[BAŞARILI]${NC} Qoder CLI sürümü: $(qodercli --version)"
    
    echo -e "\n${YELLOW}[BİLGİ]${NC} Şimdi Qoder CLI'ya giriş yapmanız gerekiyor."
    echo -e "${YELLOW}[BİLGİ]${NC} Lütfen 'qodercli login' veya ilgili oturum açma komutunu çalıştırın."
    echo -e "${YELLOW}[BİLGİ]${NC} Oturum açma tamamlandığında buraya dönün ve Enter'a basın.\n"
    
    qodercli login 2>/dev/null || echo -e "${YELLOW}[BİLGİ]${NC} Manuel oturum açma gerekebilir."
    
    echo -e "\n${YELLOW}[BİLGİ]${NC} Oturum açma işlemi tamamlandı mı? (Enter'a basarak devam edin)"
    read -p "Devam etmek için Enter'a basın..."
    
    echo -e "${GREEN}[BAŞARILI]${NC} Qoder CLI kurulumu tamamlandı!"
}

# Qwen CLI kurulumu
install_qwen_cli() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Qwen CLI kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    npm install -g @qwen-code/qwen-code@latest
    
    echo -e "${GREEN}[BAŞARILI]${NC} Qwen CLI sürümü: $(qwen --version)"
    
    echo -e "\n${YELLOW}[BİLGİ]${NC} Şimdi Qwen CLI'ya giriş yapmanız gerekiyor."
    echo -e "${YELLOW}[BİLGİ]${NC} Lütfen 'qwen login' veya ilgili oturum açma komutunu çalıştırın."
    echo -e "${YELLOW}[BİLGİ]${NC} Oturum açma tamamlandığında buraya dönün ve Enter'a basın.\n"
    
    qwen login 2>/dev/null || echo -e "${YELLOW}[BİLGİ]${NC} Manuel oturum açma gerekebilir."
    
    echo -e "\n${YELLOW}[BİLGİ]${NC} Oturum açma işlemi tamamlandı mı? (Enter'a basarak devam edin)"
    read -p "Devam etmek için Enter'a basın..."
    
    echo -e "${GREEN}[BAŞARILI]${NC} Qwen CLI kurulumu tamamlandı!"
}

# OpenAI Codex CLI kurulumu
install_codex_cli() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} OpenAI Codex CLI kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    npm install -g @openai/codex
    
    echo -e "${GREEN}[BAŞARILI]${NC} Codex CLI sürümü: $(codex --version)"
    
    echo -e "\n${YELLOW}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}   Codex CLI Kimlik Doğrulama Seçenekleri:${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}Seçenek 1:${NC} ChatGPT hesabı ile giriş (Önerilen)"
    echo -e "  • ChatGPT Plus, Pro, Business, Edu veya Enterprise planı gereklidir"
    echo -e "  • Kullanım kredileri dahildir"
    echo -e "  • Komut: ${GREEN}codex${NC} çalıştırın ve 'Sign in with ChatGPT' seçeneğini seçin"
    echo -e "\n${GREEN}Seçenek 2:${NC} OpenAI API Key ile giriş"
    echo -e "  • https://platform.openai.com/api-keys adresinden API key alın"
    echo -e "  • Environment variable olarak ayarlayın: ${GREEN}export OPENAI_API_KEY=\"your-key\"${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}\n"
    
    echo -e "${YELLOW}[BİLGİ]${NC} Hangi yöntemi kullanmak istersiniz?"
    echo -e "  ${GREEN}1${NC} - ChatGPT hesabı ile giriş (Önerilen)"
    echo -e "  ${GREEN}2${NC} - OpenAI API Key ile giriş"
    echo -e "  ${GREEN}3${NC} - Manuel olarak daha sonra yapacağım"
    read -p "Seçiminiz (1/2/3): " auth_choice
    
    case $auth_choice in
        1)
            echo -e "\n${YELLOW}[BİLGİ]${NC} Codex başlatılıyor, ChatGPT ile giriş yapın..."
            echo -e "${YELLOW}[BİLGİ]${NC} Tarayıcıda açılan sayfadan giriş yapın."
            echo -e "${YELLOW}[BİLGİ]${NC} Giriş tamamlandıktan sonra buraya dönün.\n"
            codex --auth-only 2>/dev/null || codex
            ;;
        2)
            echo -e "\n${YELLOW}[BİLGİ]${NC} OpenAI API Key girişi"
            read -p "OpenAI API Key'inizi girin: " OPENAI_KEY
            
            if [ -n "$OPENAI_KEY" ]; then
                for rc_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
                    if [ -f "$rc_file" ]; then
                        if ! grep -q 'OPENAI_API_KEY' "$rc_file"; then
                            echo '' >> "$rc_file"
                            echo "export OPENAI_API_KEY=\"$OPENAI_KEY\"" >> "$rc_file"
                            echo -e "${GREEN}[BAŞARILI]${NC} API Key $rc_file dosyasına eklendi"
                        fi
                    fi
                done
                
                export OPENAI_API_KEY="$OPENAI_KEY"
                echo -e "${GREEN}[BAŞARILI]${NC} API Key ayarlandı"
            else
                echo -e "${RED}[HATA]${NC} API Key boş olamaz!"
            fi
            ;;
        3)
            echo -e "${YELLOW}[BİLGİ]${NC} Kimlik doğrulama atlandı. Daha sonra yapabilirsiniz."
            ;;
        *)
            echo -e "${RED}[HATA]${NC} Geçersiz seçim!"
            ;;
    esac
    
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Codex CLI Kullanım İpuçları:"
    echo -e "  ${GREEN}•${NC} Başlatmak için: ${GREEN}codex${NC}"
    echo -e "  ${GREEN}•${NC} Suggest modu: ${GREEN}codex --suggest${NC}"
    echo -e "  ${GREEN}•${NC} Auto Edit modu: ${GREEN}codex --auto-edit${NC}"
    echo -e "  ${GREEN}•${NC} Full Auto modu: ${GREEN}codex --full-auto${NC}"
    echo -e "  ${GREEN}•${NC} Model değiştirme: ${GREEN}codex -m o3${NC}"
    echo -e "  ${GREEN}•${NC} Güncelleme: ${GREEN}codex --upgrade${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${GREEN}[BAŞARILI]${NC} OpenAI Codex CLI kurulumu tamamlandı!"
}

# Git yapılandırması
configure_git() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Git Global Yapılandırması Başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if ! command -v git &> /dev/null; then
        echo -e "${RED}[HATA]${NC} 'git' komutu bulunamadı. Lütfen önce sistem güncellemesini çalıştırın."
        return 1
    fi

    echo -e "${YELLOW}[BİLGİ]${NC} Lütfen global .gitconfig için bilgilerinizi girin."
    echo -e "${CYAN}Not: Bu bilgiler commit atarken kullanılacaktır. (Boş bırakmak için Enter'a basın)${NC}"

    read -p "Git Kullanıcı Adınız (örn: Tamer KARACA): " GIT_USER_NAME
    read -p "Git E-posta Adresiniz (örn: tamer@smedyazilim.com): " GIT_USER_EMAIL

    if [ -n "$GIT_USER_NAME" ]; then
        git config --global user.name "$GIT_USER_NAME"
        echo -e "${GREEN}[BAŞARILI]${NC} Git kullanıcı adı ayarlandı: $GIT_USER_NAME"
    else
        echo -e "${YELLOW}[BİLGİ]${NC} Kullanıcı adı boş bırakıldı, ayarlanmadı."
    fi

    if [ -n "$GIT_USER_EMAIL" ]; then
        git config --global user.email "$GIT_USER_EMAIL"
        echo -e "${GREEN}[BAŞARILI]${NC} Git e-posta adresi ayarlandı: $GIT_USER_EMAIL"
    else
        echo -e "${YELLOW}[BİLGİ]${NC} E-posta adresi boş bırakıldı, ayarlanmadı."
    fi

    echo -e "${GREEN}[BAŞARILI]${NC} Git yapılandırması tamamlandı."
}

# GLM-4.6 Claude Code yapılandırması
configure_glm_claude() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Claude Code için GLM-4.6 yapılandırması başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    CLAUDE_DIR="$HOME/.claude"
    SETTINGS_FILE="$CLAUDE_DIR/settings.json"
    
    if [ ! -d "$CLAUDE_DIR" ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} Claude dizini oluşturuluyor..."
        mkdir -p "$CLAUDE_DIR"
    fi
    
    echo -e "\n${YELLOW}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}   GLM API Key Alma Talimatları:${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}1.${NC} https://z.ai/model-api adresine gidin"
    echo -e "${GREEN}2.${NC} Kayıt olun veya giriş yapın"
    echo -e "${GREEN}3.${NC} https://z.ai/manage-apikey/apikey-list sayfasından API Key oluşturun"
    echo -e "${GREEN}4.${NC} API Key'inizi kopyalayın"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}\n"
    
    read -p "GLM API Key'inizi girin: " GLM_API_KEY
    
    if [ -z "$GLM_API_KEY" ]; then
        echo -e "${RED}[HATA]${NC} API Key boş olamaz!"
        return 1
    fi
    
    echo -e "\n${YELLOW}[BİLGİ]${NC} Base URL (varsayılan: https://api.z.ai/api/anthropic)"
    read -p "Base URL (Enter ile varsayılanı kullan): " GLM_BASE_URL
    
    if [ -z "$GLM_BASE_URL" ]; then
        GLM_BASE_URL="https://api.z.ai/api/anthropic"
    fi
    
    echo -e "${YELLOW}[BİLGİ]${NC} settings.json dosyası oluşturuluyor..."
    
    cat > "$SETTINGS_FILE" << EOF
{
  "env": {
      "ANTHROPIC_AUTH_TOKEN": "${GLM_API_KEY}",
      "ANTHROPIC_BASE_URL": "${GLM_BASE_URL}",
      "API_TIMEOUT_MS": "3000000",
      "ANTHROPIC_DEFAULT_OPUS_MODEL": "GLM-4.6",
      "ANTHROPIC_DEFAULT_SONNET_MODEL": "GLM-4.6",
      "ANTHROPIC_DEFAULT_HAIKU_MODEL": "GLM-4.5-Air"
  }
}
EOF
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[BAŞARILI]${NC} GLM-4.6 yapılandırması tamamlandı!"
        echo -e "\n${YELLOW}[BİLGİ]${NC} Yapılandırma dosyası: $SETTINGS_FILE"
        echo -e "${YELLOW}[BİLGİ]${NC} Model yapılandırması:"
        echo -e "  ${GREEN}•${NC} Opus Model: GLM-4.6"
        echo -e "  ${GREEN}•${NC} Sonnet Model: GLM-4.6"
        echo -e "  ${GREEN}•${NC} Haiku Model: GLM-4.5-Air"
        echo -e "\n${YELLOW}[BİLGİ]${NC} Claude Code'u başlatmak için: ${GREEN}claude${NC}"
        echo -e "${YELLOW}[BİLGİ]${NC} Model durumunu kontrol etmek için: ${GREEN}/status${NC} komutunu kullanın"
    else
        echo -e "${RED}[HATA]${NC} settings.json dosyası oluşturulamadı!"
        return 1
    fi
    
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} GLM Coding Plan hakkında:"
    echo -e "  ${GREEN}•${NC} \$3/aydan başlayan fiyatlarla premium kodlama deneyimi"
    echo -e "  ${GREEN}•${NC} PRO ve üzeri planlarda Vision ve Web Search MCP desteği"
    echo -e "  ${GREEN}•${NC} Daha fazla bilgi: https://z.ai/subscribe"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
}

# SuperGemini MCP Sunucu Temizleme
cleanup_magic_mcp() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} SuperGemini MCP Sunucu Yapılandırması Temizleme..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    SETTINGS_FILE="$HOME/.gemini/settings.json"
    
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}[HATA]${NC} 'jq' komutu bulunamadı. Bu özellik için 'jq' gereklidir."
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen 'jq' paketini kurun (örn: sudo apt install jq)."
        return 1
    fi
    
    if [ ! -f "$SETTINGS_FILE" ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} $SETTINGS_FILE bulunamadı, işlem atlanıyor."
        return 0
    fi

    if ! jq -e '.mcpServers' "$SETTINGS_FILE" > /dev/null; then
        echo -e "${YELLOW}[BİLGİ]${NC} Dosyada 'mcpServers' ayarı bulunmuyor."
        return 0
    fi

    mapfile -t mcp_servers < <(jq -r '.mcpServers | keys[]' "$SETTINGS_FILE")

    if [ ${#mcp_servers[@]} -eq 0 ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} Yapılandırılmış MCP sunucusu bulunamadı."
        return 0
    fi

    echo -e "\n${YELLOW}Kaldırmak istediğiniz MCP sunucu(lar)ını seçin:${NC}"
    local index=1
    for server in "${mcp_servers[@]}"; do
        echo -e "  ${GREEN}${index}${NC} - ${server}"
        index=$((index + 1))
    done
    echo -e "  ${RED}0${NC} - İptal"
    echo -e "${YELLOW}[BİLGİ]${NC} Birden fazla seçim için virgülle ayırın (örn: 1,2,3)"

    read -p "Seçiminiz: " choices
    if [ "$choices" = "0" ] || [ -z "$choices" ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} Temizleme işlemi iptal edildi."
        return 0
    fi

    IFS=',' read -ra SELECTED_INDICES <<< "$choices"
    
    local temp_file
    temp_file=$(mktemp)
    cp "$SETTINGS_FILE" "$temp_file"

    local changes_made=false
    for choice in "${SELECTED_INDICES[@]}"; do
        choice=$(echo "$choice" | tr -d ' ')
        if ! [[ "$choice" =~ ^[1-9][0-9]*$ ]]; then
            echo -e "${RED}[HATA]${NC} Geçersiz seçim: $choice"
            continue
        fi

        local idx=$((choice - 1))
        if [ $idx -lt 0 ] || [ $idx -ge ${#mcp_servers[@]} ]; then
            echo -e "${RED}[HATA]${NC} Desteklenmeyen seçim: $choice"
            continue
        fi

        local server_to_remove="${mcp_servers[$idx]}"
        echo -e "${YELLOW}[BİLGİ]${NC} '${server_to_remove}' MCP sunucusu kaldırılıyor..."
        
        jq "del(.mcpServers.\"$server_to_remove\")" "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[BAŞARILI]${NC} '${server_to_remove}' kaldırıldı."
            changes_made=true
        else
            echo -e "${RED}[HATA]${NC} '${server_to_remove}' kaldırılırken hata oluştu."
        fi
    done

    if [ "$changes_made" = true ]; then
        mv "$temp_file" "$SETTINGS_FILE"
        echo -e "${GREEN}[BAŞARILI]${NC} Değişiklikler $SETTINGS_FILE dosyasına kaydedildi."
    else
        rm -f "$temp_file"
        echo -e "${YELLOW}[BİLGİ]${NC} Hiçbir değişiklik yapılmadı."
    fi
}

# SuperQwen MCP Sunucu Temizleme
cleanup_qwen_mcp() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} SuperQwen MCP Sunucu Yapılandırması Temizleme..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    SETTINGS_FILE="$HOME/.qwen/settings.json"
    
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}[HATA]${NC} 'jq' komutu bulunamadı. Bu özellik için 'jq' gereklidir."
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen 'jq' paketini kurun (örn: sudo apt install jq)."
        return 1
    fi
    
    if [ ! -f "$SETTINGS_FILE" ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} $SETTINGS_FILE bulunamadı, işlem atlanıyor."
        return 0
    fi

    if ! jq -e '.mcpServers' "$SETTINGS_FILE" > /dev/null; then
        echo -e "${YELLOW}[BİLGİ]${NC} Dosyada 'mcpServers' ayarı bulunmuyor."
        return 0
    fi

    mapfile -t mcp_servers < <(jq -r '.mcpServers | keys[]' "$SETTINGS_FILE")

    if [ ${#mcp_servers[@]} -eq 0 ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} Yapılandırılmış MCP sunucusu bulunamadı."
        return 0
    fi

    echo -e "\n${YELLOW}Kaldırmak istediğiniz MCP sunucu(lar)ını seçin:${NC}"
    local index=1
    for server in "${mcp_servers[@]}"; do
        echo -e "  ${GREEN}${index}${NC} - ${server}"
        index=$((index + 1))
    done
    echo -e "  ${RED}0${NC} - İptal"
    echo -e "${YELLOW}[BİLGİ]${NC} Birden fazla seçim için virgülle ayırın (örn: 1,2,3)"

    read -p "Seçiminiz: " choices
    if [ "$choices" = "0" ] || [ -z "$choices" ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} Temizleme işlemi iptal edildi."
        return 0
    fi

    IFS=',' read -ra SELECTED_INDICES <<< "$choices"
    
    local temp_file
    temp_file=$(mktemp)
    cp "$SETTINGS_FILE" "$temp_file"

    local changes_made=false
    for choice in "${SELECTED_INDICES[@]}"; do
        choice=$(echo "$choice" | tr -d ' ')
        if ! [[ "$choice" =~ ^[1-9][0-9]*$ ]]; then
            echo -e "${RED}[HATA]${NC} Geçersiz seçim: $choice"
            continue
        fi

        local idx=$((choice - 1))
        if [ $idx -lt 0 ] || [ $idx -ge ${#mcp_servers[@]} ]; then
            echo -e "${RED}[HATA]${NC} Desteklenmeyen seçim: $choice"
            continue
        fi

        local server_to_remove="${mcp_servers[$idx]}"
        echo -e "${YELLOW}[BİLGİ]${NC} '${server_to_remove}' MCP sunucusu kaldırılıyor..."
        
        jq "del(.mcpServers.\"$server_to_remove\")" "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[BAŞARILI]${NC} '${server_to_remove}' kaldırıldı."
            changes_made=true
        else
            echo -e "${RED}[HATA]${NC} '${server_to_remove}' kaldırılırken hata oluştu."
        fi
    done

    if [ "$changes_made" = true ]; then
        mv "$temp_file" "$SETTINGS_FILE"
        echo -e "${GREEN}[BAŞARILI]${NC} Değişiklikler $SETTINGS_FILE dosyasına kaydedildi."
    else
        rm -f "$temp_file"
        echo -e "${YELLOW}[BİLGİ]${NC} Hiçbir değişiklik yapılmadı."
    fi
}

# SuperClaude MCP Sunucu Temizleme
cleanup_claude_mcp() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} SuperClaude MCP Sunucu Yapılandırması Temizleme..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    SETTINGS_FILE="$HOME/.claude/settings.json"
    
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}[HATA]${NC} 'jq' komutu bulunamadı. Bu özellik için 'jq' gereklidir."
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen 'jq' paketini kurun (örn: sudo apt install jq)."
        return 1
    fi
    
    if [ ! -f "$SETTINGS_FILE" ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} $SETTINGS_FILE bulunamadı, işlem atlanıyor."
        return 0
    fi

    if ! jq -e '.mcpServers' "$SETTINGS_FILE" > /dev/null; then
        echo -e "${YELLOW}[BİLGİ]${NC} Dosyada 'mcpServers' ayarı bulunmuyor."
        return 0
    fi

    mapfile -t mcp_servers < <(jq -r '.mcpServers | keys[]' "$SETTINGS_FILE")

    if [ ${#mcp_servers[@]} -eq 0 ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} Yapılandırılmış MCP sunucusu bulunamadı."
        return 0
    fi

    echo -e "\n${YELLOW}Kaldırmak istediğiniz MCP sunucu(lar)ını seçin:${NC}"
    local index=1
    for server in "${mcp_servers[@]}"; do
        echo -e "  ${GREEN}${index}${NC} - ${server}"
        index=$((index + 1))
    done
    echo -e "  ${RED}0${NC} - İptal"
    echo -e "${YELLOW}[BİLGİ]${NC} Birden fazla seçim için virgülle ayırın (örn: 1,2,3)"

    read -p "Seçiminiz: " choices
    if [ "$choices" = "0" ] || [ -z "$choices" ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} Temizleme işlemi iptal edildi."
        return 0
    fi

    IFS=',' read -ra SELECTED_INDICES <<< "$choices"
    
    local temp_file
    temp_file=$(mktemp)
    cp "$SETTINGS_FILE" "$temp_file"

    local changes_made=false
    for choice in "${SELECTED_INDICES[@]}"; do
        choice=$(echo "$choice" | tr -d ' ')
        if ! [[ "$choice" =~ ^[1-9][0-9]*$ ]]; then
            echo -e "${RED}[HATA]${NC} Geçersiz seçim: $choice"
            continue
        fi

        local idx=$((choice - 1))
        if [ $idx -lt 0 ] || [ $idx -ge ${#mcp_servers[@]} ]; then
            echo -e "${RED}[HATA]${NC} Desteklenmeyen seçim: $choice"
            continue
        fi

        local server_to_remove="${mcp_servers[$idx]}"
        echo -e "${YELLOW}[BİLGİ]${NC} '${server_to_remove}' MCP sunucusu kaldırılıyor..."
        
        jq "del(.mcpServers.\"$server_to_remove\")" "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[BAŞARILI]${NC} '${server_to_remove}' kaldırıldı."
            changes_made=true
        else
            echo -e "${RED}[HATA]${NC} '${server_to_remove}' kaldırılırken hata oluştu."
        fi
    done

    if [ "$changes_made" = true ]; then
        mv "$temp_file" "$SETTINGS_FILE"
        echo -e "${GREEN}[BAŞARILI]${NC} Değişiklikler $SETTINGS_FILE dosyasına kaydedildi."
    else
        rm -f "$temp_file"
        echo -e "${YELLOW}[BİLGİ]${NC} Hiçbir değişiklik yapılmadı."
    fi
}

# PHP deposu ve bağımlılık hazırlığı
ensure_php_repository() {
    if [ "$PKG_MANAGER" = "apt" ]; then
        echo -e "\n${YELLOW}[BİLGİ]${NC} PHP için Ondřej Surý deposu kontrol ediliyor..."
        eval "$INSTALL_CMD software-properties-common ca-certificates apt-transport-https lsb-release gnupg"
        if ! grep -R "ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null | grep -q ondrej; then
            echo -e "${YELLOW}[BİLGİ]${NC} Ondřej Surý PPA ekleniyor..."
            sudo add-apt-repository -y ppa:ondrej/php
        fi
        sudo apt update
    elif [ "$PKG_MANAGER" = "dnf" ] || [ "$PKG_MANAGER" = "yum" ]; then
        if ! rpm -qa | grep -qi remi-release; then
            echo -e "${YELLOW}[BİLGİ]${NC} Remi PHP deposu ekleniyor..."
            if [ -f /etc/os-release ]; then
                # shellcheck disable=SC1091
                . /etc/os-release
            fi
            if [ "${ID:-}" = "fedora" ]; then
                local fedora_ver
                fedora_ver="${VERSION_ID:-}"
                if [ -z "$fedora_ver" ]; then
                    fedora_ver=$(rpm -E %fedora 2>/dev/null || echo "")
                fi
                if [ -n "$fedora_ver" ]; then
                    sudo "$PKG_MANAGER" install -y "https://rpms.remirepo.net/fedora/remi-release-${fedora_ver}.rpm"
                else
                    echo -e "${RED}[HATA]${NC} Fedora sürümü tespit edilemedi."
                    return 1
                fi
            else
                local rhel_version
                rhel_version=$(rpm -E %rhel 2>/dev/null || echo "")
                if [ -n "$rhel_version" ]; then
                    sudo "$PKG_MANAGER" install -y "https://rpms.remirepo.net/enterprise/remi-release-${rhel_version}.rpm"
                else
                    echo -e "${RED}[HATA]${NC} Remi deposu otomatik eklenemedi. Lütfen manuel olarak yapılandırın."
                    return 1
                fi
            fi
        fi
    fi

    return 0
}

# PHP sürümü için binary yolu
resolve_php_binary_path() {
    local version="$1"
    local short_version
    short_version=$(echo "$version" | tr -d '.')
    local candidates=(
        "/usr/bin/php${version}"
        "/usr/bin/php${short_version}"
        "/usr/local/bin/php${version}"
        "/opt/remi/php${short_version}/root/usr/bin/php"
    )
    for candidate in "${candidates[@]}"; do
        if [ -x "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

register_php_alternative() {
    local version="$1"
    local binary_path="$2"
    if [ ! -x "$binary_path" ]; then
        echo -e "${YELLOW}[UYARI]${NC} $binary_path mevcut değil, alternatives kaydı atlandı."
        return 1
    fi
    local priority
    priority=$(echo "$version" | tr -d '.')
    if command -v update-alternatives &> /dev/null; then
        sudo update-alternatives --install /usr/bin/php php "$binary_path" "$priority" >/dev/null 2>&1
    else
        echo -e "${YELLOW}[UYARI]${NC} update-alternatives bulunamadı, varsayılan php symlink'i güncelleniyor."
        sudo ln -sf "$binary_path" /usr/bin/php
    fi
}

install_php_version() {
    local version="$1"
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} PHP ${version} ve Laravel eklentileri kuruluyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    ensure_php_repository || return 1

    declare -A pkg_map=()
    local skipped_exts=()

    case "$PKG_MANAGER" in
        apt)
            pkg_map["php${version}"]=1
            pkg_map["php${version}-cli"]=1
            pkg_map["php${version}-common"]=1
            pkg_map["php${version}-fpm"]=1
            for ext in "${PHP_EXTENSION_PACKAGES[@]}"; do
                local pkg_name=""
                case "$ext" in
                    fpm)
                        continue
                        ;;
                    tokenizer)
                        skipped_exts+=("tokenizer (PHP çekirdeği ile geliyor)")
                        continue
                        ;;
                    *)
                        pkg_name="php${version}-${ext}"
                        ;;
                esac
                pkg_map["$pkg_name"]=1
            done
            ;;
        dnf|yum)
            local rpm_suffix
            rpm_suffix=$(echo "$version" | tr -d '.')
            local base="php${rpm_suffix}-php"
            pkg_map["${base}"]=1
            pkg_map["${base}-cli"]=1
            pkg_map["${base}-common"]=1
            pkg_map["${base}-fpm"]=1
            for ext in "${PHP_EXTENSION_PACKAGES[@]}"; do
                local ext_name="$ext"
                case "$ext" in
                    fpm)
                        continue
                        ;;
                    tokenizer)
                        skipped_exts+=("tokenizer (php-common içinde)")
                        continue
                        ;;
                    mysql)
                        ext_name="mysqlnd"
                        ;;
                esac
                pkg_map["${base}-${ext_name}"]=1
            done
            ;;
        pacman)
            echo -e "${YELLOW}[UYARI]${NC} Pacman depoları tek PHP sürümünü destekler. Varsayılan php paketi kurulacak."
            pkg_map["php"]=1
            pkg_map["php-fpm"]=1
            pkg_map["php-intl"]=1
            pkg_map["php-gd"]=1
            pkg_map["php-pgsql"]=1
            pkg_map["php-sqlite"]=1
            pkg_map["php-curl"]=1
            pkg_map["php-zip"]=1
            pkg_map["php-bcmath"]=1
            pkg_map["php-mbstring"]=1
            pkg_map["php-xml"]=1
            pkg_map["php-mysql"]=1
            ;;
        *)
            echo -e "${RED}[HATA]${NC} Bu paket yöneticisi için PHP kurulumu otomatikleştirilmedi."
            return 1
            ;;
    esac

    local packages=()
    if [ ${#pkg_map[@]} -gt 0 ]; then
        mapfile -t packages < <(printf "%s\n" "${!pkg_map[@]}" | sort)
    fi

    if [ ${#packages[@]} -eq 0 ]; then
        echo -e "${RED}[HATA]${NC} Kurulacak paket bulunamadı."
        return 1
    fi

    echo -e "${YELLOW}[BİLGİ]${NC} Kurulacak paketler: ${GREEN}${packages[*]}${NC}"
    local install_command
    install_command="$INSTALL_CMD ${packages[*]}"
    eval "$install_command"

    if [ ${#skipped_exts[@]} -gt 0 ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} Paket gerektirmeyen/atlanan eklentiler: ${CYAN}${skipped_exts[*]}${NC}"
    fi

    local binary_path
    binary_path=$(resolve_php_binary_path "$version") || true
    if [ -n "$binary_path" ]; then
        register_php_alternative "$version" "$binary_path"
    else
        echo -e "${YELLOW}[UYARI]${NC} PHP ${version} binary'si bulunamadı, sürüm geçişi için manuel kontrol gerekebilir."
    fi

    echo -e "${GREEN}[BAŞARILI]${NC} PHP ${version} kurulumu tamamlandı."
    echo -e "${YELLOW}[BİLGİ]${NC} Aktif sürümü değiştirmek için ana menüden 'PHP sürüm geçişi' seçeneğini kullanın."
}

install_php_version_menu() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Kurmak istediğiniz PHP sürüm(ler)ini seçin:"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    local index=1
    for version in "${PHP_SUPPORTED_VERSIONS[@]}"; do
        echo -e "  ${GREEN}${index}${NC} - PHP ${version}"
        index=$((index + 1))
    done
    echo -e "  ${RED}0${NC} - İptal"
    echo -e "${YELLOW}[BİLGİ]${NC} Birden fazla seçim için virgülle ayırın (örn: 1,2,3)"

    read -p "Seçiminiz: " php_choices
    if [ "$php_choices" = "0" ] || [ -z "$php_choices" ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} PHP kurulumu iptal edildi."
        return 0
    fi

    IFS=',' read -ra SELECTED_PHP <<< "$php_choices"
    
    for choice in "${SELECTED_PHP[@]}"; do
        choice=$(echo "$choice" | tr -d ' ')
        if ! [[ "$choice" =~ ^[1-9][0-9]*$ ]]; then
            echo -e "${RED}[HATA]${NC} Geçersiz seçim: $choice"
            continue
        fi

        local idx=$((choice - 1))
        if [ $idx -lt 0 ] || [ $idx -ge ${#PHP_SUPPORTED_VERSIONS[@]} ]; then
            echo -e "${RED}[HATA]${NC} Desteklenmeyen seçim: $choice"
            continue
        fi

        local selected_version="${PHP_SUPPORTED_VERSIONS[$idx]}"
        install_php_version "$selected_version"
    done
}

switch_php_version_menu() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Kurulu PHP sürümleri arasında geçiş yapın:"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    local available_versions=()
    local available_paths=()

    for version in "${PHP_SUPPORTED_VERSIONS[@]}"; do
        local candidate
        candidate=$(resolve_php_binary_path "$version") || true
        if [ -n "$candidate" ]; then
            available_versions+=("$version")
            available_paths+=("$candidate")
        fi
    done

    if [ ${#available_versions[@]} -eq 0 ]; then
        echo -e "${YELLOW}[UYARI]${NC} Kurulu PHP sürümü bulunamadı. Önce bir sürüm kurun."
        return 1
    fi

    local index=1
    for i in "${!available_versions[@]}"; do
        local version="${available_versions[$i]}"
        local path="${available_paths[$i]}"
        local version_info
        version_info=$("$path" -v 2>/dev/null | head -n 1)
        echo -e "  ${GREEN}${index}${NC} - ${version_info:-PHP $version} (${path})"
        index=$((index + 1))
    done
    echo -e "  ${RED}0${NC} - İptal"

    read -p "Aktifleştirmek istediğiniz sürüm: " switch_choice
    if [ "$switch_choice" = "0" ] || [ -z "$switch_choice" ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} PHP sürüm geçişi iptal edildi."
        return 0
    fi

    if ! [[ "$switch_choice" =~ ^[1-9][0-9]*$ ]]; then
        echo -e "${RED}[HATA]${NC} Geçersiz seçim."
        return 1
    fi

    local selected_index=$((switch_choice - 1))
    if [ $selected_index -lt 0 ] || [ $selected_index -ge ${#available_paths[@]} ]; then
        echo -e "${RED}[HATA]${NC} Desteklenmeyen seçim."
        return 1
    fi

    local target_path="${available_paths[$selected_index]}"
    local target_version="${available_versions[$selected_index]}"

    if command -v update-alternatives &> /dev/null; then
        sudo update-alternatives --set php "$target_path"
    else
        sudo ln -sf "$target_path" /usr/bin/php
    fi

    echo -e "${GREEN}[BAŞARILI]${NC} PHP ${target_version} aktif. Güncel sürüm:"
    php -v | head -n 2
}

# Ana menü
show_menu() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Kurmak istediğiniz araçları seçin:         ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}\n"
    echo -e "${CYAN}=== Hızlı Kurulum ===${NC}"
    echo -e "  ${GREEN}1${NC}  - Tümünü kur (Tüm araçlar)"
    echo -e "\n${CYAN}=== Python Araçları ===${NC}"
    echo -e "  ${GREEN}2${NC}  - Python3 kurulumu"
    echo -e "  ${GREEN}3${NC}  - Pip (Python package manager)"
    echo -e "  ${GREEN}4${NC}  - Pipx (Isolated Python apps)"
    echo -e "  ${GREEN}5${NC}  - UV (Ultra-fast Python installer)"
    echo -e "\n${CYAN}=== Node.js & JS Araçları ===${NC}"
    echo -e "  ${GREEN}6${NC}  - NVM ve Node.js kurulumu"
    echo -e "  ${GREEN}7${NC}  - Bun.js (JS Toolkit)"
    echo -e "\n${CYAN}=== PHP Araçları ===${NC}"
    echo -e "  ${GREEN}8${NC} - PHP (7.4/8.x) kurulumu + Laravel eklentileri"
    echo -e "  ${GREEN}9${NC} - Kurulu PHP sürümleri arasında geçiş"
    echo -e "\n${CYAN}=== AI Frameworks ===${NC}"
    echo -e "  ${GREEN}10${NC}  - SuperGemini Framework (Pipx ile)"
    echo -e "  ${GREEN}11${NC}  - SuperQwen Framework (Pipx ile)"
    echo -e "  ${GREEN}12${NC}  - SuperClaude Framework (Pipx ile)"
    echo -e "\n${CYAN}=== AI CLI Araçları ===${NC}"
    echo -e "  ${GREEN}13${NC} - Claude Code CLI"
    echo -e "  ${GREEN}14${NC} - Gemini CLI"
    echo -e "  ${GREEN}15${NC} - OpenCode CLI"
    echo -e "  ${GREEN}16${NC} - Qoder CLI"
    echo -e "  ${GREEN}17${NC} - Qwen CLI"
    echo -e "  ${GREEN}18${NC} - OpenAI Codex CLI"
    echo -e "\n${CYAN}=== Yapılandırma & Araçlar ===${NC}"
    echo -e "  ${GREEN}19${NC} - Git Global Yapılandırması (Kullanıcı Adı/E-posta)"
    echo -e "  ${GREEN}20${NC} - Claude Code için GLM-4.6 yapılandırması"
    echo -e "  ${GREEN}21${NC} - SuperGemini MCP Sunucu Yönetimi"
    echo -e "  ${GREEN}22${NC} - SuperQwen MCP Sunucu Yönetimi"
    echo -e "  ${GREEN}23${NC} - SuperClaude MCP Sunucu Yönetimi"
    echo -e "  ${RED}0${NC}  - Çıkış\n"
    echo -e "${YELLOW}[BİLGİ]${NC} Birden fazla seçim için virgülle ayırın (örn: 2,3,4)"
    echo -e "${YELLOW}[BİLGİ]${NC} Python araçları için Python (2), Node.js araçları için NVM (6) gereklidir!\n"
}

# Ana program
main() {
    detect_package_manager
    update_system
    
    show_menu
    read -p "Seçiminiz: " choices
    
    NVM_INSTALLED=false
    PYTHON_INSTALLED=false
    
    IFS=',' read -ra SELECTED <<< "$choices"
    
    for choice in "${SELECTED[@]}"; do
        choice=$(echo "$choice" | tr -d ' ')
        
        case $choice in
            1)
                # Python araçları
                install_python
                PYTHON_INSTALLED=true
                install_pip
                install_pipx
                install_uv
                
                # Node.js & JS Araçları
                install_nvm
                NVM_INSTALLED=true
                install_bun
                
                # AI Frameworks
                install_supergemini
                install_superqwen
                install_superclaude
                
                # AI CLI araçları
                install_claude_code
                install_gemini_cli
                install_opencode_cli
                install_qoder_cli
                install_qwen_cli
                install_codex_cli
                
                # Yapılandırmalar
                configure_git
                configure_glm_claude
                ;;
            2)
                install_python
                PYTHON_INSTALLED=true
                ;;
            3)
                if [ "$PYTHON_INSTALLED" = false ] && ! command -v python3 &> /dev/null; then
                    echo -e "${YELLOW}[UYARI]${NC} Pip için önce Python kurulumu yapılıyor..."
                    install_python
                    PYTHON_INSTALLED=true
                fi
                install_pip
                ;;
            4)
                if [ "$PYTHON_INSTALLED" = false ] && ! command -v python3 &> /dev/null; then
                    echo -e "${YELLOW}[UYARI]${NC} Pipx için önce Python kurulumu yapılıyor..."
                    install_python
                    PYTHON_INSTALLED=true
                fi
                install_pipx
                ;;
            5)
                install_uv
                ;;
            6)
                if [ "$NVM_INSTALLED" = false ]; then
                    install_nvm
                    NVM_INSTALLED=true
                fi
                ;;
            7)
                install_bun
                ;;
            8)
                install_php_version_menu
                ;;
            9)
                switch_php_version_menu
                ;;
            10)
                if ! command -v pipx &> /dev/null; then
                    echo -e "${YELLOW}[UYARI]${NC} SuperGemini için önce Pipx kurulumu yapılıyor..."
                    if [ "$PYTHON_INSTALLED" = false ] && ! command -v python3 &> /dev/null; then
                         echo -e "${YELLOW}[UYARI]${NC} Pipx için önce Python kurulumu yapılıyor..."
                         install_python
                         PYTHON_INSTALLED=true
                    fi
                    install_pipx
                fi
                install_supergemini
                ;;
            11)
                if ! command -v pipx &> /dev/null; then
                    echo -e "${YELLOW}[UYARI]${NC} SuperQwen için önce Pipx kurulumu yapılıyor..."
                    if [ "$PYTHON_INSTALLED" = false ] && ! command -v python3 &> /dev/null; then
                         echo -e "${YELLOW}[UYARI]${NC} Pipx için önce Python kurulumu yapılıyor..."
                         install_python
                         PYTHON_INSTALLED=true
                    fi
                    install_pipx
                fi
                install_superqwen
                ;;
            12)
                if ! command -v pipx &> /dev/null; then
                    echo -e "${YELLOW}[UYARI]${NC} SuperClaude için önce Pipx kurulumu yapılıyor..."
                    if [ "$PYTHON_INSTALLED" = false ] && ! command -v python3 &> /dev/null; then
                         echo -e "${YELLOW}[UYARI]${NC} Pipx için önce Python kurulumu yapılıyor..."
                         install_python
                         PYTHON_INSTALLED=true
                    fi
                    install_pipx
                fi
                install_superclaude
                ;;
            13)
                if [ "$NVM_INSTALLED" = false ]; then
                    echo -e "${YELLOW}[UYARI]${NC} Claude Code için önce NVM kurulumu yapılıyor..."
                    install_nvm
                    NVM_INSTALLED=true
                fi
                install_claude_code
                ;;
            14)
                if [ "$NVM_INSTALLED" = false ]; then
                    echo -e "${YELLOW}[UYARI]${NC} Gemini CLI için önce NVM kurulumu yapılıyor..."
                    install_nvm
                    NVM_INSTALLED=true
                fi
                install_gemini_cli
                ;;
            15)
                if [ "$NVM_INSTALLED" = false ]; then
                    echo -e "${YELLOW}[UYARI]${NC} OpenCode CLI için önce NVM kurulumu yapılıyor..."
                    install_nvm
                    NVM_INSTALLED=true
                fi
                install_opencode_cli
                ;;
            16)
                if [ "$NVM_INSTALLED" = false ]; then
                    echo -e "${YELLOW}[UYARI]${NC} Qoder CLI için önce NVM kurulumu yapılıyor..."
                    install_nvm
                    NVM_INSTALLED=true
                fi
                install_qoder_cli
                ;;
            17)
                if [ "$NVM_INSTALLED" = false ]; then
                    echo -e "${YELLOW}[UYARI]${NC} Qwen CLI için önce NVM kurulumu yapılıyor..."
                    install_nvm
                    NVM_INSTALLED=true
                fi
                install_qwen_cli
                ;;
            18)
                if [ "$NVM_INSTALLED" = false ]; then
                    echo -e "${YELLOW}[UYARI]${NC} Codex CLI için önce NVM kurulumu yapılıyor..."
                    install_nvm
                    NVM_INSTALLED=true
                fi
                install_codex_cli
                ;;
            19)
                configure_git
                ;;
            20)
                configure_glm_claude
                ;;
            21)
                cleanup_magic_mcp
                ;;
            22)
                cleanup_qwen_mcp
                ;;
            23)
                cleanup_claude_mcp
                ;;
            0)
                echo -e "${RED}[ÇIKIŞ]${NC} Script sonlandırılıyor..."
                exit 0
                ;;
            *)
                echo -e "${RED}[HATA]${NC} Geçersiz seçim: $choice"
                ;;
        esac
    done
    
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}[TAMAMLANDI]${NC} Kurulum işlemleri tamamlandı!"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}\n"
    echo -e "${YELLOW}[BİLGİ]${NC} Değişikliklerin etkin olması için terminal oturumunuzu yenileyin:"
    echo -e "        ${GREEN}source ~/.bashrc${NC} veya ${GREEN}source ~/.zshrc${NC}\n"
}

main
