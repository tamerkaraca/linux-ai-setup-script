# 🚀 AI Development Environment Setup Script

---

## 🇬🇧 English Guide

### Overview
`linux-ai-setup-script.sh` automates preparing a Linux workstation for AI development. It corrects accidental Windows CRLF endings, detects the system's package manager (`apt`, `dnf`, `yum`, `pacman`), upgrades the OS, and installs all required runtimes (Python, Pip, Pipx, UV, NVM, Node.js, Bun, PHP 7.4–8.5). On top of that it bootstraps frequently used AI CLIs (Claude Code, Gemini CLI, OpenCode, Qoder, Qwen, OpenAI Codex) and Pipx-based AI frameworks (SuperGemini/SuperQwen/SuperClaude), plus helpers for Git, GLM-4.6 credentials, and MCP server cleanup.

### Features
- Automatic package-manager detection, colored logging, and CRLF self-healing so the script can be checked into Git safely.
- System upgrade + essential developer tooling (curl, wget, git, jq, zip/unzip, build toolchains).
- Full Python toolchain (python3, pip, pipx, UV) and JavaScript runtimes (NVM-managed Node.js, Bun).
- AI CLI installers for Claude Code, Gemini CLI, OpenCode CLI, Qoder CLI, Qwen CLI, and OpenAI Codex CLI.
- AI framework menu for SuperGemini, SuperQwen, SuperClaude with guided API-key prompts.
- PHP installer with selectable versions, Laravel-friendly extension packs, automatic Composer bootstrap, and version switcher.
- Configuration helpers: interactive Git setup, GLM-4.6 configuration for Claude Code, MCP server listing/reset.

### Requirements
- Linux distribution with one of `apt`, `dnf`, `yum`, or `pacman`.
- `bash` 5+, `sudo` privileges, and an active internet connection (cURL downloads, package repos).
- Optional but recommended: `dos2unix` for faster CRLF fixes and `shellcheck` for static analysis.

### Installation (Kurulum)
1. **Clone or download** the repository:
   ```bash
   git clone https://github.com/tamerkaraca/linux-ai-setup-script.git
   cd linux-ai-setup-script
   ```
2. **Make the script executable** and run quick linting:
   ```bash
   chmod +x linux-ai-setup-script.sh
   bash -n linux-ai-setup-script.sh
   shellcheck linux-ai-setup-script.sh   # optional but recommended
   ```
3. **Run the installer** (use `sudo` password when asked):
   ```bash
   ./linux-ai-setup-script.sh
   ```

### Usage (Kullanım)
- Launching the script opens an interactive menu. You may enter a single number or comma-separated choices to perform multiple operations in one run (e.g., `1,7,11`).
- Menu overview:
  - `1` – Install everything (system prep, runtimes, CLIs, frameworks, configs).
  - `2` – System prep + Git configuration only.
  - `3-6` – Python stack: Python3, Pip, Pipx, UV.
  - `7-8` – JavaScript runtimes: NVM/Node.js and Bun.
  - `9-10` – PHP installer (7.4/8.x + extensions + Composer) and version switcher.
  - `11` – AI CLI Tools menu (Claude Code, Gemini CLI, OpenCode, Qoder, Qwen, OpenAI Codex; choose individually or all).
  - `12` – AI Frameworks menu (SuperGemini, SuperQwen, SuperClaude; installs via Pipx).
  - `13` – Configure GLM-4.6 endpoint/key for Claude Code.
  - `14` – MCP Server management (list/reset local MCP instances).
  - `0` – Exit.
- Within sub-menus, typing `0` returns to the previous screen. Prompts default to the safest option if you simply press `Enter`.

### Usage Details & Tips (Kullanım Detayları)
- **API keys:** SuperGemini/SuperQwen/SuperClaude installers request Gemini, Anthropic, OpenAI, and related provider keys. GLM configuration requires a key from https://z.ai/model-api.
- **Privileges:** Package installations run via `sudo`; review the prompts before confirming. System upgrades may take several minutes.
- **Environment updates:** The script appends PATH exports for Pipx (`~/.local/bin`), UV (`~/.cargo/bin`), NVM (`~/.nvm`), and Bun (`~/.bun/bin`) to `~/.bashrc`, `~/.zshrc`, and `~/.profile` when present. Restart your shell or `source ~/.bashrc` afterwards.
- **Idempotent behavior:** Re-running the script is safe; existing tools are detected, and missing components are installed. Use targeted menu selections for incremental updates (e.g., rerun option `11` to refresh AI CLIs).
- **Troubleshooting:** If a CLI remains unavailable after installation, ensure your shell has the updated PATH entries and reopen the terminal. Logs are color-coded (`[BİLGİ]`, `[UYARI]`, `[HATA]`) to highlight the current step.
- **Composer availability:** Installing any PHP version automatically downloads Composer (signature-verified) into `/usr/local/bin/composer`, so Laravel or other PHP projects can start immediately.
- **Testing:** Before submitting changes, run `shellcheck linux-ai-setup-script.sh` and `bash -n linux-ai-setup-script.sh`. For smoke tests, you can set `PKG_MANAGER=apt ./linux-ai-setup-script.sh --dry-run` once the flag is implemented.

---

## 🇹🇷 Türkçe Rehber

### Genel Bakış
`linux-ai-setup-script.sh`, Linux tabanlı geliştirici makinelerde uçtan uca AI çalışma ortamını hazırlar. Windows’tan gelen CRLF satır sonlarını düzeltir, paket yöneticisini (`apt`, `dnf`, `yum`, `pacman`) otomatik saptar, sistemi günceller ve gerekli tüm çalışma ortamlarını (Python, Pip, Pipx, UV, NVM, Node.js, Bun, PHP 7.4–8.5) kurar. Buna ek olarak sık kullanılan AI CLI araçlarını (Claude Code, Gemini CLI, OpenCode, Qoder, Qwen, OpenAI Codex) ve Pipx tabanlı AI framework’lerini (SuperGemini/SuperQwen/SuperClaude) yükler; Git yapılandırması, GLM-4.6 anahtarı ve MCP sunucu temizliği gibi yardımcı menüler sağlar.

### Özellikler
- Paket yöneticisi tespiti, renkli günlükler ve CRLF otomatik düzeltmesi ile sürüm kontrolünde güvenli kullanım.
- Sistem güncellemesi + temel geliştirici araçları (curl, wget, git, jq, zip/unzip, derleme araçları).
- Python ekosistemi (python3, pip, pipx, UV) ve JavaScript çalıştırıcıları (NVM ile Node.js, Bun).
- AI CLI kurulumları: Claude Code, Gemini CLI, OpenCode CLI, Qoder CLI, Qwen CLI, OpenAI Codex CLI.
- Pipx üzerinden SuperGemini, SuperQwen, SuperClaude kurulum menüsü ve anahtar istemleri.
- PHP 7.4/8.x kurulumu, Laravel eklentileri, Composer kurulumu ve sürüm değiştirme menüsü.
- Git, GLM-4.6 yapılandırması ve MCP sunucu yönetimine yönelik etkileşimli rehberler.

### Kurulum
1. **Depoyu klonlayın veya indirin:**
   ```bash
   git clone https://github.com/tamerkaraca/linux-ai-setup-script.git
   cd linux-ai-setup-script
   ```
2. **Script’i çalıştırılabilir yapın ve hızlı kontrolleri çalıştırın:**
   ```bash
   chmod +x linux-ai-setup-script.sh
   bash -n linux-ai-setup-script.sh
   shellcheck linux-ai-setup-script.sh   # isteğe bağlı fakat önerilir
   ```
3. **Kurulumu başlatın** (`sudo` parolanızı isteyebilir):
   ```bash
   ./linux-ai-setup-script.sh
   ```

### Kullanım
- Script açıldığında etkileşimli bir menü görürsünüz. Tek bir seçenek girebilir veya virgülle ayırarak birden fazla işlemi aynı anda tetikleyebilirsiniz (örn. `1,7,11`).
- Menü özeti:
  - `1` – Her şeyi kur (sistem hazırlığı, runtime’lar, CLI’lar, framework’ler, yapılandırmalar).
  - `2` – Sadece sistem hazırlığı + Git ayarları.
  - `3-6` – Python araçları: Python3, Pip, Pipx, UV.
  - `7-8` – JavaScript araçları: NVM/Node.js ve Bun.
  - `9-10` – PHP kurulumu (7.4/8.x + eklentiler + Composer) ve sürüm geçişi.
  - `11` – AI CLI Araçları menüsü (Claude Code, Gemini CLI, OpenCode, Qoder, Qwen, OpenAI Codex).
  - `12` – AI Framework menüsü (SuperGemini, SuperQwen, SuperClaude).
  - `13` – Claude Code için GLM-4.6 anahtar/base URL yapılandırması.
  - `14` – MCP Sunucularını listeleme ve temizleme menüsü.
  - `0` – Çıkış.
- Alt menülerde `0` yazarak geri dönebilir, `Enter` ile varsayılan yanıtları kabul edebilirsiniz.

### Kullanım Detayları
- **API anahtarları:** SuperGemini/SuperQwen/SuperClaude kurulumlarında Gemini, Anthropic, OpenAI vb. anahtarlar istenir. GLM yapılandırması için https://z.ai/model-api adresinden alınan anahtar gereklidir.
- **Yetkiler:** Paket kurulumları `sudo` ile yapılır; yükseltilmiş komutları onaylamadan önce inceleyin. Sistem güncellemeleri birkaç dakika sürebilir.
- **Ortam değişkenleri:** Script; Pipx (`~/.local/bin`), UV (`~/.cargo/bin`), NVM (`~/.nvm`) ve Bun (`~/.bun/bin`) yollarını `~/.bashrc`, `~/.zshrc`, `~/.profile` dosyalarınıza ekler. İşlem sonrası terminalinizi yeniden başlatın veya `source ~/.bashrc` çalıştırın.
- **Tekrar çalıştırma:** Script idem-potent çalışır; eksik bileşenleri tamamlamak veya belirli menüleri (örn. sadece AI CLI’ları) yeniden kurmak için tekrar çalıştırabilirsiniz.
- **Sorun giderme:** Kurulumdan sonra komut bulunamıyorsa PATH güncellemelerinin yüklendiğinden emin olun ve terminali kapatıp açın. `[BİLGİ]`, `[UYARI]`, `[HATA]` etiketleri hangi adımda olduğunuzu gösterir.
- **Composer kullanımı:** Herhangi bir PHP sürümü kurduğunuzda script otomatik olarak imza doğrulamalı Composer'i `/usr/local/bin/composer` yoluna ekler; Laravel projelerine hemen başlayabilirsiniz.
- **Test önerisi:** Değişiklik yapıyorsanız `shellcheck linux-ai-setup-script.sh` ve `bash -n linux-ai-setup-script.sh` çalıştırın; ayrıca uygun olduğunda `PKG_MANAGER=apt ./linux-ai-setup-script.sh --dry-run` gibi duman testleri planlayın.
