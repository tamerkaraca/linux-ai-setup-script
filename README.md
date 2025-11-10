# 🚀 AI Development Environment Setup Script

---

## 🇬🇧 English Guide

### Overview
The `setup` script automates preparing a Linux workstation for AI development. It corrects accidental Windows CRLF endings, detects the system's package manager (`apt`, `dnf`, `yum`, `pacman`), upgrades the OS, and installs all required runtimes (Python, Pip, Pipx, UV, NVM, Node.js, Bun, PHP 7.4–8.5). On top of that it bootstraps frequently used AI CLIs (Claude Code, Gemini CLI, OpenCode, Qoder, Qwen, OpenAI Codex, GitHub Copilot CLI), GitHub CLI, and Pipx-based AI frameworks (SuperGemini/SuperQwen/SuperClaude), plus helpers for Git, GLM-4.6 credentials, and MCP server cleanup.

### Features
- **Modular & On-Demand Installation:** The `setup` script provides an interactive menu to select and install only the components you need. Each component is downloaded and executed via `curl` on demand, avoiding a full repository clone for initial setup.
- Automatic package-manager detection, colored logging, and CRLF self-healing.
- System upgrade + essential developer tooling (curl, wget, git, jq, zip/unzip, build toolchains).
- Full Python toolchain (python3, pip, pipx, UV) and JavaScript runtimes (NVM-managed Node.js, Bun).
- AI CLI installers for Claude Code, Gemini CLI, OpenCode CLI, Qoder CLI, Qwen CLI, OpenAI Codex CLI, and GitHub Copilot CLI, plus GitHub CLI.
- AI framework menu for SuperGemini, SuperQwen, SuperClaude with guided API-key prompts.
- Removal menu to undo SuperGemini/SuperQwen/SuperClaude installs and purge their configs in one go.
- PHP installer with selectable versions, Laravel-friendly extension packs, automatic Composer bootstrap, and version switcher.
- Configuration helpers: interactive Git setup, GLM-4.6 configuration for Claude Code, MCP server listing/reset.

### Requirements
- Linux distribution with one of `apt`, `dnf`, `yum`, or `pacman`.
- `bash` 5+, `sudo` privileges, and an active internet connection (cURL downloads, package repos).
- Optional but recommended: `dos2unix` for faster CRLF fixes and `shellcheck` for static analysis.

### Installation

You have two primary ways to use this setup script:

#### 1. Quick Install via cURL (Recommended for initial setup)
This method downloads and runs the main `setup` script directly, which then allows you to selectively install components.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/tamerkaraca/linux-ai-setup-script/main/setup)"
```

#### 2. Local Clone and Run
If you prefer to inspect the code or contribute, you can clone the repository:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/tamerkaraca/linux-ai-setup-script.git
   cd linux-ai-setup-script
   ```
2. **Make the main script executable** (and optionally run quick linting):
   ```bash
   chmod +x setup
   bash -n setup
   shellcheck setup   # optional but recommended
   ```
3. **Run the installer** (use `sudo` password when asked):
   ```bash
   ./setup
   ```

### Usage
- Launching the `setup` script opens an interactive menu. You may enter a single number to perform an operation. Some options lead to sub-menus.
- Menu overview:
  - `1` – Update System and Install Basic Packages
  - `2` – Install Python and Related Tools (Pip, Pipx, UV)
  - `3` – Install Node.js and Related Tools (NVM, Bun.js)
  - `4` – Install AI Frameworks (SuperGemini, SuperQwen, SuperClaude) - *This opens a sub-menu.*
  - `5` – Install AI CLI Tools (Claude Code, Gemini CLI, OpenCode, Qoder, Qwen, OpenAI Codex, GitHub Copilot CLI) - *This opens a sub-menu.*
  - `6` – Git Configuration
  - `7` – GLM-4.6 Claude Code Configuration
  - `8` – PHP and Composer Installation
  - `9` – GitHub CLI Installation
  - `10` – Uninstall AI Frameworks - *This opens a sub-menu.*
  - `11` – MCP Server Management - *This opens a sub-menu.*
  - `A` – Install All (Sequentially)
  - `0` – Exit
- Within sub-menus, typing `0` returns to the previous screen. Prompts default to the safest option if you simply press `Enter`.

### Usage Details & Tips
- **API keys:** SuperGemini/SuperQwen/SuperClaude installers request Gemini, Anthropic, OpenAI, and related provider keys. GLM configuration requires a key from https://z.ai/model-api. GitHub Copilot CLI flows follow https://github.com/github/copilot-cli (`npm install -g @github/copilot`, then manually run `copilot auth login` and `copilot auth activate`), with the script auto-adding the alias (`eval "$(copilot alias -- bash|zsh)"`) to your shell RC.
- **Privileges:** Package installations run via `sudo`; review the prompts before confirming. System upgrades may take several minutes.
- **Environment updates:** The script appends PATH exports for Pipx (`~/.local/bin`), UV (`~/.cargo/bin`), NVM (`~/.nvm`), and Bun (`~/.bun/bin`) to `~/.bashrc`, `~/.zshrc`, and `~/.profile` when present. Restart your shell or `source ~/.bashrc` afterwards.
- **Idempotent behavior:** Re-running the script is safe; existing tools are detected, and missing components are installed. Use targeted menu selections for incremental updates (e.g., rerun option `11` to refresh AI CLIs).
- **Troubleshooting:** If a CLI remains unavailable after installation, ensure your shell has the updated PATH entries and reopen the terminal. Logs are color-coded (`[BİLGİ]`, `[UYARI]`, `[HATA]`) to highlight the current step.
- **Composer availability:** Installing any PHP version automatically downloads Composer (signature-verified) into `/usr/local/bin/composer`, so Laravel or other PHP projects can start immediately.
- **GLM credentials:** Menu option 7 shows your existing GLM API key in masked form (`abcd***wxyz`). Press `Enter` to keep it or type a new key to overwrite; the base URL prompt behaves the same way.
- **Auto-sourcing:** Whenever PATH or toolchain exports are updated, the script reloads your shell config (`~/.bashrc`, `~/.zshrc`, or `~/.profile`) automatically and prints a notice so follow-up commands in the same run can see the changes.
- **Testing:** Before submitting changes, run `shellcheck setup` and `bash -n setup`. For smoke tests, you can set `PKG_MANAGER=apt ./setup --dry-run` once the flag is implemented.

---

## 🇹🇷 Türkçe Rehber

### Genel Bakış
`setup`, Linux tabanlı geliştirici makinelerde uçtan uca AI çalışma ortamını hazırlar. Windows’tan gelen CRLF satır sonlarını düzeltir, paket yöneticisini (`apt`, `dnf`, `yum`, `pacman`) otomatik saptar, sistemi günceller ve gerekli tüm çalışma ortamlarını (Python, Pip, Pipx, UV, NVM, Node.js, Bun, PHP 7.4–8.5) kurar. Buna ek olarak sık kullanılan AI CLI araçlarını (Claude Code, Gemini CLI, OpenCode, Qoder, Qwen, OpenAI Codex, GitHub Copilot CLI), GitHub CLI ve Pipx tabanlı AI framework’lerini (SuperGemini/SuperQwen/SuperClaude) yükler; Git yapılandırması, GLM-4.6 anahtarı ve MCP sunucu temizliği gibi yardımcı menüler sağlar.

### Özellikler
- **Modüler ve İsteğe Bağlı Kurulum:** `setup` script'i, yalnızca ihtiyacınız olan bileşenleri seçip kurmanız için etkileşimli bir menü sunar. Her bileşen, ilk kurulum için tüm depoyu klonlamaya gerek kalmadan, isteğe bağlı olarak `curl` aracılığıyla indirilir ve çalıştırılır.
- Paket yöneticisi tespiti, renkli günlükler ve CRLF otomatik düzeltmesi ile sürüm kontrolünde güvenli kullanım.
- Sistem güncellemesi + temel geliştirici araçları (curl, wget, git, jq, zip/unzip, derleme araçları).
- Python ekosistemi (python3, pip, pipx, UV) ve JavaScript çalıştırıcıları (NVM ile Node.js, Bun).
- AI CLI kurulumları: Claude Code, Gemini CLI, OpenCode CLI, Qoder CLI, Qwen CLI, OpenAI Codex CLI, GitHub Copilot CLI, GitHub CLI.
- Pipx üzerinden SuperGemini, SuperQwen, SuperClaude kurulum menüsü ve anahtar istemleri.
- SuperGemini/SuperQwen/SuperClaude için temiz kaldırma menüsü ve yapılandırma temizliği.
- PHP 7.4/8.x kurulumu, Laravel eklentileri, Composer kurulumu ve sürüm değiştirme menüsü.
- Git, GLM-4.6 yapılandırması ve MCP sunucu yönetimine yönelik etkileşimli rehberler.

### Kurulum

Bu kurulum script'ini kullanmak için iki ana yöntem bulunmaktadır:

#### 1. cURL ile Hızlı Kurulum (İlk kurulum için önerilir)
Bu yöntem, ana `setup` script'ini doğrudan indirir ve çalıştırır; bu sayede bileşenleri seçerek kurabilirsiniz.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/tamerkaraca/linux-ai-setup-script/main/setup)"
```

#### 2. Yerel Klonlama ve Çalıştırma
Kodu incelemeyi veya katkıda bulunmayı tercih ediyorsanız, depoyu klonlayabilirsiniz:

1. **Depoyu klonlayın:**
   ```bash
   git clone https://github.com/tamerkaraca/linux-ai-setup-script.git
   cd linux-ai-setup-script
   ```
2. **Ana script'i çalıştırılabilir yapın** (ve isteğe bağlı olarak hızlı lint kontrolü yapın):
   ```bash
   chmod +x setup
   bash -n setup
   shellcheck setup   # isteğe bağlı fakat önerilir
   ```
3. **Kurulumu başlatın** (`sudo` parolanızı isteyebilir):
   ```bash
   ./setup
   ```

### Kullanım
- `setup` script'ini başlattığınızda etkileşimli bir menü açılır. Bir işlem gerçekleştirmek için tek bir sayı girebilirsiniz. Bazı seçenekler alt menülere yönlendirir.
- Menü özeti:
  - `1` – Sistemi Güncelle ve Temel Paketleri Kur
  - `2` – Python ve İlgili Araçları Kur (Pip, Pipx, UV)
  - `3` – Node.js ve İlgili Araçları Kur (NVM, Bun.js)
  - `4` – AI Frameworklerini Kur (SuperGemini, SuperQwen, SuperClaude) - *Bu bir alt menü açar.*
  - `5` – AI CLI Araçlarını Kur (Claude Code, Gemini CLI, OpenCode, Qoder, Qwen, OpenAI Codex, GitHub Copilot CLI) - *Bu bir alt menü açar.*
  - `6` – Git Yapılandırması
  - `7` – GLM-4.6 Claude Code Yapılandırması
  - `8` – PHP ve Composer Kurulumu
  - `9` – GitHub CLI Kurulumu
  - `10` – AI Frameworklerini Kaldır - *Bu bir alt menü açar.*
  - `11` – MCP Sunucu Yönetimi - *Bu bir alt menü açar.*
  - `A` – Hepsini Kur (Sırayla)
  - `0` – Çıkış
- Alt menülerde `0` yazarak geri dönebilir, `Enter` ile varsayılan yanıtları kabul edebilirsiniz.

### Kullanım Detayları
- **API anahtarları:** SuperGemini/SuperQwen/SuperClaude kurulumlarında Gemini, Anthropic, OpenAI vb. anahtarlar istenir. GLM yapılandırması için https://z.ai/model-api adresinden alınan anahtar gereklidir. GitHub Copilot CLI akışları https://github.com/github/copilot-cli adresini takip eder (`npm install -g @github/copilot`, ardından `copilot auth login` ve `copilot auth activate` komutlarını manuel olarak çalıştırın), script otomatik olarak alias'ı (`eval "$(copilot alias -- bash|zsh)"`) shell RC dosyanıza ekler.
- **Yetkiler:** Paket kurulumları `sudo` ile yapılır; yükseltilmiş komutları onaylamadan önce inceleyin. Sistem güncellemeleri birkaç dakika sürebilir.
- **Ortam değişkenleri:** Script; Pipx (`~/.local/bin`), UV (`~/.cargo/bin`), NVM (`~/.nvm`) ve Bun (`~/.bun/bin`) yollarını `~/.bashrc`, `~/.zshrc`, `~/.profile` dosyalarınıza ekler. İşlem sonrası terminalinizi yeniden başlatın veya `source ~/.bashrc` çalıştırın.
- **Tekrar çalıştırma:** Script idem-potent çalışır; eksik bileşenleri tamamlamak veya belirli menüleri (örn. sadece AI CLI’ları) yeniden kurmak için tekrar çalıştırabilirsiniz.
- **Sorun giderme:** Kurulumdan sonra komut bulunamıyorsa PATH güncellemelerinin yüklendiğinden emin olun ve terminali kapatıp açın. `[BİLGİ]`, `[UYARI]`, `[HATA]` etiketleri hangi adımda olduğunuzu gösterir.
- **Composer kullanımı:** Herhangi bir PHP sürümü kurduğunuzda script otomatik olarak imza doğrulamalı Composer'i `/usr/local/bin/composer` yoluna ekler; Laravel projelerine hemen başlayabilirsiniz.
- **GLM bilgileri:** 7 numaralı menüde mevcut GLM API key maskeleme ile (`abcd***wxyz`) gösterilir. Enter'a bastığınızda değer korunur, yeni key girerseniz eskisiyle değiştirilir; Base URL için de aynı mantık geçerlidir.
- **Otomatik source:** PATH veya ortam değişikliklerinde script uygun shell dosyasını (`~/.bashrc`, `~/.zshrc`, `~/.profile`) otomatik olarak `source` eder ve bilgi mesajı gösterir; böylece aynı oturumda komutlar güncel yolu görür.
- **Test önerisi:** Değişiklik yapıyorsanız `shellcheck setup` ve `bash -n setup` çalıştırın; ayrıca uygun olduğunda `PKG_MANAGER=apt ./setup --dry-run` gibi duman testleri planlayın.
