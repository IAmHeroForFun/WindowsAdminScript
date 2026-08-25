# 00. Master IT Toolkit Architecture & Console Guide

## 📌 Executive Summary
The **OmviHub Windows & Windows Server Master IT Administration Toolkit** is an enterprise-grade administration console designed to unify diagnostics, hardware audits, protocol repairs, security hardening, and performance tune-ups across all supported versions of Microsoft Windows.

It features the **Massgrave (MAS) Minimalist High-Contrast UI**, native execution policy bypasses, automated elevation detection, and a zero-footprint self-cleaning mechanism upon exit while preserving generated audit reports.

---

## 🏗️ Architecture & Component Hierarchy

```text
Repository Root /
├── windows_it_toolkit.ps1         # Main Interactive Master Menu Coordinator
├── Windows_IT_Toolkit.bat         # Native Windows Batch Elevation Wrapper
├── install.ps1                    # Cloud Web Bootstrapper & Tool Dispatcher
├── toolkit.conf                   # Nginx Reverse Proxy & User-Agent Router
├── inventory/                     # Local, Subnet, and Remote Inventory Modules
├── network_auditor/               # 6-Phase Socket & Port Security Suite
├── slowness_debug/                # 7-Layer PC Performance Profiler
├── search_fixer/                  # Windows & Outlook MAPI Indexing Engine
├── win11_debloater/               # Safe Windows 11 Enterprise Debloater
├── server_audit/                  # Server Configuration & Forensic Auditor
├── printer_manager/               # Print Spooler, Ports & Driver Manager
├── network_sharing_fixer/         # Windows 10/11 SMB & USB Printer Sharing
├── rdp_fixer/                     # RDP & CredSSP Oracle Connection Fixer
├── office_fixer/                  # MS Office Diagnostics & PST Recovery Suite
├── sql_database_fixer/            # Database Ports & MSSQL Protocol Fixer
├── antivirus_fixer/               # Defender Definition Reset & Exclusion Suite
└── guides/                        # Technical Documentation Library
```

---

## ⚡ Execution Methods

### 1. Web One-Liner (Cloud In-Memory Bootstrap)
```powershell
irm https://toolkit.omvihub.in | iex
```

### 2. Local Right-Click Run
Right-click `Windows_IT_Toolkit.bat` and select **Run as administrator**.

### 3. Native PowerShell Console
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows_it_toolkit.ps1
```

---

## 🛡️ Core Capabilities & Safety Principles

1. **Privilege Awareness**:
   The header dynamically queries the current Windows Security Token via `[Security.Principal.WindowsPrincipal]` to display whether the console is running with `Elevated / Administrator` rights or `Standard User`.

2. **PowerShell 2.0 to 7+ Backward Compatibility**:
   Every script defines `$PSScriptRoot` fallbacks (`Split-Path -Parent $MyInvocation.MyCommand.Definition`) ensuring flawless execution on legacy Windows 7 / Server 2008 R2 machines with default PowerShell 2.0 runtimes.

3. **Centralized Report Preservation (`C:\SysMaster\reports\`)**:
   All diagnostic reports, inventory CSVs, security audits, and registry backups are written to a centralized, permanent reports directory (`C:\SysMaster\reports\` or local `reports\`).

4. **Zero-Footprint Auto-Cleanup on Exit**:
   When the user exits via `Q` or `q`, the toolkit cleanly wipes temporary script files (`.ps1`, `.bat`, `.cmd`, `.md`, `.conf`) and removes empty staging directories, leaving only the generated reports in `C:\SysMaster\reports\`.

5. **Granular Q-Exit & Cancel Controls**:
   Every interactive sub-script implements `Get-UserApproval` with `(Y/N, Q to Cancel)`. Typing `Q` at any prompt immediately halts the sub-routine and returns cleanly to the Master Menu.
