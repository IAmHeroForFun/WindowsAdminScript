# 🏢 MS Office & Outlook Diagnostic & Repair Suite

A production-grade, highly interactive administration suite to diagnose and resolve Microsoft Office startup crashes, first-run opt-in wizard loops, licensing issues, and Outlook profile/cache corruption.

Compatible with **Office 2010 (14.0), Office 2013 (15.0), and Office 2016/2019/2021/365 (16.0)**.

---

## 🚀 Features

1. **Opt-in First-Run Experience Bypass**: Bypasses the initial update settings screens that cause immediate crashes on launch.
2. **GPU Hardware Acceleration Disable**: Applies registry configs to disable graphics acceleration, a common cause of instant launch failures.
3. **Outlook Profile & OST Cache Renamer**: Replaces corrupted offline exchange caches (`.ost`) and renames registry profiles recursively to force clean rebuilds.
4. **Credential Manager Purger**: Clears stored Office and Outlook credentials to resolve credential prompt loops.
5. **Permissions & Service Restorer**: Fixes system and administrator rights on Office folders/registry paths and repairs required services (`sppsvc`, `osppsvc`, etc.).
6. **SFC and DISM System Integration**: Runs built-in system file checks to repair core OS component corruptions.

---

## 📋 Interactive Mode (Yes/No Prompts)

This suite is fully **interactive**. Before performing any action or changing any setting, you will be prompted with a yellow message:
```text
>>> Reset Microsoft Office settings, clear caches, and backup/reset profiles?
Proceed? (Y/N)
```
- Type `Y` (or `y`) to execute the action.
- Type `N` (or `n` / press Enter) to skip the action. The script will log it as `[SKIPPED]` and continue.

---

## 🔄 Rollback Procedures

This suite is built with safety in mind. No settings or user data are permanently deleted.
- **Registry Hives**: Backups are exported as `.reg` files inside the `Logs\` directory. To restore them, double-click the corresponding `.reg` file.
- **Directories and normal templates**: Roaming/Local folders and files (like `Normal.dotm` or `*.ost`) are renamed to `*_Backup_TIMESTAMP` or `*.old`. To restore, rename them back to their original names.
- **Rollback Instruction Log**: When renames are performed, a file named `Logs\Rollback_Instructions_*.txt` is generated, summarizing exactly which files and folders were renamed so you can quickly undo the changes.

---

## 💻 Execution

### Run Locally
Right-click `Run-As-Administrator.bat` and select **Run as Administrator**.

### Web One-Liner
```powershell
irm https://toolkit.omvihub.in/office | iex
```
