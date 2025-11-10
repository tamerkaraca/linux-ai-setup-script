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

    echo -e "${YELLOW}[BİLGİ]${NC} Qoder CLI indiriliyor ve kuruluyor..."
    if curl -fsSL https://qoder.com/install.sh | bash; then
        echo -e "${GREEN}[BAŞARILI]${NC} Qoder CLI kurulumu tamamlandı."
        # Qoder CLI'ın PATH'e eklenmesi gerekebilir, genellikle installer bunu yapar.
        # Eğer yapmazsa, burada PATH'i güncellemek gerekebilir.
        # Şimdilik varsayalım ki installer PATH'i günlüyor veya ~/.local/bin gibi bir yere kuruyor.
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