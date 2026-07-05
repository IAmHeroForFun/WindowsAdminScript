# ⚡ OmviHub Cloud Software Deployer (WPF & Winget Engine) [Option 16]

A lightweight, antivirus-friendly Windows software deployment application built using **PowerShell 7**, **WPF (XAML)**, and Microsoft's built-in **Winget** package manager.

## ✨ Key Features
- **Modern Dark Theme WPF Interface**: Built with native XAML for a sleek, responsive presentation.
- **Real-Time Filtering & Categories**: Search across 18 essential IT applications grouped into 8 categories.
- **Anti-Hang Silent Execution**: Runs Winget directly with `--silent`, `--disable-interactivity`, and `--no-upgrade` flags.
- **Instant System Cache**: Performs a single bulk query (`winget list`) and scans Windows Registry uninstall hives to verify installed software in under 1 second.
- **Dual-Stream Logging**: Records timestamped events to `Logs\` while streaming real-time status updates directly into the UI console panel.

## 🚀 Usage
Launch directly via double-click wrapper or through Option 16 in the master Windows IT Toolkit:
```powershell
.\deploy_software.ps1
```
