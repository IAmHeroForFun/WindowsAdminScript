# 🛠️ Windows & Windows Server IT Administration Toolkit

A modular, enterprise-grade collection of portable Windows and Windows Server administration, forensic diagnostic, and automation tools. Engineered for 100% compatibility across Windows 7–11 and Windows Server 2008 R2–2025 (PowerShell 2.0 to 7+).

Every suite is contained inside its own dedicated subdirectory with standalone batch launchers, comprehensive documentation, and isolated or centralized forensic report storage.

---

## ⚡ Instant Cloud Execution (Single One-Liner)

Run this universal command in an elevated PowerShell prompt to automatically deploy and launch the Master Console:

```powershell
irm https://toolkit.omvihub.in | iex
```

- **Zero-Footprint**: Script files are automatically cleaned up on exit.
- **Data Preservation**: Historical reports, CSV logs, and inventory data under `C:\SysMaster\reports\` are 100% preserved.
- **Auto UAC Elevation**: Automatically prompts for Administrator privileges if executed standard.

---

## 🧭 Master Menu & Suites Overview

The toolkit organizes **16 enterprise tools** across 4 operational domains:

```text
==========================================================================
 :: OmviHub Windows & Windows Server Master IT Toolkit (v2.6)
==========================================================================

 [AUDIT & INVENTORY]
  [1]  Local Hardware & Installed Software Inventory Scanner
  [2]  Local Network Subnet IP & Active Host Discovery (Ping Sweep)
  [3]  Agentless Remote Network PC Inventory (WMI / CIM)
  [4]  Network Security, Open Port Exposure & Socket Auditor (6-Phases)

 [SYSTEM TUNE-UP & DEBLOAT]
  [5]  Sherlock Slow PC Performance Debugger & Turbo Tune-Up
  [6]  Windows Search & Indexing Repair Suite (EDB, UWP & MAPI)
  [7]  Windows 11 Enterprise Debloat & Privacy Optimizer
  [8]  Windows Update, WSUS & Component Store (DISM/CBS) Repair Suite

 [INFRASTRUCTURE & SERVER ADMIN]
  [9]  Server Security & Configuration Audit (GPOs, Accounts, Shares)
  [10] Local Print Spooler, Queue & Driver Manager
  [11] Windows 10/11 Network Folder & SMB Sharing Fixer
  [12] Remote Desktop (RDP) & CredSSP Connection Fixer

 [APPLICATION & DATABASE SUITES]
  [13] MS Office General Diagnostic & Configuration Reset Suite
  [14] Outlook PST / OST Recovery, SCANPST Locator & 100GB Expander
  [15] SQL Database Port & Protocol Diagnostic Fixer (1433, 3306, 5432)
  [16] Windows Defender Signature Reset & Exclusion Engine
--------------------------------------------------------------------------
  [Q]  Exit Toolkit
==========================================================================
```

---

## 📂 Repository Structure

```text
WindowsAdminScript/
│
├── README.md                          # Master project documentation
├── WEB_BOOTSTRAP_GUIDE.md             # Guide for deploying via AWS Lightsail Nginx & GitHub
├── toolkit.conf                       # Simplified Nginx reverse proxy configuration
├── install.ps1                        # Massgrave-style Web Bootstrapper (irm | iex)
├── Windows_IT_Toolkit.bat             # Master Interactive Menu Launcher (Double-Click)
├── windows_it_toolkit.ps1             # Central Massgrave console connecting all 16 tools
│
├── inventory/                         # 💻 Hardware & Software Inventory Scanner (Tools 1, 2, 3)
│   ├── README.md                      # Suite documentation
│   ├── get_inventory.ps1              # Local hardware/software scan logic
│   ├── scan_network.ps1               # Subnet IP & ARP ping sweep logic
│   ├── remote_inventory.ps1           # Remote WMI/CIM network inventory logic
│   └── *.bat                          # Individual double-click launchers
│
├── network_auditor/                   # 🌐 Network Security & Port Exposure Auditor (Tool 4)
│   ├── README.md                      # Suite documentation
│   ├── audit_network.ps1              # 6-phase socket, DNS, ARP & firewall auditor
│   └── run_network_audit.bat          # Double-click launcher
│
├── slowness_debug/                    # 🕵️‍♂️ Sherlock Slow PC Debugger & Turbo Tune-Up (Tool 5)
│   ├── README.md                      # Suite documentation
│   ├── slowness_detective.ps1         # 7-layer CPU, RAM, Disk, Uptime profiler & optimizer
│   └── run_slowness_detective.bat     # Double-click launcher
│
├── search_fixer/                      # 🔍 Windows & Outlook Search Repair Suite (Tool 6)
│   ├── README.md                      # Suite documentation
│   ├── fix_search.ps1                 # WSearch service, Windows.edb purge & UWP repair
│   ├── Fix-Outlook-Search.ps1         # Outlook MAPI Search & IFilter repair
│   └── run_search_fixer.bat           # Double-click launcher
│
├── win11_debloater/                   # 🚀 Windows 11 Enterprise Debloater & Privacy (Tool 7)
│   ├── README.md                      # Suite documentation
│   ├── debloat.ps1                    # Bloatware uninstaller, telemetry & taskbar optimizer
│   └── run_debloater.bat              # Double-click launcher
│
├── update_fixer/                      # 🔄 Windows Update & Component Store Fixer (Tool 8)
│   ├── README.md                      # Suite documentation
│   ├── fix_windows_update.ps1         # Main update repair coordinator
│   ├── Reset-Update-Components.ps1    # SoftwareDistribution/catroot2 purge & BITS reset
│   ├── Clear-Pending-Reboot.ps1       # Clears stuck CBS & WindowsUpdate reboot flags
│   ├── Reset-WSUS-Policies.ps1        # WSUS policy bypass & Microsoft CDN toggle
│   ├── Repair-Component-Store.ps1     # DISM component cleanup, restore & SFC scan
│   └── Run-As-Administrator.bat       # Double-click launcher
│
├── server_audit/                      # 🏛️ Server Forensic & Configuration Auditor (Tool 9)
│   ├── README.md                      # Suite documentation
│   ├── audit_server.ps1               # Users, GPOs, Shares, Services & NTP audit
│   └── run_server_audit.bat           # Double-click launcher
│
├── printer_manager/                   # 🖨️ Print Spooler, Queue & Driver Manager (Tool 10)
│   ├── README.md                      # Suite documentation
│   ├── manage_printers.ps1            # Stuck queue purge, driver isolation & TCP ports
│   └── run_printer_manager.bat        # Double-click launcher
│
├── network_sharing_fixer/             # 📂 Windows 10/11 SMB & USB Printer Sharing (Tool 11)
│   ├── README.md                      # Suite documentation
│   ├── fix_sharing.ps1                # Main SMB & printer sharing coordinator
│   ├── Fix-SMB-Shares.ps1             # Guest auth, SMB signing & CNAME fixes
│   ├── Fix-Shared-Printers.ps1        # RPC 0x0000011b, Point & Print, driver blocklist
│   ├── Reset-Network-Sharing-Firewall.ps1 # Firewall rules for sharing & WSD
│   └── Run-As-Administrator.bat       # Double-click launcher
│
├── rdp_fixer/                         # 🔑 Remote Desktop & CredSSP Oracle Repair (Tool 12)
│   ├── README.md                      # Suite documentation
│   ├── fix_rdp.ps1                    # Main RDP coordinator
│   ├── Fix-CredSSP-Oracle.ps1         # CredSSP remediation (0x800706BA)
│   ├── Enable-RDP-Service.ps1         # Unblocks RDP service & firewall
│   ├── Configure-RDP-Port.ps1         # Custom RDP port manager
│   └── Run-As-Administrator.bat       # Double-click launcher
│
├── office_fixer/                      # 📑 MS Office & Outlook PST Recovery Suite (Tools 13, 14)
│   ├── README.md                      # Suite documentation
│   ├── Repair-Office.ps1              # Office 2010–365 diagnostics, reset & repair
│   ├── Repair-PST.ps1                 # SCANPST locator & 100GB limit expander
│   ├── Check-Services.ps1             # Office licensing & service audit
│   ├── Fix-Permissions.ps1            # Registry & folder ACL repair
│   ├── Reset-Office.ps1               # Cache, first-run opt-in & GPU acceleration
│   ├── Export-Activation.ps1          # Office licensing status audit
│   ├── Collect-Logs.ps1               # Diagnostics & Event Viewer log collector
│   ├── Install-Dependencies.ps1       # VC++ runtime & .NET check
│   └── Run-As-Administrator.bat       # Double-click launcher
│
├── sql_database_fixer/                # 🗄️ SQL Database Port & Protocol Fixer (Tool 15)
│   ├── README.md                      # Suite documentation
│   ├── fix_sql.ps1                    # Main database fixer coordinator
│   ├── Fix-MSSQL-Services-Protocols.ps1 # SQL Browser & TCP/IP protocol enable
│   ├── Fix-SQL-Firewall-Ports.ps1     # Unblocks 1433, 1434, 3306, 5432, 1521, 27017
│   ├── Audit-SQL-Connectivity.ps1     # Database port connectivity tester
│   └── Run-As-Administrator.bat       # Double-click launcher
│
├── antivirus_fixer/                   # 🛡️ Windows Defender Reset & Exclusions (Tool 16)
│   ├── README.md                      # Suite documentation
│   ├── fix_antivirus.ps1              # Main Defender coordinator
│   ├── Reset-Defender-Definitions.ps1 # MpCmdRun.exe definition wipe & update
│   ├── Manage-Defender-Exclusions.ps1 # Path & process exclusion manager
│   ├── Repair-Security-Center-WMI.ps1 # root\SecurityCenter2 WMI audit
│   └── Run-As-Administrator.bat       # Double-click launcher
│
└── guides/                            # 📖 Master Technical Documentation Library
    ├── README.md                      # Navigation index for all 17 guides
    └── 00_*.md to 17_*.md             # Complete architectural and technical reference manuals
```

---

## 🛡️ Core Architectural Principles

1. **Privilege Awareness**: Automatically evaluates the calling process token; requests elevation via UAC when required.
2. **Local Workspace Safety**: Post-execution cleanup routines strictly verify that the current directory is not a `.git` workspace, preventing any accidental deletion during local development.
3. **PowerShell 2.0 to 7+ Backward Compatibility**: Universal `$PSScriptRoot` resolution enables execution from legacy Windows 7 / Server 2008 R2 through Windows 11 and Server 2025.
4. **Permanent Report Centralization**: All diagnostics, hardware logs, and audits are written to `C:\SysMaster\reports\` (or local `reports\` when run standalone) and are never purged on update or exit.
