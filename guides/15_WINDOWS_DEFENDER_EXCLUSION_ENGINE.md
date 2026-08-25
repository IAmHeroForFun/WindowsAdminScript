# 15. Windows Defender Signature Reset & Exclusion Engine

## 📌 Executive Summary
The **Windows Defender Signature Reset & Exclusion Repair Suite** (`antivirus_fixer/`) resolves corrupted Microsoft Defender virus signatures, stuck definition update error codes (`0x80070643` / `0x800106ba`), and false-positive antivirus blocking by managing folder and process exclusions and verifying the Security Center WMI repository.

---

## 🏗️ Architecture & Component Files

- **Main Coordinator**: `antivirus_fixer/fix_antivirus.ps1`
- **Definition Reset Engine**: `antivirus_fixer/Reset-Defender-Definitions.ps1`
- **Exclusion Manager**: `antivirus_fixer/Manage-Defender-Exclusions.ps1`
- **Security Center WMI Fixer**: `antivirus_fixer/Repair-Security-Center-WMI.ps1`
- **Batch Launcher**: `antivirus_fixer/Run-As-Administrator.bat`
- **Master Menu Option**: `[15]`
- **Direct Web Shortcut**: `irm https://toolkit.omvihub.in/defender | iex`

---

## 🔧 Technical Repair Modules

### 1. Definition Purge & Force Signature Update (`Reset-Defender-Definitions.ps1`):
- Locates `MpCmdRun.exe` in `C:\ProgramData\Microsoft\Windows Defender\Platform\<Version>\` or `C:\Program Files\Windows Defender\`.
- Executes:
  ```cmd
  MpCmdRun.exe -RemoveDefinitions -All
  MpCmdRun.exe -SignatureUpdate
  ```
- Purges corrupt signature databases and downloads a fresh definition package directly from Microsoft Update servers.

### 2. Antivirus Exclusions Management (`Manage-Defender-Exclusions.ps1`):
- Lists currently active path, process, and extension exclusions (`Get-MpPreference`).
- Interactively adds custom folder exclusions (e.g. `C:\ERP_Software`, `D:\Development`) or process exclusions via `Add-MpPreference -ExclusionPath` / `Add-MpPreference -ExclusionProcess`.

### 3. Security Center WMI Health & Audit (`Repair-Security-Center-WMI.ps1`):
- Queries `root\SecurityCenter2` WMI namespace (`AntiVirusProduct`, `FirewallProduct`, `AntiSpywareProduct`).
- Audits active third-party antivirus agents and reports real-time state flags.
