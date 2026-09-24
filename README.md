# 🛠️ OmviHub Windows & Windows Server Master IT Administration Toolkit

[![PowerShell Version](https://img.shields.io/badge/PowerShell-2.0%20to%207.5%2B-blue.svg)](https://microsoft.com/powershell)
[![Platform](https://img.shields.io/badge/Platform-Windows%207--11%20%7C%20Server%202008%20R2--2025-0078D6.svg)](https://microsoft.com/windows)
[![Architecture](https://img.shields.io/badge/Architecture-x86%20%7C%20x64%20%7C%20ARM64-lightgrey.svg)](#)
[![Zero Footprint](https://img.shields.io/badge/Self--Cleaning-Zero%20Footprint-success.svg)](#)
[![Deployment](https://img.shields.io/badge/Cloud%20One--Liner-Active-brightgreen.svg)](#)

A production-grade, enterprise administration, forensic diagnostic, and automation suite engineered for Windows and Windows Server environments. Designed for 100% cross-generational compatibility across desktop and server operating systems, it unifies **17 operational administration suites** under a minimalist, high-contrast, keyboard-driven console interface inspired by Microsoft Massgrave (MAS).

---

## ⚡ Quick Start: Universal Execution Modes

### 🌐 Mode 1: Cloud In-Memory Execution (Single Universal One-Liner)
Open Windows PowerShell (Run as Administrator) and execute:

```powershell
irm https://toolkit.omvihub.in | iex
```

- **In-Memory Streaming**: The bootstrapper is served dynamically via the AWS Lightsail Nginx proxy directly from the GitHub repository.
- **Auto-Elevation**: Automatically requests Administrator privileges via native Windows UAC if launched as a standard user.
- **Zero-Footprint Cleanup**: When you exit via `[Q]`, temporary scripts, loaders, and markdowns are cleanly erased.
- **Permanent Data Preservation**: All generated spreadsheets (`inventory.csv`), diagnostic prescription files, and forensic logs are permanently preserved under `C:\SysMaster\reports\`.

### 💻 Mode 2: Local GUI Double-Click Launch
1. Clone or download the repository.
2. Right-click **`Windows_IT_Toolkit.bat`** and select **Run as administrator**.

### ⌨️ Mode 3: Native PowerShell Terminal Launch
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows_it_toolkit.ps1
```

---

## 🧭 Master Console Interface (v2.7)

```text
==========================================================================
 :: OmviHub Windows & Windows Server Master IT Toolkit (v2.7)
 :: Host: WORKSTATION-01 | OS: Microsoft Windows 11 Enterprise
 :: User: Administrator | Privileges: Elevated / Administrator
==========================================================================

 [AUDIT & INVENTORY]
  [1]  Local Hardware & Installed Software Inventory Scanner
  [2]  Local Network Subnet IP & Active Host Discovery (Ping Sweep)
  [3]  Agentless Remote Network PC Inventory (WMI / CIM)
  [4]  Network Security, Open Port Exposure & Socket Auditor (6-Phases)
  [5]  Shared Folder & NTFS Permissions Auditor (SMB / ACLs / Risks)

 [SYSTEM TUNE-UP & DEBLOAT]
  [6]  Sherlock Slow PC Performance Debugger & Turbo Tune-Up
  [7]  Windows Search & Indexing Repair Suite (EDB, UWP & MAPI)
  [8]  Windows 11 Enterprise Debloat & Privacy Optimizer
  [9]  Windows Update, WSUS & Component Store (DISM/CBS) Repair Suite

 [INFRASTRUCTURE & SERVER ADMIN]
  [10] Server Security & Configuration Audit (GPOs, Accounts, Shares)
  [11] Local Print Spooler, Queue & Driver Manager
  [12] Windows 10/11 Network Folder & SMB Sharing Fixer
  [13] Remote Desktop (RDP) & CredSSP Connection Fixer

 [APPLICATION & DATABASE SUITES]
  [14] MS Office General Diagnostic & Configuration Reset Suite
  [15] Outlook PST / OST Recovery, SCANPST Locator & 100GB Expander
  [16] SQL Database Port & Protocol Diagnostic Fixer (1433, 3306, 5432)
  [17] Windows Defender Signature Reset & Exclusion Engine
--------------------------------------------------------------------------
  [Q]  Exit Toolkit
==========================================================================
```

---

## 🔍 Comprehensive Suite Catalog (All 17 Tools)

### 💻 Section 1: Audit & Inventory

#### 1. Local Hardware & Software Inventory Scanner
- **Primary Script**: `inventory/get_inventory.ps1`
- **Launcher**: `inventory/run_inventory.bat`
- **Documentation**: [Guide 01: Local Inventory Scanner](guides/01_LOCAL_INVENTORY_SCANNER.md)
- **Capabilities**:
  - Gathers Motherboard, CPU (Cores/Threads/Clock), RAM modules (Speed/Slot count), Storage drives (SSD/NVMe/HDD health & model), GPU, BIOS Serial, and Chassis form-factor (Desktop, Laptop, Server).
  - Normalizes and sanitizes all system strings with carriage-return stripping to prevent CSV cell corruption.
  - Automatically updates or appends to a consolidated `inventory.csv` asset spreadsheet.
  - Exports a detailed timestamped text inventory of all installed software (32-bit, 64-bit, and UWP) to `installed_software\<ComputerName>_software.txt`.
  - Creates automatic timestamped backups before each scan in `backups\`.

#### 2. Local Network Subnet IP & Active Host Discovery
- **Primary Script**: `inventory/scan_network.ps1`
- **Launcher**: `inventory/run_network_scan.bat`
- **Documentation**: [Guide 02: Network Subnet Discovery](guides/02_NETWORK_SUBNET_DISCOVERY.md)
- **Capabilities**:
  - Detects active local network adapter and calculates the local `/24` IPv4 subnet mask automatically.
  - Executes a multi-threaded asynchronous ICMP ping sweep across 254 subnet addresses in under 15 seconds.
  - Resolves network NetBIOS/DNS hostnames and maps hardware MAC addresses from the ARP cache table.
  - Displays colorized terminal table of online endpoints and offers export to CSV.

#### 3. Agentless Remote Network PC Inventory (WMI / CIM)
- **Primary Script**: `inventory/remote_inventory.ps1`
- **Launcher**: `inventory/run_remote_inventory.bat`
- **Documentation**: [Guide 03: Remote WMI Inventory](guides/03_REMOTE_WMI_INVENTORY.md)
- **Capabilities**:
  - Scans remote machines across Workgroups or Active Directory domains over WMI/DCOM without client software agents.
  - Supports custom administrative credentials (`PSCredential`) or pass-through Kerberos domain tokens.
  - Extracts full hardware specifications and software lists remotely, consolidating data into the master `inventory.csv`.

#### 4. Network Security, Open Port Exposure & Socket Auditor
- **Primary Script**: `network_auditor/audit_network.ps1`
- **Launcher**: `network_auditor/run_network_audit.bat`
- **Documentation**: [Guide 04: Network Security Auditor](guides/04_NETWORK_SECURITY_AUDITOR.md)
- **Capabilities**:
  - **6-Phase Security Analysis**:
    1. Audits all active listening TCP and UDP sockets mapped to executable process IDs.
    2. Runs heuristic safety classification, flagging risky open ports (e.g. Telnet 23, SMB 445, RDP 3389, VNC 5900).
    3. Resolves external Public IP and checks for carrier-grade NAT.
    4. Benchmarks primary DNS server latency against Cloudflare (1.1.1.1) and Google (8.8.8.8).
    5. Audits Default Gateway latency and ARP spoofing indicators.
    6. Interactive Firewall remediation: prompts administrator to immediately block exposed vulnerable ports.
    7. Quick Network Remediation: 1-click universal network stack reset (Winsock, TCP/IP, ARP, DNS, DHCP) and local subnet duplicate IP address conflict detection (Event 4199 & ARP audit).
- **Output**: `C:\SysMaster\reports\network_security_report_<ComputerName>.csv`, `subnet_scan_*.csv`, and `network_diagnostics_*.txt`

#### 5. Windows Shared Folder & NTFS Permissions Auditor
- **Primary Script**: `inventory/audit_folder_permissions.ps1`
- **Launcher**: `inventory/run_folder_permissions.bat`
- **Capabilities**:
  - Standalone script designed for easy download and execution on any Windows Server (2008 R2 to 2025) or client workstation (Windows 7 to 11).
  - **Dual-Layer Audit Engine**: Gathers both SMB Share-level permissions (`Get-SmbShareAccess` / `Win32_LogicalShareSecuritySetting`) and underlying NTFS filesystem ACLs (`Get-Acl`).
  - **Flexible Scope Modes**: (1) Auto-discovers all active SMB shares (excluding admin shares `C$`, `ADMIN$`, `IPC$`), (2) Audits custom directory path, (3) Scans root directories across all local fixed drives.
  - **Defensive Identity Translation**: Safely translates SIDs to user/group account names with fallback handling for orphaned or deleted domain accounts.
  - **Heuristic Risk Detection**: Flags open `Everyone` access with modify/full rights, explicit `Deny` rules, and unresolved orphaned SIDs.
  - **Sanitized Dual CSV Export**: Strips trailing newlines to prevent Excel column distortion, exporting to both consolidated `folder_permissions.csv` and timestamped `folder_permissions_<ComputerName>_<Timestamp>.csv`.
- **Output**: `inventory\reports\folder_permissions.csv` and `inventory\reports\folder_permissions_<ComputerName>_<Timestamp>.csv`

---

### ⚡ Section 2: System Tune-Up & Debloat

#### 6. Sherlock Slow PC Performance Debugger & Turbo Tune-Up
- **Primary Script**: `slowness_debug/slowness_detective.ps1`
- **Launcher**: `slowness_debug/run_slowness_detective.bat`
- **Documentation**: [Guide 05: Sherlock Slow PC Debugger](guides/05_SHERLOCK_SLOW_PC_DEBUGGER.md)
- **Capabilities**:
  - **Multi-Layer Bottleneck Profiler**:
    1. Real-time CPU hogs and **PROCHOT Thermal / Power Throttling detection** (identifies if CPU clock is clamped at 0.79 GHz).
    2. **WMI Provider Host (`WmiPrvSE.exe`) Tracer** (pinpoints rogue client processes triggering excessive WMI CPU spikes).
    3. Memory pressure, paging file exhaustion, and leaking process identification.
    4. **Storage Response Latency & Queue Depth Audit** (detects disk freezes >50ms response times on HDDs/SSDs).
    5. System uptime evaluation (flags machines running continuously for >7 days without reboot) and pending update reboots.
    6. Startup programs analysis and background bloat score (0–100 health index).
    7. Power plan audit (prompts to switch to High Performance / Ultimate Performance).
    8. Granular interactive tune-up: User-approved temporary file purging, Delivery Optimization cache cleaning, and Recycle Bin purge.
- **Output**: `C:\SysMaster\reports\Sherlock_Report_<ComputerName>_<Timestamp>.txt`

#### 7. Windows Search & Indexing Repair Suite
- **Primary Script**: `search_fixer/fix_search.ps1`
- **Outlook Module**: `search_fixer/Fix-Outlook-Search.ps1`
- **Launcher**: `search_fixer/run_search_fixer.bat`
- **Documentation**: [Guide 06: Search & Indexing Fixer](guides/06_WINDOWS_AND_OUTLOOK_SEARCH_FIXER.md)
- **Capabilities**:
  - Inspects `WSearch` service and checks `Windows.edb` database size (flags bloat >2 GB).
  - Terminates hung indexer threads, wipes corrupted `.edb` files, and forces a clean index rebuild.
  - Re-registers modern Windows 10/11 Search UI and Start Menu UWP packages (`Microsoft.Windows.Search`).
  - Disables Bing web search lag to prioritize immediate local file results.
  - Fixes Outlook MAPI search policies (`EnableSearchIndexMapi = 1`) and registers `.pst`/`.ost` persistent IFilter handlers.

#### 8. Windows 11 Enterprise Debloat & Privacy Optimizer
- **Primary Script**: `win11_debloater/debloat.ps1`
- **Launcher**: `win11_debloater/run_debloater.bat`
- **Documentation**: [Guide 07: Windows 11 Debloater](guides/07_WINDOWS_11_DEBLOATER_OPTIMIZER.md)
- **Capabilities**:
  - Uninstalls sponsored bloatware and pre-installed consumer applications (TikTok, Spotify, Disney+, Xbox, Cortana).
  - Disables telemetry, diagnostic tracking services (`DiagTrack`, `dmwappushservice`), and feedback reminders.
  - Cleans Windows 11 Taskbar by hiding Widgets, Chat (Teams), and Cortana icons.
  - Disables OneDrive auto-start and background sync telemetry with admin confirmation.

#### 9. Windows Update, WSUS & Component Store Repair Suite
- **Primary Coordinator**: `update_fixer/fix_windows_update.ps1`
- **Sub-modules**:
  - `update_fixer/Reset-Update-Components.ps1`: Stops services, flushes caches, resets BITS queue, re-registers COM DLLs.
  - `update_fixer/Clear-Pending-Reboot.ps1`: Clears stuck `RebootPending` and `PendingFileRenameOperations` locks.
  - `update_fixer/Reset-WSUS-Policies.ps1`: Toggles `UseWUServer = 0` to bypass unreachable internal WSUS servers.
  - `update_fixer/Repair-Component-Store.ps1`: Executes DISM `/StartComponentCleanup`, `/RestoreHealth`, and `sfc /scannow`.
- **Launcher**: `update_fixer/Run-As-Administrator.bat`
- **Documentation**: [Guide 17: Windows Update & WSUS Fixer](guides/17_WINDOWS_UPDATE_AND_WSUS_FIXER.md)
- **Capabilities**:
  - Solves errors `0x80070002`, `0x8024402f`, `0x80070422`, `0x800f081f`, `0x80240034`, `0x8024402c`, `0x80072ee2`.
  - Resets `SoftwareDistribution` and `catroot2` caches safely without reboot.
  - Flushes BITS transfer queue and clears stuck background download jobs.
  - Clears lingering installer-blocking reboot flags in registry.
  - Flushes WinSock sockets, DNS cache, and resets WinHTTP proxy.
- **Output**: `C:\SysMaster\reports\WindowsUpdateFixReport.txt` and `WindowsUpdateFix.log`

---

### 🏢 Section 3: Infrastructure & Server Administration

#### 10. Server Security & Configuration Audit
- **Primary Script**: `server_audit/audit_server.ps1`
- **Launcher**: `server_audit/run_server_audit.bat`
- **Documentation**: [Guide 08: Server Forensic Security Audit](guides/08_SERVER_FORENSIC_SECURITY_AUDIT.md)
- **Capabilities**:
  - Audits Local and Active Directory user accounts, password age, `PasswordNeverExpires` flags, and stale accounts (>90 days).
  - Enumerates members of privileged groups (`Domain Admins`, `Enterprise Admins`, `Administrators`, `Remote Desktop Users`).
  - Audits all SMB file shares (`Win32_Share`), flagging dangerous permissions (`Everyone` with Full Control).
  - Checks Active Directory FSMO roles (`netdom query fsmo`), domain controller health, and NTP time drift via `w32tm`.
  - Audits Windows Server Backup (`wbadmin`) and VSS shadow storage allocations.
- **Output**: `server_audit_report_<PC>_<Timestamp>.txt`, `server_users_<PC>.csv`, `server_shares_<PC>.csv`

#### 11. Local Print Spooler, Queue & Driver Manager
- **Primary Script**: `printer_manager/manage_printers.ps1`
- **Launcher**: `printer_manager/run_printer_manager.bat`
- **Documentation**: [Guide 09: Print Spooler Manager](guides/09_PRINTER_SPOOLER_DRIVER_MANAGER.md)
- **Capabilities**:
  - Hard purge of stuck, orphaned print spool jobs, clearing dead spooler files (`.SHD` and `.SPL`).
  - Terminates hung driver isolation processes (`PrintIsolationHost.exe`) and cleanly restarts `Spooler`.
  - Audits network printer ports, testing TCP port 9100 and ping latency to identify offline physical printers.
  - Fleet inventory scan with Windows Protected Print (WPP) assessment and driver model (Type 3 vs Type 4) classification.
  - Multi-layer shared printer UNC target diagnostic (`\\HOST\Printer` testing DNS, TCP 445 SMB, TCP 135 RPC, and SMB share namespace).
  - Inspects `Microsoft-Windows-PrintService/Admin` event logs and decodes Win32 error codes (`0x11b`, `0x709`, `0xbc4`, `0x7c`, Error 5).
  - Enables Print Driver Isolation to prevent buggy vendor drivers from crashing the spooler service.
  - Removes stale, orphaned printer ports and uninstalled printer queues.
  - Creates Standard TCP/IP network printer ports and queues via command line.
- **Output**: `C:\SysMaster\reports\printer_inventory.csv` and `printer_path_test_<Timestamp>.txt`

#### 12. Windows 10/11 Network Folder & SMB Sharing Fixer
- **Primary Coordinator**: `network_sharing_fixer/fix_sharing.ps1`
- **Sub-modules**:
  - `Fix-SMB-Shares.ps1`: Remediates insecure guest authentication and SMB signing.
  - `Fix-Shared-Printers.ps1`: Role-based printer repair engine (Host vs Client vs Universal vs Local Port workaround).
  - `Reset-Network-Sharing-Firewall.ps1`: Unblocks File/Printer Sharing and WSD Discovery rules.
- **Dedicated Launchers**:
  - `1_RUN_ON_HOST_PC (Printer Attached).bat` (Fixes 0x0000011b, Public network, firewall, discovery)
  - `2_RUN_ON_CLIENT_PC (Connect Over Network).bat` (Fixes 0x00000bc4, 0x00000709, 0x00000bcb, 24H2 WPP)
  - `3_UNIVERSAL_ALL_IN_ONE_FIX.bat` (Applies all Host & Client remediations)
  - `4_CONNECT_VIA_LOCAL_PORT (Guaranteed Workaround).bat` (100% Guaranteed Local Port Workaround)
  - `Run-As-Administrator.bat` (Master self-elevating launcher)
- **Documentation**: [Guide 10: SMB & USB Printer Sharing](guides/10_SMB_SHARE_USB_PRINTER_REPAIR.md)
- **Capabilities**:
  - **Explicit Role Distinction**: Explains whether to run on Host (printer attached) or Client (connecting workstation) to eliminate configuration mistakes.
  - **Windows 10 to 10 Diagnosis**: Switches network from Public to Private, resolves password-protected sharing mismatches, and starts discovery services.
  - Fixes Windows 10/11 USB shared printer connection failure `0x0000011b` (`RpcAuthnLevelPrivacyEnabled = 0` on Host).
  - Fixes Windows 11 "No printers were found" error `0x00000bc4` and `0x00000709` (`RpcUseNamedPipeProtocol = 1`, `RpcProtocols = 7` on Client).
  - Disables Windows 11 24H2 Windows Protected Print (WPP) to allow legacy Type 3 (v3) vendor drivers to run.
  - Relaxes Windows 11 24H2 mandatory SMB Client signing (`RequireSecuritySignature = False`).
  - **Automated Local Port Workaround**: Connects via `\\Host\PrinterShare` Local Port with local driver — completely bypasses Spooler RPC and Point & Print bugs with a 100% success rate!
  - Sets `AllowInsecureGuestAuth = 1` and `RequireSecuritySignature = 0` to restore connectivity to legacy NAS appliances.
  - Configures `DisableStrictNameChecking = 1` and `DnsOnWire = 1` to enable connecting to file shares via DNS CNAME aliases.
  - Active Directory Domain GPO lock guard to prevent silent domain policy reverts.
- **Output**: `C:\SysMaster\reports\SharingFixReport.txt` and `SharingFix.log`

#### 13. Remote Desktop (RDP) & CredSSP Connection Fixer
- **Primary Coordinator**: `rdp_fixer/fix_rdp.ps1`
- **Sub-modules**:
  - `Fix-CredSSP-Oracle.ps1`: Configures CredSSP Encryption Oracle Remediation.
  - `Enable-RDP-Service.ps1`: Enables RDP service, NLA, and firewall rules.
  - `Fix-RDP-UDP-Freeze.ps1`: Fixes Windows 11 RDP session freezes/disconnects by enforcing reliable TCP transport (`fClientDisableUDP = 1`).
  - `Fix-RDP-BlackScreen.ps1`: Resolves black screens upon connection by forcing legacy XDDM display driver (`fEnableWddmDriver = 0`).
  - `Configure-RDP-Port.ps1`: Inspects and migrates default RDP listening port.
- **Launcher**: `rdp_fixer/Run-As-Administrator.bat`
- **Documentation**: [Guide 11: RDP & CredSSP Oracle Fixer](guides/11_RDP_AND_CREDSSP_ORACLE_FIXER.md)
- **Capabilities**:
  - Remediates CredSSP Encryption Oracle Remediation error (`0x800706BA` / `0x80090308`) by setting `AllowEncryptionOracle = 2` (Mitigated mode).
  - Unblocks disabled Remote Desktop services by configuring `fDenyTSConnections = 0`.
  - Fixes Windows 11 22H2/23H2 RDP UDP freezing and disconnect bugs (`fClientDisableUDP = 1`).
  - Fixes black screen connection hangs caused by buggy GPU/WDDM drivers (`fEnableWddmDriver = 0`).
  - Interactive pre-flight target reachability probe (tests remote IP/hostname and TCP port connectivity).
  - Automatically enables all inbound Windows Defender Firewall rules for Remote Desktop.
  - Allows inspecting and changing the default RDP port (`3389`) to any custom port, creating the required firewall rules automatically.
- **Output**: `C:\SysMaster\reports\RdpFixReport.txt` and `RdpFix.log`

---

### 💻 Section 4: Application & Database Suites

#### 14. MS Office General Diagnostic & Configuration Reset Suite
- **Primary Coordinator**: `office_fixer/Repair-Office.ps1`
- **Sub-modules**:
  - `Install-Dependencies.ps1`: Checks .NET Framework and Visual C++ runtimes.
  - `Check-Services.ps1`: Audits Office licensing and click-to-run background services.
  - `Fix-Permissions.ps1`: Restores ACL permissions on Office registry hives and folders.
  - `Reset-Office.ps1`: Resets first-run opt-ins, purges cache, and disables GPU hardware acceleration.
  - `Export-Activation.ps1`: Queries `ospp.vbs` licensing status and product keys.
  - `Collect-Logs.ps1`: Extracts Office event logs from Application and System logs.
- **Launcher**: `office_fixer/Run-As-Administrator.bat`
- **Documentation**: [Guide 12: MS Office Diagnostic Repair](guides/12_MS_OFFICE_DIAGNOSTIC_REPAIR.md)
- **Capabilities**:
  - Detects Microsoft Office 2010 through Office 365 (32-bit and 64-bit).
  - Solves launch freezes and white screen crashes by disabling hardware GPU acceleration in registry.
  - Clears first-run opt-in popups (`OptIn = 0`) across all Office applications.
  - Re-applies NTFS and registry permissions across `HKLM:\SOFTWARE\Microsoft\Office`.
  - Automates system image repair (`DISM /RestoreHealth` and `SFC /scannow`).
- **Output**: `C:\SysMaster\reports\RepairReport.txt` and `Repair.log`

#### 15. Outlook PST / OST Recovery, SCANPST Locator & 100GB Expander
- **Primary Script**: `office_fixer/Repair-PST.ps1`
- **Documentation**: [Guide 13: Outlook PST Recovery & Expander](guides/13_OUTLOOK_PST_RECOVERY_EXPANDER.md)
- **Capabilities**:
  - Automatically crawls all local hard drives to discover every `.pst` and `.ost` file on the system.
  - Dynamically searches all Office installation directories to find the exact matching version of `SCANPST.EXE`.
  - Expands the default Microsoft Outlook 50GB file limit to **100GB** in the registry (`MaxLargeFileSize` and `WarnLargeFileSize`).
  - Removes read-only file attributes and resets NTFS permissions on locked data files.
- **Output**: `C:\SysMaster\reports\PST_Repair_Report.txt` and `PST_Repair.log`

#### 16. SQL Database Port & Protocol Diagnostic Fixer
- **Primary Coordinator**: `sql_database_fixer/fix_sql.ps1`
- **Sub-modules**:
  - `Audit-SQL-Connectivity.ps1`: Tests local port bindings across 6 database engines.
  - `Fix-MSSQL-Services-Protocols.ps1`: Starts SQL Browser service and enables TCP/IP protocol.
  - `Fix-SQL-Firewall-Ports.ps1`: Unblocks firewall rules for all major database ports.
- **Launcher**: `sql_database_fixer/Run-As-Administrator.bat`
- **Documentation**: [Guide 14: SQL Database Port Protocol Fixer](guides/14_SQL_DATABASE_PORT_PROTOCOL_FIXER.md)
- **Supported Databases & Ports**:
  - Microsoft SQL Server (`1433` TCP, `1434` UDP)
  - MySQL / MariaDB (`3306` TCP)
  - PostgreSQL (`5432` TCP)
  - Oracle Database (`1521` TCP)
  - MongoDB (`27017` TCP)
  - Redis (`6379` TCP)
- **Capabilities**:
  - Inspects MSSQL registry to ensure `TcpDynamicPorts` and `TcpPort` are enabled.
  - Unblocks inbound firewall rules for seamless remote database connectivity.
- **Output**: `C:\SysMaster\reports\SqlFixReport.txt` and `SqlFix.log`

#### 17. Windows Defender Signature Reset & Exclusion Engine
- **Primary Coordinator**: `antivirus_fixer/fix_antivirus.ps1`
- **Sub-modules**:
  - `Test-Defender-Cloud-Connectivity.ps1`: Tests reachability to Microsoft Defender Cloud Protection and SmartScreen endpoints.
  - `Reset-Defender-Definitions.ps1`: Flushes definition database via `MpCmdRun.exe` and downloads latest updates.
  - `Manage-Defender-Exclusions.ps1`: Interactive prompt to view, add, and audit folder/process exclusions.
  - `Repair-Security-Center-WMI.ps1`: Audits and repairs `root\SecurityCenter2` WMI repository.
- **Launcher**: `antivirus_fixer/Run-As-Administrator.bat`
- **Documentation**: [Guide 15: Windows Defender Exclusion Engine](guides/15_WINDOWS_DEFENDER_EXCLUSION_ENGINE.md)
- **Capabilities**:
  - Tamper Protection state audit (checks if kernel tamper locking is active before attempting modifications).
  - Tests Defender Cloud Protection HTTPS connectivity (`wdcp.microsoft.com`, `smartscreen.microsoft.com`).
  - Flushes corrupted definition stores via `MpCmdRun.exe -RemoveDefinitions -All`.
  - Forces immediate signature update from Microsoft Security Intelligence.
  - Audits configured Attack Surface Reduction (ASR) enterprise rules.
  - Audits registered antivirus products via WMI to detect conflicting third-party security engines.
- **Output**: `C:\SysMaster\reports\AntivirusFixReport.txt` and `AntivirusFix.log`

---

## 📂 Complete Repository File Tree (All 83 Files)

```text
WindowsAdminScript/
│
├── README.md                                          # Master repository documentation (this file)
├── WEB_BOOTSTRAP_GUIDE.md                             # Guide for AWS Lightsail Nginx deployment
├── toolkit.conf                                       # High-performance Nginx reverse proxy configuration
├── install.ps1                                        # Universal cloud web bootstrapper (irm | iex)
├── Windows_IT_Toolkit.bat                             # Master interactive double-click batch launcher
├── windows_it_toolkit.ps1                             # Central Massgrave console coordinator (v2.7)
│
├── inventory/                                         # 💻 Section 1: Hardware & Software Inventory
│   ├── README.md                                      # Inventory suite documentation
│   ├── get_inventory.ps1                              # Tool 1: Local hardware/software scan logic
│   ├── scan_network.ps1                               # Tool 2: Local subnet ping sweep logic
│   ├── remote_inventory.ps1                           # Tool 3: Agentless remote WMI inventory logic
│   ├── audit_folder_permissions.ps1                   # Tool 5: Shared folder & NTFS permissions audit logic
│   ├── run_inventory.bat                              # Standalone local inventory batch launcher
│   ├── run_network_scan.bat                           # Standalone subnet scan batch launcher
│   ├── run_remote_inventory.bat                       # Standalone remote inventory batch launcher
│   └── run_folder_permissions.bat                     # Standalone folder permissions batch launcher
│
├── network_auditor/                                   # 🌐 Section 1: Network Security & Port Auditor
│   ├── README.md                                      # Network auditor documentation
│   ├── audit_network.ps1                              # Tool 4: 6-Phase socket & firewall auditor
│   └── run_network_audit.bat                          # Standalone network audit batch launcher
│
├── slowness_debug/                                    # 🕵️‍♂️ Section 2: Sherlock Slow PC Debugger
│   ├── README.md                                      # Sherlock slow debugger documentation
│   ├── slowness_detective.ps1                         # Tool 6: 7-layer PC performance profiler
│   └── run_slowness_detective.bat                     # Standalone slowness detective launcher
│
├── search_fixer/                                      # 🔍 Section 2: Windows & Outlook Search Repair
│   ├── README.md                                      # Search repair documentation
│   ├── fix_search.ps1                                 # Tool 7: Windows.edb purge & UWP package repair
│   ├── Fix-Outlook-Search.ps1                         # Outlook MAPI search & IFilter handler repair
│   └── run_search_fixer.bat                           # Standalone search fixer batch launcher
│
├── win11_debloater/                                   # 🚀 Section 2: Windows 11 Debloat & Privacy
│   ├── README.md                                      # Debloater suite documentation
│   ├── debloat.ps1                                    # Tool 8: Bloatware uninstaller & privacy tweaks
│   └── run_debloater.bat                              # Standalone debloater batch launcher
│
├── update_fixer/                                      # 🔄 Section 2: Windows Update & Component Fixer
│   ├── README.md                                      # Update fixer suite documentation
│   ├── fix_windows_update.ps1                         # Tool 9: Main coordinator with pre-flight check
│   ├── Reset-Update-Components.ps1                    # SoftwareDistribution & catroot2 cache reset
│   ├── Clear-Pending-Reboot.ps1                       # Stuck CBS & WindowsUpdate reboot flag clear
│   ├── Reset-WSUS-Policies.ps1                        # Corporate WSUS bypass & CDN toggle
│   ├── Repair-Component-Store.ps1                     # DISM /StartComponentCleanup & /RestoreHealth
│   └── Run-As-Administrator.bat                       # Self-elevating batch launcher
│
├── server_audit/                                      # 🏛️ Section 3: Server Forensic Security Auditor
│   ├── README.md                                      # Server audit documentation
│   ├── audit_server.ps1                               # Tool 10: Users, GPOs, shares, FSMO & NTP audit
│   └── run_server_audit.bat                           # Standalone server audit batch launcher
│
├── printer_manager/                                   # 🖨️ Section 3: Print Spooler & Driver Manager
│   ├── README.md                                      # Printer manager documentation
│   ├── manage_printers.ps1                            # Tool 11: Spool purge, latency & driver isolation
│   └── run_printer_manager.bat                        # Standalone printer manager batch launcher
│
├── network_sharing_fixer/                             # 📂 Section 3: SMB & USB Printer Sharing Repair
│   ├── README.md                                      # Sharing repair documentation
│   ├── fix_sharing.ps1                                # Tool 12: Main SMB and printer sharing coordinator
│   ├── Fix-SMB-Shares.ps1                             # Guest auth, SMB signing & CNAME fixes
│   ├── Fix-Shared-Printers.ps1                        # Role-based printer fixer (Host/Client/Workaround)
│   ├── Reset-Network-Sharing-Firewall.ps1             # Firewall rules for sharing & WSD discovery
│   ├── 1_RUN_ON_HOST_PC (Printer Attached).bat        # Host PC 1-click batch launcher
│   ├── 2_RUN_ON_CLIENT_PC (Connect Over Network).bat  # Client PC 1-click batch launcher
│   ├── 3_UNIVERSAL_ALL_IN_ONE_FIX.bat                 # Universal all-in-one batch launcher
│   ├── 4_CONNECT_VIA_LOCAL_PORT (Guaranteed Workaround).bat # Local port workaround batch launcher
│   └── Run-As-Administrator.bat                       # Master self-elevating batch launcher
│
├── rdp_fixer/                                         # 🔑 Section 3: Remote Desktop & CredSSP Repair
│   ├── README.md                                      # RDP fixer documentation
│   ├── fix_rdp.ps1                                    # Tool 13: Main RDP coordinator
│   ├── Fix-CredSSP-Oracle.ps1                         # CredSSP encryption remediation (0x800706BA)
│   ├── Enable-RDP-Service.ps1                         # Unblocks RDP service and firewall rules
│   ├── Configure-RDP-Port.ps1                         # Custom RDP port manager
│   └── Run-As-Administrator.bat                       # Self-elevating batch launcher
│
├── office_fixer/                                      # 📑 Section 4: MS Office & PST Recovery Suite
│   ├── README.md                                      # Office suite documentation
│   ├── Repair-Office.ps1                              # Tool 14: Office diagnostic, reset & repair
│   ├── Repair-PST.ps1                                 # Tool 15: SCANPST locator & 100GB limit expander
│   ├── Check-Services.ps1                             # Office licensing and service audit
│   ├── Fix-Permissions.ps1                            # Registry & folder ACL repair
│   ├── Reset-Office.ps1                               # First-run opt-in, cache & GPU acceleration
│   ├── Export-Activation.ps1                          # Office licensing status query
│   ├── Collect-Logs.ps1                               # Event Viewer diagnostic log collector
│   ├── Install-Dependencies.ps1                       # Visual C++ and .NET Framework checks
│   └── Run-As-Administrator.bat                       # Self-elevating batch launcher
│
├── sql_database_fixer/                                # 🗄️ Section 4: SQL Database Protocol Fixer
│   ├── README.md                                      # SQL database fixer documentation
│   ├── fix_sql.ps1                                    # Tool 16: Main database fixer coordinator
│   ├── Audit-SQL-Connectivity.ps1                     # Port connectivity tester across 6 DB engines
│   ├── Fix-MSSQL-Services-Protocols.ps1               # SQL Browser & TCP/IP protocol enable
│   ├── Fix-SQL-Firewall-Ports.ps1                     # Unblocks 1433, 1434, 3306, 5432, 1521, 27017
│   └── Run-As-Administrator.bat                       # Self-elevating batch launcher
│
├── antivirus_fixer/                                   # 🛡️ Section 4: Windows Defender Reset Suite
│   ├── README.md                                      # Defender suite documentation
│   ├── fix_antivirus.ps1                              # Tool 17: Main Defender coordinator
│   ├── Reset-Defender-Definitions.ps1                 # MpCmdRun.exe definition flush & update
│   ├── Manage-Defender-Exclusions.ps1                 # Folder and process exclusion manager
│   ├── Repair-Security-Center-WMI.ps1                 # root\SecurityCenter2 WMI repository audit
│   └── Run-As-Administrator.bat                       # Self-elevating batch launcher
│
└── guides/                                            # 📖 Master Technical Documentation Library
    ├── README.md                                      # Central library navigation index
    ├── 00_MASTER_TOOLKIT_ARCHITECTURE.md              # 00: Architecture & console guide
    ├── 01_LOCAL_INVENTORY_SCANNER.md                  # 01: Hardware & software inventory
    ├── 02_NETWORK_SUBNET_DISCOVERY.md                 # 02: Network subnet ping sweep
    ├── 03_REMOTE_WMI_INVENTORY.md                     # 03: Remote agentless WMI inventory
    ├── 04_NETWORK_SECURITY_AUDITOR.md                 # 04: Socket & port security audit
    ├── 05_SHERLOCK_SLOW_PC_DEBUGGER.md                # 05: PC slowness diagnostic & tune-up
    ├── 06_WINDOWS_AND_OUTLOOK_SEARCH_FIXER.md         # 06: Search & indexing repair
    ├── 07_WINDOWS_11_DEBLOATER_OPTIMIZER.md           # 07: Windows 11 debloater & privacy
    ├── 08_SERVER_FORENSIC_SECURITY_AUDIT.md           # 08: Server configuration & GPO audit
    ├── 09_PRINTER_SPOOLER_DRIVER_MANAGER.md           # 09: Print spooler & queue management
    ├── 10_SMB_SHARE_USB_PRINTER_REPAIR.md             # 10: SMB shares & USB printer repair
    ├── 11_RDP_AND_CREDSSP_ORACLE_FIXER.md             # 11: RDP & CredSSP Oracle repair
    ├── 12_MS_OFFICE_DIAGNOSTIC_REPAIR.md              # 12: MS Office repair suite
    ├── 13_OUTLOOK_PST_RECOVERY_EXPANDER.md            # 13: Outlook PST recovery & 100GB limit
    ├── 14_SQL_DATABASE_PORT_PROTOCOL_FIXER.md         # 14: SQL database port & protocol repair
    ├── 15_WINDOWS_DEFENDER_EXCLUSION_ENGINE.md        # 15: Windows Defender reset & exclusions
    ├── 16_WEB_BOOTSTRAP_AND_NGINX_DEPLOYMENT.md       # 16: Cloud proxy & deployment guide
    └── 17_WINDOWS_UPDATE_AND_WSUS_FIXER.md            # 17: Windows Update & WSUS repair
```

---

## 📖 Master Technical Documentation Library Matrix

Each suite in the toolkit is paired with a dedicated technical guide detailing its internal mechanics, registry keys, commands, and rollback instructions:

| Guide # | Document | Target Domain | Core Focus |
| :---: | :--- | :--- | :--- |
| **00** | [00. Master Toolkit Architecture & Console Guide](guides/00_MASTER_TOOLKIT_ARCHITECTURE.md) | Core Engine | Massgrave console UI, lifecycle, privilege token detection, zero-footprint self-cleaning. |
| **01** | [01. Local Hardware & Software Inventory Scanner](guides/01_LOCAL_INVENTORY_SCANNER.md) | Audit & Inventory | Hardware specs, string normalization, `inventory.csv`, installed software text reports. |
| **02** | [02. Network Subnet IP & Active Host Discovery](guides/02_NETWORK_SUBNET_DISCOVERY.md) | Audit & Inventory | Asynchronous ICMP ping sweep, NetBIOS resolution, ARP table MAC discovery. |
| **03** | [03. Agentless Remote Network PC Inventory](guides/03_REMOTE_WMI_INVENTORY.md) | Audit & Inventory | Remote WMI/CIM over DCOM, domain/workgroup credentials, zero-agent asset discovery. |
| **04** | [04. Network Security & Port Exposure Auditor](guides/04_NETWORK_SECURITY_AUDITOR.md) | Audit & Inventory | 6-Phase socket scanner, heuristic risk rating, DNS benchmark, firewall port closing. |
| **05** | [05. Sherlock Slow PC Performance Debugger](guides/05_SHERLOCK_SLOW_PC_DEBUGGER.md) | System Tune-Up | 7-Layer profiler, thermal throttling, uptime warnings, SSD TRIM, temp cleanup. |
| **06** | [06. Windows Search & Indexing Repair Suite](guides/06_WINDOWS_AND_OUTLOOK_SEARCH_FIXER.md) | System Tune-Up | `Windows.edb` wipe, UWP Start Menu packages, Bing search lag disable, Outlook MAPI index. |
| **07** | [07. Windows 11 Enterprise Debloat & Privacy Optimizer](guides/07_WINDOWS_11_DEBLOATER_OPTIMIZER.md) | System Tune-Up | Sponsored app removal, `DiagTrack` disabling, taskbar customization, OneDrive control. |
| **08** | [08. Server Security & Configuration Audit](guides/08_SERVER_FORENSIC_SECURITY_AUDIT.md) | Server Admin | Accounts, password age, stale accounts (>90 days), SMB shares, FSMO roles, NTP sync. |
| **09** | [09. Local Print Spooler, Queue & Driver Manager](guides/09_PRINTER_SPOOLER_DRIVER_MANAGER.md) | Server Admin | Stuck spool purging, driver isolation, port latency checks, TCP/IP queue creation. |
| **10** | [10. SMB Share & USB Shared Printer Repair](guides/10_SMB_SHARE_USB_PRINTER_REPAIR.md) | Infrastructure | Guest auth, SMB signing, CNAME alias, RPC `0x0000011b`, Point & Print restrictions. |
| **11** | [11. Remote Desktop (RDP) & CredSSP Oracle Fixer](guides/11_RDP_AND_CREDSSP_ORACLE_FIXER.md) | Infrastructure | CredSSP remediation (`0x800706BA`), `fDenyTSConnections`, firewall, custom RDP ports. |
| **12** | [12. MS Office General Diagnostic & Repair Suite](guides/12_MS_OFFICE_DIAGNOSTIC_REPAIR.md) | Applications | Office 2010–365, first-run opt-ins, GPU acceleration toggle, ACL repair, SFC & DISM. |
| **13** | [13. Outlook PST Recovery & 100GB Expander](guides/13_OUTLOOK_PST_RECOVERY_EXPANDER.md) | Applications | `SCANPST.EXE` locator, `.pst`/`.ost` drive crawl, 100GB registry limit expansion. |
| **14** | [14. SQL Database Port & Protocol Fixer](guides/14_SQL_DATABASE_PORT_PROTOCOL_FIXER.md) | Databases | SQL Server Browser (1434 UDP), MSSQL (1433), MySQL (3306), Postgres (5432), Redis. |
| **15** | [15. Windows Defender Signature Reset & Exclusions](guides/15_WINDOWS_DEFENDER_EXCLUSION_ENGINE.md) | Security | `MpCmdRun.exe` definition flush, updates, folder/process exclusions, `SecurityCenter2`. |
| **16** | [16. Web Bootstrap, TLS & Nginx Deployment Guide](guides/16_WEB_BOOTSTRAP_AND_NGINX_DEPLOYMENT.md) | Deployment | AWS Lightsail Nginx proxy, SSL setup, User-Agent filtering, single one-liner workflow. |
| **17** | [17. Windows Update, WSUS & Component Store Repair](guides/17_WINDOWS_UPDATE_AND_WSUS_FIXER.md) | System Tune-Up | `SoftwareDistribution` reset, BITS flush, pending reboot clearance, WSUS bypass, DISM. |

---

## 🌐 Cloud Bootstrapper & Reverse Proxy Architecture

```mermaid
sequenceDiagram
    autonumber
    actor Admin as SysAdmin (Windows PC)
    participant Nginx as Nginx Proxy (toolkit.omvihub.in)
    participant GitHub as GitHub Raw (IAmHeroForFun/WindowsAdminScript)
    participant Client as Local Machine (C:\SysMaster)

    Admin->>Nginx: irm https://toolkit.omvihub.in | iex
    Note over Nginx: Inspects User-Agent header (PowerShell/curl)
    Nginx->>GitHub: GET /master/install.ps1
    GitHub-->>Nginx: Returns install.ps1 raw code
    Nginx-->>Admin: Streams bootstrapper payload in-memory
    Admin->>Client: install.ps1 executes
    Note over Client: Evaluates UAC; prompts elevation if needed<br/>Enforces TLS 1.2/1.3 security protocols<br/>Downloads repo archive to C:\SysMaster<br/>Preserves historical reports & CSV data<br/>Unblocks modules & launches windows_it_toolkit.ps1
    Admin->>Client: Executes administrative suites (1-17)
    Note over Client: Writes all outputs to C:\SysMaster\reports\
    Admin->>Client: Exits via [Q]
    Note over Client: Cleans up temporary scripts (.ps1, .bat, .md)<br/>Retains 100% of generated reports!
```

---

## 🛡️ Enterprise Safety & Data Preservation Engine

1. **Local Developer Workspace Protection**:
   The post-execution cleanup routine in `windows_it_toolkit.ps1` and `install.ps1` automatically detects whether it is running inside a `.git` repository clone. If a `.git` folder exists, **the cleanup routine will abort immediately**, ensuring local source files are never deleted during development.
2. **Dynamic UAC Privilege Awareness**:
   Every script evaluates the calling Windows Security Token (`[Security.Principal.WindowsPrincipal]`). If elevated permissions are required, scripts seamlessly elevate via `Start-Process powershell.exe -Verb RunAs`.
3. **Pre-Flight Rollback Backups**:
   Before modifying system states, suites offer automated safeguards:
   - System Restore Points via `Checkpoint-Computer`.
   - Registry export backups (`.reg` files) saved directly to the reports directory.
   - Automatic pre-run backups of `inventory.csv` before each audit run.
4. **Permanent Report Centralization**:
   All diagnostic prescriptions, audit logs, and hardware inventories are stored permanently under **`C:\SysMaster\reports\`** (or local `reports\` when run standalone). The bootstrapper update engine strictly preserves all `.csv`, `.json`, `.log`, and `.txt` files across updates.
5. **Universal Granular Approval**:
   All interactive repair subroutines implement `Get-UserApproval` with `(Y/N, Q to Cancel)`. Entering `Q` at any prompt immediately halts the action and returns cleanly to the Master Menu.
