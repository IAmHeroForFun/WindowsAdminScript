# 🛠️ Windows & Windows Server IT Administration Toolkit

A modular, enterprise-grade collection of portable Windows and Windows Server administration, forensic diagnostic, and automation tools. Engineered for 100% compatibility across Windows 7–11 and Windows Server 2008 R2–2025. Every suite is contained inside its own dedicated subdirectory with its own batch launchers, documentation, and forensic report directories.

---

## 📂 Repository Structure

```text
D:\projects\script\
│
├── README.md                          # Master directory index
├── WEB_BOOTSTRAP_GUIDE.md             # 🌐 Guide for deploying via AWS Lightsail Nginx & GitHub
├── install.ps1                        # 🌟 Massgrave-style 2-Stage Web Bootstrapper (irm | iex)
├── Windows_IT_Toolkit.bat             # 🌟 Master Interactive Menu Launcher (Double-Click)
├── windows_it_toolkit.ps1             # Central menu interface connecting all 6 tools
│
├── inventory/                         # 💻 Windows Hardware & Software Inventory Tool
│   ├── README.md                      # Detailed suite documentation
│   ├── run_inventory.bat              # Run locally on any PC (No Admin Required)
│   ├── run_network_scan.bat           # Run subnet scan to discover active IPs
│   ├── run_remote_inventory.bat       # Query remote PCs over WMI (Admin Required)
│   ├── get_inventory.ps1              # Local hardware/software scan logic
│   ├── scan_network.ps1               # Network discovery scan logic
│   ├── remote_inventory.ps1           # Remote WMI network inventory logic
│   ├── inventory.csv                  # Consolidated spreadsheet of all PCs
│   ├── backups/                       # Automatic timestamped pre-run backups
│   └── installed_software/            # Detailed installed app text reports
│
├── slowness_debug/                    # 🕵️‍♂️ Sherlock Slow: Fun PC Performance Profiler
│   ├── README.md                      # Diagnostic tool documentation
│   ├── run_slowness_detective.bat     # Run interactive slowness audit & tune-up
│   ├── slowness_detective.ps1         # Real-time CPU, RAM, Disk, Uptime profiler
│   └── reports/                       # Generated diagnostic prescription files
│
├── search_fixer/                      # 🔍 Windows Search & Indexing Repair Suite
│   ├── README.md                      # Search repair tool documentation
│   ├── run_search_fixer.bat           # Run interactive search & indexing fix
│   └── fix_search.ps1                 # WSearch service, database rebuild & UWP repair
│
└── server_audit/                      # 🏛️ Main Server Forensic & Configuration Auditor
    ├── README.md                      # Server audit documentation
    ├── run_server_audit.bat           # Run extraction of server configurations
    ├── audit_server.ps1               # Extracts Users, GPOs, Shares, Services & Tasks
    └── reports/                       # Generated spreadsheets and GPO web reports
```

---

## 🚀 Adding New Automation Scripts

When building additional tools or scripts in this workspace, follow this standard modular layout:
1. Create a dedicated folder under the root directory (e.g., `user_management/`, `backup_automation/`, `network_audit/`).
2. Include double-click `.bat` wrappers with `-ExecutionPolicy Bypass` enabled so administrators can execute scripts without manual PowerShell policy configuration.
3. Keep output files, backups, and documentation isolated within that tool's subfolder using relative pathing (`$PSScriptRoot`).
