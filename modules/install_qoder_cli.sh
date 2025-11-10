#!/bin/bash

# Ortak yardımcı fonksiyonları yükle
# shellcheck source=/dev/null
source "/mnt/d/ai/modules/utils.sh"

install_qoder_cli() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} Qoder CLI kurulumu başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if command -v qoder &> /dev/null; then
        echo -e "${GREEN}[BAŞARILI]${NC} Qoder CLI zaten kurulu: $(qoder --version 2>/dev/null)"
        return 0
    fi

    echo -e "${YELLOW}[BİLGİ]${NC} Qoder CLI npm ile kuruluyor..."
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}[HATA]${NC} npm bulunamadı. Lütfen Node.js ve npm'i kurun (Ana Menü -> 3. Node.js ve İlgili Araçları Kur)."
        return 1
    fi

    if sudo npm install -g qoder; then
        echo -e "${GREEN}[BAŞARILI]${NC} Qoder CLI kurulumu tamamlandı."
        reload_shell_configs silent # PATH güncellemelerini uygulamak için
    else
        echo -e "${RED}[HATA]${NC} Qoder CLI kurulumu başarısız oldu."
        return 1
    fi

    if command -v qoder &> /dev/null; then
        echo -e "${GREEN}[BAŞARILI]${NC} Qoder CLI başarıyla kuruldu: $(qoder --version 2>/dev/null)"
    else
        echo -e "${RED}[HATA]${NC} Qoder CLI kuruldu ancak 'qoder' komutu bulunamadı. PATH ayarlarınızı kontrol edin."
        return 1
    fi
}

main() {
    install_qoder_cli
}

main