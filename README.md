# 🛠️ IT Administration Script Suite

A modular collection of portable Windows administration and automation tools. Every suite is contained inside its own dedicated subdirectory with its own batch launchers, documentation, output files, and automatic backup directories.

---

## 📂 Repository Structure

```text
D:\projects\script\
│
├── README.md                          # Master directory index
├── run_it_toolkit.bat                 # 🌟 Master Interactive Menu Launcher (Double-Click)
├── it_toolkit_menu.ps1                # Central menu interface connecting all suites
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
```

---

## 🚀 Adding New Automation Scripts

When building additional tools or scripts in this workspace, follow this standard modular layout:
1. Create a dedicated folder under the root directory (e.g., `user_management/`, `backup_automation/`, `network_audit/`).
2. Include double-click `.bat` wrappers with `-ExecutionPolicy Bypass` enabled so administrators can execute scripts without manual PowerShell policy configuration.
3. Keep output files, backups, and documentation isolated within that tool's subfolder using relative pathing (`$PSScriptRoot`).
