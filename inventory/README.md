# 💻 USB Windows Inventory Tool (Full OS Compatibility & Network Remote Scan)

This portable tool retrieves hardware and software inventory from Windows PCs and aggregates the results into a central spreadsheet on your USB drive. It is 100% compatible across **Windows 7** through **Windows 11** and **Windows Server**.

It features a **Triple-Workflow**:
1. **Local USB Spec Scan (`run_inventory.bat`)**: Take the USB drive to any PC, double-click the script (no admin rights required), and it will gather the PC's complete hardware, disk health, memory slots, and software details.
2. **Network Discovery Scan (`run_network_scan.bat`)**: Plug the USB drive into **1 PC** and run a network sweep to find all online PCs. This adds their Names and IPs to the list as placeholders (`Pending USB Scan`).
3. **Remote Network Spec Scan (`run_remote_inventory.bat`)**: Run from one central PC to remotely connect to all discovered online Windows PCs over WMI/DCOM across the network. If you have admin privileges across the domain or workgroup, it gathers their complete hardware specs and software lists over the network without leaving your desk!

---

## 📁 Drive Structure

Place these files on your USB pendrive root or in a dedicated directory:

```text
USB Drive/
├── run_inventory.bat             # Run on each PC locally (No Admin Required)
├── run_network_scan.bat          # Fast ping scan to discover active network IPs
├── run_remote_inventory.bat      # Query remote network PCs over WMI (Admin Required)
├── get_inventory.ps1             # Local hardware/software scan logic
├── scan_network.ps1              # Network discovery scan logic
├── remote_inventory.ps1          # Remote WMI network inventory logic
├── inventory.csv                 # Consolidated spreadsheet of all PCs
├── backups/                      # Automatic timestamped backups before each run
│   └── inventory_backup_YYYY-MM-DD_HH-mm-ss.csv
└── installed_software/           # Detailed installed software lists
    ├── PC-NAME-1_software.txt
    └── PC-NAME-2_software.txt
```

---

## 🛡️ Automatic Backup Feature

Whenever any scan script is executed (`run_inventory.bat`, `run_network_scan.bat`, or `run_remote_inventory.bat`), it automatically checks if `inventory.csv` exists. If it does, an exact timestamped backup copy is saved in the `backups/` folder before any updates occur. Your historical data is never lost!

---

## 🚀 Step-by-Step Workflows

### Option A: Fully Remote Network Inventory (From One Central PC)
1. Plug the USB drive into your admin or management computer.
2. Double-click **`run_remote_inventory.bat`**.
3. You can choose to enter domain or local administrator credentials when prompted (or press Enter to use your current logged-in Windows account).
4. The script sweeps the network, connects to each online Windows PC over WMI/DCOM, gathers complete hardware specifications (RAM, CPU, Disk health, OS, MS Office, Antivirus), and writes detailed software reports remotely!
5. Any device that blocks remote access (or is non-Windows like a printer) will be marked as `Pending USB Scan` so you can scan it locally.

### Option B: Local USB Scan (No Admin Required)
1. Plug the USB drive into any target PC.
2. Double-click **`run_inventory.bat`**.
3. The script gathers specs instantly and updates/overwrites its row in `inventory.csv`.

---

## 📊 Compatibility & Formatting Guarantee

* **100% Windows Version Compatible**: Tested and structured to run seamlessly across Windows 7 (PowerShell 2.0), Windows 8, Windows 10, Windows 11 (PowerShell 5.1 & 7+), and Windows Server editions.
* **No CSV Column Corruption**: All string fields are sanitized to remove trailing carriage returns and newlines (`\r\n`), ensuring rows never split or merge columns when opened in Microsoft Excel.
