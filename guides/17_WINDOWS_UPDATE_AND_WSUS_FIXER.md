# 17. Windows Update, WSUS & Component Store Repair Suite

## 📌 Executive Summary
The **Windows Update, WSUS & Component Store (DISM/CBS) Repair Suite** (`update_fixer/fix_windows_update.ps1`) diagnoses and resolves corrupted Windows Update components, stuck download and installation loops, bloated cache directories, orphaned BITS transfer queues, unreachable corporate WSUS server overrides, broken component store manifests, and lingering pending-reboot locks.

---

## 🏗️ Architecture & Script Mapping

- **Primary Coordinator**: `update_fixer/fix_windows_update.ps1`
- **Component Reset**: `update_fixer/Reset-Update-Components.ps1`
- **Pending Reboot Clear**: `update_fixer/Clear-Pending-Reboot.ps1`
- **WSUS Policy Bypass**: `update_fixer/Reset-WSUS-Policies.ps1`
- **Component Store & DISM**: `update_fixer/Repair-Component-Store.ps1`
- **Batch Launcher**: `update_fixer/Run-As-Administrator.bat`
- **Master Menu Option**: `[8]` under `[SYSTEM TUNE-UP & DEBLOAT]`
- **Universal Execution**: `irm https://toolkit.omvihub.in | iex`

---

## 🔧 Technical Repair Actions

1. **System Restore Point Safeguard**:
   - Creates a Windows System Restore Point (`BeforeWindowsUpdateRepair`) via `Checkpoint-Computer` before modifying registry or system directories.

2. **Full Update Component & Cache Reset**:
   - Stops `wuauserv`, `bits`, `cryptsvc`, `msiserver`, and `TrustedInstaller` (terminating hung processes if needed).
   - Flushes BITS queues via `bitsadmin /reset /allusers` and `Remove-BitsTransfer`.
   - Renames `C:\Windows\SoftwareDistribution` -> `SoftwareDistribution.old`.
   - Renames `C:\Windows\System32\catroot2` -> `catroot2.old`.
   - Re-registers 28 core COM libraries (including `wups2.dll`, `wuaueng.dll`, `wuapi.dll`, `wintrust.dll`).
   - Configures services to Automatic startup and starts them in dependency order.

3. **Pending Reboot Lock Clearance**:
   - Clears installer-blocking registry flags:
     - `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending`
     - `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired`
     - `HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations`
     - `HKLM:\SOFTWARE\Microsoft\ServerManager\CurrentRebootAttempts`

4. **WSUS Server Policy Bypass**:
   - Inspects `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU`.
   - Backs up registry keys to `C:\SysMaster\reports\WSUS_Policy_Backup_<Timestamp>.reg`.
   - Toggles `UseWUServer = 0` so off-premise client machines can fetch updates directly from Microsoft Update Cloud CDN.

5. **Component Store & Protected File Integrity**:
   - Executes `dism.exe /Online /Cleanup-Image /StartComponentCleanup` to reclaim superseded update disk space.
   - Executes `dism.exe /Online /Cleanup-Image /RestoreHealth` to repair corrupted component store manifests.
   - Executes `sfc /scannow` to verify and repair hash-mismatched system files.

6. **Network & Proxy Remediations**:
   - Executes `netsh winsock reset`, `ipconfig /flushdns`, and `netsh winhttp reset proxy` to fix network socket corruptions causing update timeouts (`0x8024402c`, `0x80072ee2`).

---

## 📊 Generated Reports

- **Summary Audit Report**: `C:\SysMaster\reports\WindowsUpdateFixReport.txt`
- **Execution Log**: `C:\SysMaster\reports\WindowsUpdateFix.log`
- **DISM Cleanup Log**: `C:\SysMaster\reports\DISM_Cleanup_Output.txt`
- **DISM Restore Log**: `C:\SysMaster\reports\DISM_Restore_Output.txt`
- **SFC Scan Log**: `C:\SysMaster\reports\SFC_Scan_Output.txt`
- **WSUS Registry Backup**: `C:\SysMaster\reports\WSUS_Policy_Backup_<Timestamp>.reg`
