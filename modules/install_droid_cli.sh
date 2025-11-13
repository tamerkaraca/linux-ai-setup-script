#!/bin/bash
set -euo pipefail

DOC_URL="https://docs.factory.ai/cli/getting-started/quickstart"

if command -v droid >/dev/null 2>&1; then
    echo -e "${GREEN:-}[BİLGİ]${NC:-} droid CLI zaten kurulu: $(droid --version 2>/dev/null || echo 'sürüm bilgisi okunamadı')."
    exit 0
fi

echo -e "\n${BLUE:-}╔═══════════════════════════════════════════════╗${NC:-}"
echo -e "${YELLOW:-}[BİLGİ]${NC:-} Droid CLI kurulumu için resmi talimatlara yönlendiriliyorsunuz."
echo -e "${BLUE:-}╚═══════════════════════════════════════════════╝${NC:-}\n"

echo -e "${YELLOW:-}[BİLGİ]${NC:-} Factory, Droid CLI kurulumunu işletim sistemine göre değişen bir bootstrap betiği üzerinden dağıtıyor. Aşağıdaki adımlar özet niteliğindedir; ayrıntılar için resmi dökümanı ziyaret edin:"

echo -e "  1. https://factory.ai adresinde oturum açın ve CLI Quickstart sayfasını açın."
echo -e "  2. Sayfadaki macOS/Linux ya da Windows sekmesinde yer alan betiği kopyalayın (örneğin macOS/Linux için indirme + chmod + ./droid)."
echo -e "  3. Betiği projenizin bulunduğu dizinde çalıştırın ve istemciyi başlattıktan sonra tarayıcıda doğrulama adımlarını tamamlayın."
echo -e "  4. İlk oturum açmadan sonra 'droid' komutuyla etkileşimli terminal UI'sini başlatabilir, 'droid exec' ile headless modu kullanabilirsiniz."

echo -e "${YELLOW:-}[NOT]${NC:-} Resmi talimatlar için: ${DOC_URL}\n"

echo -e "Bu script, kurulumun manuel adımlarını otomatikleştirmez; Factory'nin belgelediği bootstrap komutlarını çalıştırmanız gerekir."
