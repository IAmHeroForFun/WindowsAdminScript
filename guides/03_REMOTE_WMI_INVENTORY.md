# 03. Agentless Remote Network PC Inventory (WMI / CIM)

## 📌 Executive Summary
The **Agentless Remote Network PC Inventory Tool** (`inventory/remote_inventory.ps1`) connects to remote workstations and servers across an Active Directory Domain or Local Workgroup without installing any local agent software. It leverages Windows Management Instrumentation (WMI) and Common Information Model (CIM) protocols over RPC/WinRM to collect full hardware specifications and software lists remotely.

---

## 🏗️ Architecture & Script Mapping

- **Primary Script**: `inventory/remote_inventory.ps1`
- **Batch Launcher**: `inventory/run_remote_inventory.bat`
- **Master Menu Option**: `[3]`
- **Direct Web Shortcut**: `irm https://toolkit.omvihub.in/remoteinv | iex`

---

## ⚙️ Connection & Protocol Workflows

1. **Target Identification**:
   - Accepts a single hostname/IP address, a comma-separated list, or an input text file of target computer names.
   - Verifies target reachability via ICMP ping before initiating RPC/WMI connections.

2. **Authentication Modes**:
   - **Integrated Windows Authentication (Kerberos/NTLM)**: Uses the current logged-in Domain Administrator token.
   - **Alternate Credentials**: Prompts for administrative credentials (`Get-Credential`) if connecting across workgroups or non-trusted domains.

3. **Fallback Architecture**:
   - Attempts modern CIM over WinRM (`Get-CimInstance` on Port 5985/5986).
   - Automatically falls back to classic DCOM/RPC WMI (`Get-WmiObject` on Port 135 & dynamic RPC ports) for legacy Windows 7 / Server 2008 R2 targets.

4. **Remote Data Extraction**:
   - Queries `Win32_ComputerSystem`, `Win32_OperatingSystem`, `Win32_Processor`, `Win32_PhysicalMemory`, `Win32_DiskDrive`, `Win32_VideoController`, and remote registry hives for installed applications.

---

## 📊 Reports & Outputs

- **Central Inventory CSV**: Appends or updates rows directly in `C:\SysMaster\reports\inventory.csv`.
- **Remote Installed Software**: Saved to `C:\SysMaster\reports\installed_software\<TargetHost>_software.txt`.
- **Error Log**: Unreachable or access-denied targets are flagged with specific troubleshooting advice (e.g. firewall blocked RPC, WMI service disabled).
