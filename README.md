# 🚀 AI Development Environment Setup Script

This script automates the setup of a complete AI development environment on Linux-based systems. It detects the operating system's package manager and installs a wide range of tools, including Python, Node.js, NVM, Bun.js, and various AI CLI tools and frameworks like SuperGemini, SuperQwen, SuperClaude, Claude Code, Gemini CLI, and more.

## ✨ Features

*   Automatic package manager detection (apt, dnf, yum, pacman).
*   System update and installation of essential build tools.
*   Installation of Python, Pip, Pipx, and UV.
*   Installation of NVM for Node.js version management, and Bun.js.
*   Installation of various AI frameworks and CLI tools.
*   Interactive menu to select which components to install.
*   Configuration helpers for Git, GLM-4.6, and MCP server cleanup.

## 💡 How to Use

1.  Clone the repository or download the `linux-ai-setup-script.sh` file.
2.  Make the script executable:
    ```bash
    chmod +x linux-ai-setup-script.sh
    ```
3.  Run the script:
    ```bash
    ./linux-ai-setup-script.sh
    ```
4.  Follow the interactive menu to select the tools you want to install.

**⚠️ İnteraktif Komutlar ve İpuçları:** Kurulum sırasında script veya kurulan CLI araçları sizden girdi isteyebilir. Script'in kendi soruları için genellikle `Enter` tuşuna basarak devam edebilirsiniz. Bazı CLI araçları interaktif moda geçebilir; bu durumda, aracı sonlandırmak ve script'in bir sonraki adıma geçmesini sağlamak için `CTRL + C` kullanmanız gerekebilir.

---

# 🚀 AI Geliştirme Ortamı Kurulum Scripti

Bu script, Linux tabanlı sistemlerde eksiksiz bir AI geliştirme ortamının kurulumunu otomatikleştirir. İşletim sisteminin paket yöneticisini algılar ve Python, Node.js, NVM, Bun.js gibi temel araçların yanı sıra SuperGemini, SuperQwen, SuperClaude, Claude Code, Gemini CLI gibi çeşitli AI CLI araçlarını ve framework'lerini kurar.

## ✨ Özellikler

*   Otomatik paket yöneticisi tanıma (apt, dnf, yum, pacman).
*   Sistem güncelleme ve temel geliştirme araçlarının kurulumu.
*   Python, Pip, Pipx ve UV kurulumu.
*   Node.js sürüm yönetimi için NVM ve Bun.js kurulumu.
*   Çeşitli AI framework ve CLI araçlarının kurulumu.
*   Hangi bileşenlerin kurulacağını seçmek için interaktif menü.
*   Git, GLM-4.6 ve MCP sunucu temizliği için yapılandırma yardımcıları.

## 💡 Nasıl Kullanılır

1.  Depoyu klonlayın veya `linux-ai-setup-script.sh` dosyasını indirin.
2.  Script'i çalıştırılabilir yapın:
    ```bash
    chmod +x linux-ai-setup-script.sh
    ```
3.  Script'i çalıştırın:
    ```bash
    ./linux-ai-setup-script.sh
    ```
4.  İnteraktif menüyü takip ederek kurmak istediğiniz araçları seçin.

**⚠️ İnteraktif Komutlar ve İpuçları:** Kurulum sırasında script veya kurulan CLI araçları sizden girdi isteyebilir. Script'in kendi soruları için genellikle `Enter` tuşuna basarak devam edebilirsiniz. Bazı CLI araçları interaktif moda geçebilir; bu durumda, aracı sonlandırmak ve script'in bir sonraki adıma geçmesini sağlamak için `CTRL + C` kullanmanız gerekebilir.