# 🛠️ Windows & Windows Server IT Administration Toolkit

A modular, enterprise-grade collection of portable Windows and Windows Server administration, forensic diagnostic, and automation tools. Engineered for 100% compatibility across Windows 7–11 and Windows Server 2008 R2–2025. Every suite is contained inside its own dedicated subdirectory with its own batch launchers, documentation, and forensic report directories.

---

## 📂 Repository Structure

```text
D:\projects\script\
│
├── README.md                          # Master directory index
├── Windows_IT_Toolkit.bat             # 🌟 Master Interactive Menu Launcher (Double-Click)
├── windows_it_toolkit.ps1             # Central menu interface connecting all 10 suites
│
└── inventory/                         # 💻 Windows Hardware & Software Inventory Tool
    ├── README.md                      # Detailed suite documentation
    ├── run_inventory.bat              # Run locally on any PC (No Admin Required)
    ├── run_network_scan.bat           # Run subnet scan to discover active IPs
    ├── run_remote_inventory.bat       # Query remote PCs over WMI (Admin Required)
    ├── get_inventory.ps1              # Local hardware/software scan logic
    ├── scan_network.ps1               # Network discovery scan logic
    ├── remote_inventory.ps1           # Remote WMI network inventory logic
    ├── inventory.csv                  # Consolidated spreadsheet of all PCs
    ├── backups/                       # Automatic timestamped pre-run backups
    └── installed_software/            # Detailed installed app text reports

└── slowness_debug/                    # 🕵️‍♂️ Sherlock Slow: Fun PC Performance Profiler
    ├── README.md                      # Diagnostic tool documentation
    ├── run_slowness_detective.bat     # Run interactive slowness audit & tune-up
    ├── slowness_detective.ps1         # Real-time CPU, RAM, Disk, Uptime profiler
    └── reports/                       # Generated diagnostic prescription files

└── search_fixer/                      # 🔍 Windows Search & Indexing Repair Suite
    ├── README.md                      # Search repair tool documentation
    ├── run_search_fixer.bat           # Run interactive search & indexing fix
    └── fix_search.ps1                 # WSearch service, database rebuild & UWP repair

└── server_audit/                      # 🏛️ Main Server Forensic & Configuration Auditor
    ├── README.md                      # Server audit documentation
    ├── run_server_audit.bat           # Run extraction of server configurations
    ├── audit_server.ps1               # Extracts Users, GPOs, Shares, Services & Tasks
    └── reports/                       # Generated spreadsheets and GPO web reports

└── server_health_doctor/              # 🩺 Windows Server Health & Misconfiguration Doctor
    ├── README.md                      # Server doctor documentation
    ├── run_server_doctor.bat          # Run server fault scan
    ├── server_doctor.ps1              # Scans DNS, Time, Firewall, Disk & Crash logs
    └── reports/                       # Generated health case files

└── crash_and_error_detective/         # 🛑 Server Crash, Reboot & Error Forensic Detective
    ├── README.md                      # Crash detective documentation
    ├── run_crash_detective.bat        # Run crash & error extraction
    ├── crash_detective.ps1            # Scans shutdowns, BSODs, recurring errors & live KB links
    └── reports/                       # Generated CSV spreadsheets & interactive HTML web report

└── deep_infrastructure_audit/         # 🔐 Ultimate Deep Infrastructure & Security Diagnostic Suite
    ├── README.md                      # Deep infrastructure documentation
    ├── run_deep_diagnostic.bat        # Run 360-degree infrastructure scan
    ├── deep_diagnostic.ps1            # Scans AD replication, SSL certs, SMBv1, listening ports & reboots
    └── reports/                       # Generated port maps and certificate CSVs

└── enterprise_security_auditor/       # 🛡️ Enterprise Security, Compliance & Recovery Auditor [Option 10]
    ├── README.md                      # Complete enterprise MSP assessment documentation
    ├── run_enterprise_security_auditor.bat # Run comprehensive audit scan
    ├── enterprise_security_auditor.ps1# 360-degree security, patch, backup, disk & network scoring engine
    └── reports/                       # 6 CSV data sheets, audit.log & dark-mode HTML executive dashboard

└── network_mapper/                    # 🌐 Advanced Network Mapper & Topology Discovery Tool [Option 11]
    ├── README.md                      # SolarWinds & PRTG-inspired topology scanner documentation
    ├── run_network_mapper.bat         # Launch multi-threaded subnet discovery scan
    ├── network_mapper.ps1             # Async ICMP sweep, MAC OUI vendor lookup, OS fingerprinting & port scanner
    └── reports/                       # CSV spreadsheet, JSON topology & interactive HTML visual network diagram

└── uptime_monitor/                    # ⏱️ NOC Uptime & Availability Monitoring Platform [Option 12]
    ├── README.md                      # Uptime Kuma & PRTG-style SLA monitor documentation
    ├── run_uptime_monitor.bat         # Execute real-time availability check
    ├── uptime_monitor.ps1             # Monitors Internet, Gateway, DNS, DCs, SMB, Web & VPN with latency/loss tracking
    └── reports/                       # history.json, CSV log & Daily/Weekly/Monthly/Master HTML availability dashboards

└── client_health_report/              # 💼 MSP One-Click Client Health Report Generator [Option 13]
    ├── README.md                      # Boardroom & CEO executive health assessment documentation
    ├── run_client_health_report.bat   # Generate executive 360-degree client health deliverable
    ├── generate_report.ps1            # Audits server health, storage, VSS, security, patching & certs with 0-100 Score
    └── reports/                       # Print-to-PDF boardroom HTML report (@media print) & itemized findings CSV

└── msp_platform/                      # 🏛️ Complete Self-Hosted MSP Monitoring & Reporting Platform [Option 14]
    ├── README.md                      # Lansweeper, PRTG, NinjaOne & OpManager alternative documentation
    ├── run_msp_platform.bat           # Launch 10-module enterprise IT management ecosystem
    ├── msp_platform.ps1               # 10 core modules, 3 KPI risk scoring engines, scheduled task & email alerting
    └── reports/                       # Master Command Center HTML dashboard, historical trend JSON/CSV & risk logs
```

---

## 🚀 Adding New Automation Scripts

When building additional tools or scripts in this workspace, follow this standard modular layout:
1. Create a dedicated folder under the root directory (e.g., `user_management/`, `backup_automation/`, `network_audit/`).
2. Include double-click `.bat` wrappers with `-ExecutionPolicy Bypass` enabled so administrators can execute scripts without manual PowerShell policy configuration.
3. Keep output files, backups, and documentation isolated within that tool's subfolder using relative pathing (`$PSScriptRoot`).
