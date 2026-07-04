# ⚡ OmviHub Cloud Software & Utility Deployer [Option 16]

**Enterprise Ninite-Style Hybrid CDN Application Deployment Command Center for Windows & Windows Server.**

---

## 🌟 Overview
The **OmviHub Cloud Software Deployer** is a supercharged, native PowerShell package deployment suite designed for IT technicians and MSPs. It eliminates the need for external paid tools (like Ninite Pro or PDQ Deploy) and avoids consuming expensive AWS server storage and bandwidth.

Instead, it leverages a **Hybrid CDN Architecture**, utilizing Microsoft's native **Winget** package manager and **Chocolatey** to pull verified, latest-version software packages directly from official vendor CDNs (Google, Microsoft, VideoLAN, Mozilla, Wireshark Foundation, etc.) at gigabit edge speeds!

---

## 🔥 Key Features

1. **Genuine Ninite-Style Checkbox Graphical UI (Windows Forms Dark Mode)**:
   * When launched on a GUI-enabled Windows machine, a genuine Ninite-style graphical window pops up!
   * Applications are cleanly organized into categorized GroupBoxes with clickable checkboxes (`[x] Chrome`, `[x] 7-Zip`, `[x] Putty`, etc.).
   * Includes one-click preset buttons (`Select All`, `Clear All`, `⚡ IT Admin Bundle`) right inside the window!
   * Click **🚀 DEPLOY SELECTED SOFTWARE** to begin silent deployment!
2. **Server Core & SSH Fallback Console Menu**:
   * If running on Windows Server Core or in a remote SSH session where a GUI is unavailable, the script seamlessly falls back to a clean numbered console selection menu!
3. **Automatic Package Manager Bootstrapping**:
   * Automatically detects and prioritizes native **Microsoft Winget**.
   * If Winget is missing (e.g., older Windows 10 or Server 2016), it automatically bootstraps **Chocolatey** from its official CDN without human intervention.
4. **Pre-Configured Enterprise Bundles**:
   * Deploy entire software suites in seconds using one-word bundle keywords (`ALL_ADMIN`, `ALL_BROWSERS`, `ALL_DEV`, `ALL_NETWORK`, `ALL_REMOTE`).
5. **100% Offline-Compatible Forensic Reporting**:
   * Automatically records every deployment in an itemized CSV audit log (`reports/deployment_history.csv`).
   * Generates a stunning, self-contained dark-mode HTML Command Center report (`reports/deployment_report.html`).

---

## 📦 Master Software Catalog (30+ Applications)

| Category | Application Name | Package Identifier | Description |
| :--- | :--- | :--- | :--- |
| **Web Browsers** | Google Chrome | `Google.Chrome` | Fast, secure web browser by Google |
| **Web Browser** | Mozilla Firefox | `Mozilla.Firefox` | Open-source privacy-focused web browser |
| **Web Browser** | Microsoft Edge | `Microsoft.Edge` | Chromium-based enterprise web browser |
| **Web Browser** | Brave Browser | `Brave.Brave` | Privacy-first ad-blocking web browser |
| **IT Admin Tools** | Sysinternals Suite | `Microsoft.SysinternalsSuite` | Advanced Windows system utilities |
| **IT Admin Tools** | PuTTY (SSH Client) | `PuTTY.PuTTY` | Telnet and SSH terminal client |
| **IT Admin Tools** | WinSCP (SFTP/SCP) | `WinSCP.WinSCP` | SFTP, SCP, and FTP remote transfer client |
| **IT Admin Tools** | Notepad++ | `Notepad++.Notepad++` | Advanced source code & configuration editor |
| **IT Admin Tools** | TreeSize Free | `JAM Software.TreeSize.Free` | Disk space analyzer & folder hierarchy manager |
| **IT Admin Tools** | PowerToys | `Microsoft.PowerToys` | Microsoft system tuning & productivity utilities |
| **IT Admin Tools** | Windows Terminal | `Microsoft.WindowsTerminal` | Modern tabbed command-line console |
| **Network & Security** | Wireshark | `WiresharkFoundation.Wireshark` | Network protocol analyzer & packet sniffer |
| **Network & Security** | Advanced IP Scanner | `Famatech.AdvancedIPScanner` | Fast LAN subnet scanner with remote control |
| **Network & Security** | Nmap | `Insecure.Nmap` | Security scanner & network exploration tool |
| **Network & Security** | OpenVPN Client | `OpenVPNTechnologies.OpenVPN` | Enterprise SSL VPN tunneling client |
| **File Utilities** | 7-Zip | `7zip.7zip` | High-compression file archiving utility |
| **File Utilities** | WinRAR | `RARLab.WinRAR` | Popular archive & compression tool |
| **File Utilities** | Everything Search | `voidtools.Everything` | Instant real-time filename search engine |
| **File Utilities** | OpenHashTab | `namazso.OpenHashTab` | File checksum verification tab in Explorer |
| **Remote Support** | RustDesk | `RustDesk.RustDesk` | Open-source remote desktop & RMM software |
| **Remote Support** | AnyDesk | `AnyDeskSoftwareGmbH.AnyDesk` | Fast remote desktop assistance application |
| **Remote Support** | TeamViewer | `TeamViewer.TeamViewer` | Enterprise remote support & collaboration |
| **Media & Comm** | VLC Media Player | `VideoLAN.VLC` | Universal multimedia video & audio player |
| **Media & Comm** | Zoom Workplace | `Zoom.Zoom` | Video conferencing & enterprise collaboration |
| **Media & Comm** | Microsoft Teams | `Microsoft.Teams` | Enterprise messaging & meetings platform |
| **Media & Comm** | Discord | `Discord.Discord` | Voice, video, and text communication platform |
| **Developer Tools** | Visual Studio Code | `Microsoft.VisualStudioCode` | Lightweight source code editor by Microsoft |
| **Developer Tools** | Git for Windows | `Git.Git` | Distributed version control system & bash |
| **Developer Tools** | Python 3 | `Python.Python.3` | Python programming language runtime |
| **Developer Tools** | PowerShell 7 | `Microsoft.PowerShell` | Modern cross-platform PowerShell engine |

---

## 🚀 How to Execute

### 1. Interactive Ninite-Style GUI (Default)
Double-click **`run_software_deployer.bat`** or select **Option [16]** from the Master Toolkit Menu:
* A graphical window appears.
* Click to check/highlight the desired applications (hold `Ctrl` or `Shift` for multiple).
* Click **OK** to begin silent deployment!

### 2. Interactive Console Numbered Selection
If running on Server Core or with `-NoGUI`:
```powershell
.\deploy_software.ps1 -NoGUI
```
When prompted, type application numbers separated by commas or enter a bundle name:
```text
Enter application numbers (e.g. 1, 5, 8, 12, 16) or BUNDLE name: 1, 5, 6, 8, 12, 16
```

### 3. Automated Command-Line Execution (Scripted / RMM)
Pass package identifiers or presets directly from command line:
```powershell
# Deploy specific packages silently without prompts
.\deploy_software.ps1 -Packages "Google.Chrome", "7zip.7zip", "PuTTY.PuTTY", "Notepad++.Notepad++" -NoGUI

# Deploy a pre-configured enterprise bundle
.\deploy_software.ps1 -Preset ALL_ADMIN -NoGUI

# Force re-install existing packages
.\deploy_software.ps1 -Preset ALL_BROWSERS -ForceInstall -NoGUI
```

---

## 📊 Generated Reports
Upon completion, reports are saved to `software_deployer\reports\`:
* **`deployment_report.html`**: A standalone, dark-mode visual command center showing exact duration, status badges, and error details.
* **`deployment_history.csv`**: An itemized historical spreadsheet suitable for SLA compliance and client billing audits.
