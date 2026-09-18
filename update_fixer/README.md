# 🔄 Windows Update, WSUS & Component Store Repair Suite

A production-grade, interactive administration suite to diagnose and resolve Windows Update failures, stuck download/install loops, corrupted component stores, locked BITS queues, WSUS policy overrides, and lingering pending-reboot flags across Windows 7–11 and Windows Server 2008 R2–2025.

---

## 🚀 Solved Errors & Issues

| Error Code | Common Cause | Solved By |
| :--- | :--- | :--- |
| `0x80070002` / `0x80070003` | Missing or corrupted files in `SoftwareDistribution` | Full cache wipe & rebuild (`Reset-Update-Components.ps1`) |
| `0x8024402f` / `0x8024401c` | WSUS server unreachable / off-premise client | Bypass WSUS via `UseWUServer = 0` (`Reset-WSUS-Policies.ps1`) |
| `0x80070422` | Windows Update service disabled or hung | Service startup set to Automatic & restarted |
| `0x800f081f` / `0x800f0906` | Component Store corruption / missing manifest | DISM `/RestoreHealth` & `/StartComponentCleanup` |
| `0x80240034` | Download stalled / orphaned BITS background jobs | BITS queue flush via `bitsadmin /reset /allusers` |
| `0x8024402c` / `0x80072ee2` | Network proxy misconfiguration / socket timeout | WinSock reset & `netsh winhttp reset proxy` |
| **Pending Reboot Lock** | Installer error: "Another installation is in progress" | Clears CBS & Windows Update reboot flags (`Clear-Pending-Reboot.ps1`) |

---

## 🏗️ Architecture & Sub-Modules

```text
update_fixer/
├── fix_windows_update.ps1         # Main interactive coordinator (Phase 1-5)
├── Reset-Update-Components.ps1    # Halts services, renames caches, resets BITS, re-registers DLLs
├── Clear-Pending-Reboot.ps1       # Clears stuck CBS, WindowsUpdate, & PendingFileRename locks
├── Reset-WSUS-Policies.ps1        # Inspects & toggles corporate WSUS vs Microsoft Cloud CDN
├── Repair-Component-Store.ps1     # Executes DISM cleanup, health restore, and SFC scan
└── Run-As-Administrator.bat       # Self-elevating double-click wrapper
```

---

## 📋 Interactive Approval Engine

Every repair phase prompts the administrator with explicit confirmation before modifying services or registry entries:
```text
>>> Execute Full Windows Update Component & Cache Reset (SoftwareDistribution, catroot2, BITS)?
Proceed? (Y/N, Q to Cancel)
```
- Enter `Y` to execute the phase.
- Enter `N` (or press Enter) to skip safely.
- Enter `Q` at any prompt to immediately halt execution and return cleanly to the Master Menu.

---

## 💻 Execution

### Run Locally (Standalone)
Right-click `Run-As-Administrator.bat` and select **Run as Administrator**.

### Run via Master IT Toolkit
Launch the Master Console and select Option `[8]` under `[SYSTEM TUNE-UP & DEBLOAT]`:
```powershell
irm https://toolkit.omvihub.in | iex
```
