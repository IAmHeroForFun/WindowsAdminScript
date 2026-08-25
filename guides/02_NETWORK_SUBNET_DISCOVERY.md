# 02. Network Subnet IP & Active Host Discovery (Ping Sweep)

## 📌 Executive Summary
The **Network Subnet IP & Active Host Discovery Scanner** (`inventory/scan_network.ps1`) performs a rapid, multi-threaded ICMP ping sweep across the local network subnet (e.g. `/24` 1-254). It automatically detects the active subnet, identifies all responsive IP addresses, resolves hostnames via reverse DNS lookups, cross-references physical MAC addresses from the ARP cache, and populates undiscovered devices into the centralized inventory database.

---

## 🏗️ Architecture & Script Mapping

- **Primary Script**: `inventory/scan_network.ps1`
- **Batch Launcher**: `inventory/run_network_scan.bat`
- **Master Menu Option**: `[2]`
- **Direct Web Shortcut**: `irm https://toolkit.omvihub.in/netscan | iex`

---

## ⚙️ Technical Mechanics

1. **Subnet Auto-Detection**:
   - Queries active IPv4 network adapters via WMI (`Win32_NetworkAdapterConfiguration`) and `.NET` NetworkInterfaces.
   - Extracts the primary IPv4 address and subnet prefix (e.g. `192.168.1.0/24`).
   - Allows the administrator to confirm the auto-detected subnet or specify a custom range.

2. **Asynchronous Multi-Threaded Ping Sweep**:
   - Dispatches parallel `.NET` `System.Net.NetworkInformation.Ping` asynchronous tasks.
   - Scans 254 IP addresses in parallel within ~5 to 10 seconds.

3. **Hostname & MAC Address Resolution**:
   - Performs asynchronous reverse DNS lookup (`[System.Net.Dns]::GetHostEntry`).
   - Executes `arp -a <IP>` and parses the Windows ARP cache table to retrieve physical MAC addresses and NIC vendor identifiers.

4. **Inventory Sync**:
   - Matches discovered hostnames against `inventory.csv`.
   - Populates new placeholder rows (`Device Type = Pending USB Scan`) for network-only discovered devices.

---

## 📊 Reports Generated

- **Subnet Scan CSV**: `C:\SysMaster\reports\subnet_scan_<ComputerName>_<Timestamp>.csv`
  - Columns: `IP Address`, `Hostname`, `MAC Address`, `Status`, `Response Time (ms)`
- **Inventory Sync**: Updates `C:\SysMaster\reports\inventory.csv`.
