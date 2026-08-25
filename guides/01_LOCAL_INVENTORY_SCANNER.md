# 01. Local Hardware & Installed Software Inventory Scanner

## 📌 Executive Summary
The **Local Hardware & Installed Software Inventory Scanner** (`inventory/get_inventory.ps1`) performs a rapid, agentless forensic hardware and software inventory of the local Windows PC or Server. It consolidates hardware specifications into a central `inventory.csv` file (updating existing entries by Computer Name/Serial Number or appending new rows) and dumps a complete list of installed applications into a separate text file.

---

## 🏗️ Architecture & Script Mapping

- **Primary Script**: `inventory/get_inventory.ps1`
- **Batch Launcher**: `inventory/run_inventory.bat`
- **Master Menu Option**: `[1]`
- **Direct Web Shortcut**: `irm https://toolkit.omvihub.in/inventory | iex`

---

## 🔍 Data Points Collected

### Hardware & Operating System:
- **System Information**: Computer Name, OS Caption, Build/Version, OS Architecture (64-bit / 32-bit), System Uptime.
- **Motherboard & BIOS**: Manufacturer, Model Number, Serial Number, BIOS Version, Secure Boot Status.
- **CPU (Processor)**: Name, Physical Cores, Logical Processors, Base Clock Speed.
- **Memory (RAM)**: Total Installed Capacity (GB), RAM Speed (MHz), Number of Slots Occupied.
- **Storage / Disks**: Drive letters, Models, Interface (NVMe / SATA / SSD / HDD), Total Capacity, Free Space (GB & %).
- **Graphics (GPU)**: Video Controller Name, Driver Version, VRAM.
- **Network Interfaces**: Active Network Adapter Names, MAC Addresses, IPv4 Addresses, Default Gateways, DNS Servers.

### Software Inventory:
- Scans `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall` (64-bit).
- Scans `HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall` (32-bit).
- Scans `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall` (Per-user apps).
- Captures: Application Name, Version, Publisher, Install Date, and Architecture.

---

## 📊 Reports & Storage Location

1. **Consolidated Inventory CSV**:
   - Path: `C:\SysMaster\reports\inventory.csv` (or `inventory\inventory.csv`)
   - Deduplication: Matches against existing rows by `Computer Name` or `Serial Number`. If a match is found, updates the record in-place; otherwise, appends a new row.
   - Backup: Automatically creates a timestamped backup (`inventory_backup_YYYY-MM-DD_HH-mm-ss.csv`) in `reports\backups\` before modifying the CSV.

2. **Detailed Installed Software File**:
   - Path: `C:\SysMaster\reports\installed_software\<ComputerName>_software.txt`
   - Formatted list of all installed programs sorted alphabetically with version numbers and install dates.
