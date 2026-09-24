# 💻 USB Windows Inventory Tool (Full OS Compatibility & Network Remote Scan)

This portable tool retrieves hardware and software inventory from Windows PCs and aggregates the results into a central spreadsheet on your USB drive. It is 100% compatible across **Windows 7** through **Windows 11** and **Windows Server**.

It features a **Multi-Workflow Suite**:
1. **Local USB Spec Scan (`run_inventory.bat`)**: Take the USB drive to any PC, double-click the script (no admin rights required), and it will gather the PC's complete hardware, disk health, memory slots, and software details.
2. **Network Discovery Scan (`run_network_scan.bat`)**: Plug the USB drive into **1 PC** and run a network sweep to find all online PCs. This adds their Names and IPs to the list as placeholders (`Pending USB Scan`).
3. **Remote Network Spec Scan (`run_remote_inventory.bat`)**: Run from one central PC to remotely connect to all discovered online Windows PCs over WMI/DCOM across the network. If you have admin privileges across the domain or workgroup, it gathers their complete hardware specs and software lists over the network without leaving your desk!
4. **Shared Folder & Permissions Auditor (`run_folder_permissions.bat`)**: Run on any Windows Server or client to audit active SMB file shares and NTFS directory access control lists (ACLs). Generates a complete audit report mapping every user/group to their access rights and security flags.

---

## 📁 Drive Structure

Place these files on your USB pendrive root or in a dedicated directory:

```text
USB Drive/
├── run_inventory.bat             # Run on each PC locally (No Admin Required)
├── run_network_scan.bat          # Fast ping scan to discover active network IPs
├── run_remote_inventory.bat      # Query remote network PCs over WMI (Admin Required)
├── run_folder_permissions.bat   # Audit Shared Folders & NTFS Permissions (Admin Recommended)
├── audit_folder_permissions.ps1  # Folder & SMB permissions audit logic
├── get_inventory.ps1             # Local hardware/software scan logic
├── scan_network.ps1              # Network discovery scan logic
├── remote_inventory.ps1          # Remote WMI network inventory logic
├── inventory.csv                 # Consolidated spreadsheet of all PCs
├── reports/                      # Folder permissions audit CSV reports
│   ├── folder_permissions.csv
│   └── folder_permissions_<ComputerName>_<Timestamp>.csv
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

### Option C: Shared Folder & NTFS Permissions Audit (Standalone or Server)
1. Copy or download `audit_folder_permissions.ps1` & `run_folder_permissions.bat` to any Windows Server or client machine.
2. Right-click **`run_folder_permissions.bat`** and select **Run as Administrator** (required to read ACLs and SMB security descriptors on protected shares).
3. Choose the audit scope:
   * **[1] Audit all active SMB file shares (Recommended)**: Automatically discovers all custom file shares (excluding administrative hidden shares like `ADMIN$`, `C$`, `IPC$`), audits both SMB Share-level permissions and underlying NTFS folder permissions.
   * **[2] Audit a specific folder path**: Enter any local directory (e.g. `D:\Data\Finance`) to audit its recursive access permissions.
   * **[3] Audit root directories across all fixed local drives**: Scans top-level shared roots across `C:\`, `D:\`, etc.
4. The audit automatically generates two CSVs in the `reports/` folder:
   * A consolidated report: `reports/folder_permissions.csv`
   * A timestamped snapshot: `reports/folder_permissions_<ComputerName>_<YYYYMMDD_HHmmss>.csv`

#### Permission Report Columns
| Column | Description |
| :--- | :--- |
| `ComputerName` | Hostname of the scanned server/workstation |
| `LoggedOnUser` | Username running the scan |
| `ShareName` | SMB Share name (or `N/A (Local Folder)` if auditing direct path) |
| `FolderPath` | Local filesystem path of the folder |
| `PermissionLayer` | `SMB Share Level` or `NTFS Filesystem Level` |
| `IdentityReference` | User or Group account name (or SID if orphaned account) |
| `AccessControlType` | `Allow` or `Deny` |
| `Permissions` | Specific rights (e.g., `FullControl`, `ReadAndExecute`, `Change`, `Read`) |
| `IsInherited` | `True` if inherited from parent directory, `False` if explicit |
| `InheritanceFlags` | Inheritance propagation rule (`ContainerInherit, ObjectInherit`, etc.) |
| `PropagationFlags` | Propagation behavior (`None`, `InheritOnly`, `NoPropagateInherit`) |
| `SecurityRisk` | Flags potential risks like `Unrestricted Everyone Full Control`, `Explicit Deny Rule`, or `Orphaned/Unresolvable SID` |
| `ScanTimestamp` | Date and time the audit was performed |

---

## 📊 Compatibility & Formatting Guarantee

* **100% Windows Version Compatible**: Tested and structured to run seamlessly across Windows 7 (PowerShell 2.0), Windows 8, Windows 10, Windows 11 (PowerShell 5.1 & 7+), and Windows Server 2008 R2 through Server 2025.
* **No CSV Column Corruption**: All string fields are sanitized to remove trailing carriage returns and newlines (`\r\n`), ensuring rows never split or merge columns when opened in Microsoft Excel.
