# 📖 Master IT Toolkit - Comprehensive Technical Documentation Library

Welcome to the central technical documentation and reference library for the **OmviHub Windows & Windows Server Master IT Administration Toolkit**.

Every script, sub-module, and infrastructure component in the toolkit has a dedicated, production-grade guide detailing its architecture, technical registry modifications, command workflows, interactive options, reports, and rollback instructions.

---

## 🧭 Navigation & Module Guides

### 🏛️ Core Architecture & Web Bootstrapper
- [00. Master Toolkit Architecture & Console Guide](00_MASTER_TOOLKIT_ARCHITECTURE.md) - Massgrave (MAS) UI, privilege escalation, execution lifecycle, and zero-footprint cleanup.
- [16. Web Bootstrap, TLS/SSL & Nginx Deployment Guide](16_WEB_BOOTSTRAP_AND_NGINX_DEPLOYMENT.md) - Cloud proxying, User-Agent filtering, SSL certificates, and one-liner triggers.

---

### 🔍 Section 1: Audit & Inventory
- [01. Local Hardware & Installed Software Inventory Scanner](01_LOCAL_INVENTORY_SCANNER.md) - CPU, RAM, GPU, storage, motherboard, and software audit (`get_inventory.ps1`).
- [02. Network Subnet IP & Active Host Discovery (Ping Sweep)](02_NETWORK_SUBNET_DISCOVERY.md) - Multi-threaded subnet discovery, ARP table resolution, and live host tracking (`scan_network.ps1`).
- [03. Agentless Remote Network PC Inventory (WMI / CIM)](03_REMOTE_WMI_INVENTORY.md) - Domain & Workgroup agentless remote hardware/software discovery (`remote_inventory.ps1`).
- [04. Network Security, Open Port Exposure & Socket Auditor](04_NETWORK_SECURITY_AUDITOR.md) - 6-Phase network exposure analysis, DNS benchmarks, listening sockets, and latency audits (`audit_network.ps1`).

---

### ⚡ Section 2: System Tune-Up & Debloat
- [05. Sherlock Slow PC Performance Debugger & Turbo Tune-Up](05_SHERLOCK_SLOW_PC_DEBUGGER.md) - 7-Layer hardware bottleneck diagnostics, thermal throttling, disk health, and system cleanup (`slowness_detective.ps1`).
- [06. Windows Search & Indexing Repair Suite (EDB, UWP & MAPI)](06_WINDOWS_AND_OUTLOOK_SEARCH_FIXER.md) - Windows Search Service reset, EDB database wipe, Start Menu UWP re-registration, and Outlook email search repair (`fix_search.ps1` & `Fix-Outlook-Search.ps1`).
- [07. Windows 11 Enterprise Debloat & Privacy Optimizer](07_WINDOWS_11_DEBLOATER_OPTIMIZER.md) - UWP bloatware removal, diagnostic telemetry disabling, taskbar customization, and OneDrive toggles (`debloat.ps1`).

---

### 🏢 Section 3: Infrastructure & Server Administration
- [08. Server Security & Configuration Audit (GPOs, Accounts, Shares)](08_SERVER_FORENSIC_SECURITY_AUDIT.md) - Active Directory, local accounts, password age, SMB share permissions, and NTP sync audit (`audit_server.ps1`).
- [09. Local Print Spooler, Queue & Driver Manager](09_PRINTER_SPOOLER_DRIVER_MANAGER.md) - Stuck job purging, printer port TCP latency, driver isolation, and TCP/IP queue creation (`manage_printers.ps1`).
- [10. Windows 10/11 Network Folder & SMB Sharing Fixer](10_SMB_SHARE_USB_PRINTER_REPAIR.md) - Insecure guest auth, SMB client signing, Network Discovery services, Point & Print restrictions, and 0x0000011b RPC fixes (`network_sharing_fixer/`).
- [11. Remote Desktop (RDP) & CredSSP Connection Fixer](11_RDP_AND_CREDSSP_ORACLE_FIXER.md) - CredSSP Encryption Oracle remediation (`0x80004005` / `0x800706BA`), NLA configuration, and custom RDP port migration (`rdp_fixer/`).

---

### 💻 Section 4: Application & Database Suites
- [12. MS Office General Diagnostic & Configuration Reset Suite](12_MS_OFFICE_DIAGNOSTIC_REPAIR.md) - First-run opt-in bypass, hardware GPU acceleration toggle, credential purge, and licensing audit (`office_fixer/`).
- [13. Outlook PST / OST Recovery, SCANPST Locator & 100GB Expander](13_OUTLOOK_PST_RECOVERY_EXPANDER.md) - Automated `SCANPST.EXE` locator, PST discovery, 100GB registry limit expansion, and permission unlocker (`Repair-PST.ps1`).
- [14. SQL Database Port & Protocol Diagnostic Fixer (1433, 3306, 5432)](14_SQL_DATABASE_PORT_PROTOCOL_FIXER.md) - SQL Server Browser activation, TCP/IP protocol registry repair, and database firewall rules (`sql_database_fixer/`).
- [15. Windows Defender Signature Reset & Exclusion Engine](15_WINDOWS_DEFENDER_EXCLUSION_ENGINE.md) - Definition purge via `MpCmdRun.exe`, signature updates, path exclusions, and `root\SecurityCenter2` WMI checks (`antivirus_fixer/`).

---

## ⚡ Direct Web Shortcuts Quick Matrix

| Target Tool | Web One-Liner Command |
| :--- | :--- |
| **Master IT Toolkit** | `irm https://toolkit.omvihub.in \| iex` |
| **PST Repair & 100GB Expander** | `irm https://toolkit.omvihub.in/pst \| iex` |
| **Windows & Outlook Search Fixer** | `irm https://toolkit.omvihub.in/search \| iex` |
| **MS Office Repair Suite** | `irm https://toolkit.omvihub.in/office \| iex` |
| **Network Security Auditor** | `irm https://toolkit.omvihub.in/netaudit \| iex` |
| **SMB & Printer Sharing Fixer** | `irm https://toolkit.omvihub.in/sharing \| iex` |
| **SQL & Database Protocol Fixer** | `irm https://toolkit.omvihub.in/sql \| iex` |
| **Remote Desktop (RDP) Fixer** | `irm https://toolkit.omvihub.in/rdp \| iex` |
| **Windows Defender Reset Suite** | `irm https://toolkit.omvihub.in/defender \| iex` |
| **Windows 11 Debloater Suite** | `irm https://toolkit.omvihub.in/debloat \| iex` |
| **Sherlock Slow PC Debugger** | `irm https://toolkit.omvihub.in/slowness \| iex` |
| **Print Spooler Manager** | `irm https://toolkit.omvihub.in/printer \| iex` |
| **Hardware Inventory Scanner** | `irm https://toolkit.omvihub.in/inventory \| iex` |
