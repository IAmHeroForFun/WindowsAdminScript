# 07. Windows 11 Enterprise Debloat & Privacy Optimizer

## 📌 Executive Summary
The **Windows 11 Enterprise Debloat & Privacy Suite** (`win11_debloater/debloat.ps1`) is a safe, reversible customization and debloating engine designed specifically for Windows 11 (builds 22000+). It safely uninstalls third-party sponsored bloatware, disables diagnostic telemetry and advertising IDs, declutters the taskbar, and disables OneDrive background auto-sync.

---

## 🏗️ Architecture & Script Mapping

- **Primary Script**: `win11_debloater/debloat.ps1`
- **Batch Launcher**: `win11_debloater/run_debloater.bat`
- **Master Menu Option**: `[7]`
- **Direct Web Shortcut**: `irm https://toolkit.omvihub.in/debloat | iex`

---

## 🛠️ Optimization Modules & Registry Tweaks

### 1. Sponsored UWP Bloatware Removal
Removes non-essential consumer packages via `Remove-AppxPackage -AllUsers`:
- `Clipchamp`, `TikTok`, `Spotify`, `Disney`, `PrimeVideo`, `Netflix`, `Instagram`, `Duolingo`, `XboxGamingOverlay`, `Solitaire`, `YourPhone`, `FeedbackHub`.
- Preserves core system packages (Microsoft Store, Calculator, Notepad, Terminal, Photos, Security).

### 2. Diagnostic Telemetry & Privacy Tracking Services
- Stops and disables `DiagTrack` (Connected User Experiences and Telemetry) and `dmwappushservice`.
- Registry Tweaks (`HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection`):
  - `AllowTelemetry = 0`
- User Privacy (`HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo`):
  - `Enabled = 0`

### 3. Taskbar & UI Decluttering
Configures `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced`:
- `TaskbarDa = 0` (Hides Widgets)
- `TaskbarMn = 0` (Hides Chat / Teams)
- `ShowTaskViewButton = 0` (Hides Task View)
- `SearchboxTaskbarMode = 1` (Shrinks Search Box to simple icon)

### 4. OneDrive Auto-Startup & Sync
- Removes auto-start entry from `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\OneDrive`.
- Terminates running `OneDrive.exe` background sync processes.

---

## 🔄 Rollback & Safety Principles
- Uses non-destructive registry tweaks and clean AppX removal.
- Never removes system-critical framework components.
- All actions require confirmation (`Ask-Option` with `[Y/N, Q to Cancel]`).
