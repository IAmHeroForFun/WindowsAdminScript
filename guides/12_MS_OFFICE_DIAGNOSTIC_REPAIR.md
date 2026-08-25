# 12. MS Office General Diagnostic & Configuration Reset Suite

## 📌 Executive Summary
The **MS Office General Diagnostic & Configuration Reset Suite** (`office_fixer/`) is a comprehensive repair suite for Microsoft Office (Office 2010, 2013, 2016, 2019, 2021, and Office 365). It resolves immediate crash-on-launch loops, first-run opt-in dialog freezes, corrupt user profile caches, template corruptions, credential loops, licensing errors, and directory permissions.

---

## 🏗️ Architecture & Component Files

- **Main Coordinator**: `office_fixer/Repair-Office.ps1`
- **Reset Module**: `office_fixer/Reset-Office.ps1`
- **Services Auditor**: `office_fixer/Check-Services.ps1`
- **Permissions Restorer**: `office_fixer/Fix-Permissions.ps1`
- **Dependencies Installer**: `office_fixer/Install-Dependencies.ps1`
- **Activation Auditor**: `office_fixer/Export-Activation.ps1`
- **Log Collector**: `office_fixer/Collect-Logs.ps1`
- **Batch Launcher**: `office_fixer/Run-As-Administrator.bat`
- **Master Menu Option**: `[12]`
- **Direct Web Shortcut**: `irm https://toolkit.omvihub.in/office | iex`

---

## 🔧 Technical Repair Actions

1. **Bypass First-Run Opt-In & Disable Hardware Acceleration**:
   - `ShownFirstRunOptin = 1`, `FirstRun = 0`, `BootedRTM = 1` under `HKCU:\Software\Microsoft\Office\<Ver>\Common\General`.
   - `DisableHardwareAcceleration = 1` under `HKCU:\Software\Microsoft\Office\<Ver>\Common\Graphics` (resolves white screen and GPU crash-on-launch).

2. **Template & User Profile Cache Reset**:
   - Renames corrupt `Normal.dotm` to `Normal.dotm.old`.
   - Safely backs up and resets user profile directories (`%APPDATA%\Microsoft\Office`, `%LOCALAPPDATA%\Microsoft\Office`).

3. **Outlook Autodiscover & Cache Cleaners**:
   - Sets `ExcludeHttpsRootDomain = 1`, `ExcludeSrvRecord = 1`, and `PreferLocalXML = 1` under `Outlook\AutoDiscover`.
   - Renames offline Exchange caches (`*.ost`) to `*.ost.old` to force clean rebuilds.
   - Resets Outlook connection configuration files (`*.srs`).

4. **Credential Manager Purge**:
   - Cleans stored Office/Outlook tokens using `cmdkey.exe /delete` to fix infinite login prompts.

5. **System Services & Licensing Engine**:
   - Audits and starts `sppsvc` (Software Protection), `osppsvc` (Office Software Protection), and `ClickToRunSvc`.
   - Audits licensing status via `ospp.vbs`.

6. **Permissions Restoration**:
   - Grants Full Control rights (`icacls`) on Office program folders and registry hives for `SYSTEM` and `Administrators`.
