# 13. Outlook PST / OST Recovery, SCANPST Locator & 100GB Expander

## 📌 Executive Summary
The **Outlook PST / OST Recovery, SCANPST Locator & 100GB Limit Expander** (`office_fixer/Repair-PST.ps1`) is a dedicated recovery and optimization tool for Microsoft Outlook data files. It solves PST file corruption, automatically discovers the appropriate `SCANPST.EXE` binary across all Office versions, scans user profiles for `.pst` and `.ost` archives, expands the 50GB file size limit to 100GB, removes accidental read-only flags, and fixes NTFS permissions.

---

## 🏗️ Architecture & Script Mapping

- **Primary Script**: `office_fixer/Repair-PST.ps1`
- **Integrated Within**: `office_fixer/Repair-Office.ps1` (as optional step)
- **Master Menu Option**: `[13]`
- **Direct Web Shortcut**: `irm https://toolkit.omvihub.in/pst | iex`

---

## 🔧 Technical Capabilities

### 1. Automated `SCANPST.EXE` Discovery Engine:
Probes all known 32-bit and 64-bit installation paths:
- `C:\Program Files\Microsoft Office\root\Office16\SCANPST.EXE` (Office 365 / 2021 / 2019 / 2016 Click-to-Run)
- `C:\Program Files (x86)\Microsoft Office\root\Office16\SCANPST.EXE`
- `C:\Program Files\Microsoft Office\Office16\SCANPST.EXE` (MSI)
- `C:\Program Files (x86)\Microsoft Office\Office16\SCANPST.EXE`
- `C:\Program Files\Microsoft Office\Office15\SCANPST.EXE` (Office 2013)
- `C:\Program Files (x86)\Microsoft Office\Office15\SCANPST.EXE`
- `C:\Program Files\Microsoft Office\Office14\SCANPST.EXE` (Office 2010)
- `C:\Program Files (x86)\Microsoft Office\Office14\SCANPST.EXE`

### 2. PST / OST File Discovery & Health Inspection:
- Scans `Documents\Outlook Files`, `%LOCALAPPDATA%\Microsoft\Outlook`, `%APPDATA%\Microsoft\Outlook`.
- Displays file size in MB/GB, last modified timestamp, and flags files approaching the 50GB limit or locked in Read-Only mode.

### 3. Expand PST File Size Ceiling (50GB $\rightarrow$ 100GB):
- Configures `HKCU:\Software\Microsoft\Office\<14.0|15.0|16.0>\Outlook\PST`:
  - `MaxLargeFileSize = 102400` (DWORD: 100 GB in MB)
  - `WarnLargeFileSize = 97280` (DWORD: 95 GB in MB)
- Prevents Outlook freezing and database corruption when a mailbox exceeds 50GB.

### 4. Read-Only & Permission Unlocker:
- Clears `ReadOnly` attribute (`attrib -r`).
- Grants Current User Full Control (`icacls <path> /grant %USERNAME%:(F)`).

### 5. Guided SCANPST Execution:
- Prompts user to select any discovered file by index or custom path.
- Launches `SCANPST.EXE` pre-pointed to that file with step-by-step backup instructions.
