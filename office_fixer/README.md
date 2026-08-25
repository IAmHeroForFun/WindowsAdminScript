# 🏢 MS Office & Outlook Diagnostic & Repair Suite

A production-grade, highly interactive administration suite to diagnose and resolve Microsoft Office startup crashes, first-run opt-in wizard loops, licensing issues, and Outlook profile/cache corruption.

Compatible with **Office 2010 (14.0), Office 2013 (15.0), and Office 2016/2019/2021/365 (16.0)**.

---

## 🚀 Features

1. **Opt-in First-Run Experience Bypass**: Bypasses the initial update settings screens that cause immediate crashes on launch.
2. **GPU Hardware Acceleration Disable**: Applies registry configs to disable graphics acceleration, a common cause of instant launch failures.
3. **Outlook PST & OST Auto-Recovery**:
   - **Automated SCANPST Locator**: Discovers Microsoft Outlook Inbox Repair Tool (`SCANPST.EXE`) across 32-bit & 64-bit Office 2010 to 365 paths.
   - **PST Discovery**: Finds all `.pst` and `.ost` files across user profiles and displays sizes and status.
   - **100GB Limit Expander**: Configures `MaxLargeFileSize` (100GB) and `WarnLargeFileSize` (95GB) in the registry.
   - **PST Permission / Read-Only Unlocker**: Clears read-only file attributes (`attrib -r`) and restores NTFS ACL permissions.
4. **Outlook Profile & OST Cache Renamer**: Replaces corrupted offline exchange caches (`.ost`) and renames registry profiles recursively to force clean rebuilds.
5. **Credential Manager Purger**: Clears stored Office and Outlook credentials to resolve credential prompt loops.
6. **Permissions & Service Restorer**: Fixes system and administrator rights on Office folders/registry paths and repairs required services (`sppsvc`, `osppsvc`, etc.).
7. **SFC and DISM System Integration**: Runs built-in system file checks to repair core OS component corruptions.

---

## 📋 Interactive Mode (Yes/No Prompts)

This suite is fully **interactive**. Before performing any action or changing any setting, you will be prompted with a yellow message:
```text
>>> Reset Microsoft Office settings, clear caches, and backup/reset profiles?
Proceed? (Y/N, Q to Cancel)
```
- Type `Y` (or `y`) to execute the action.
- Type `N` (or `n` / press Enter) to skip the action.
- Type `Q` (or `q`) to cancel and return to the main menu.

---

## 💻 Execution

### Run Locally
Right-click `Run-As-Administrator.bat` and select **Run as Administrator**.

### Web One-Liners
```powershell
# MS Office Diagnostic & Repair Suite
irm https://toolkit.omvihub.in/office | iex

# Outlook PST Recovery & 100GB Limit Expander
irm https://toolkit.omvihub.in/pst | iex
```
