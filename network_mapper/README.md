# 🌐 Advanced Network Mapper & Topology Discovery Tool [Option 11]

A SolarWinds & PRTG-inspired enterprise subnet discovery and mapping engine. Uses multi-threaded ICMP sweeps, DNS resolution, ARP table MAC extraction, IEEE OUI vendor dictionary matching, TCP port scanning (12 core ports), and heuristic OS fingerprinting.

---

## 🚀 Key Features

* **Multi-Threaded Subnet Scanning**: Pings 254 IP addresses simultaneously using asynchronous background jobs in under 15 seconds.
* **MAC Address & OUI Vendor Discovery**: Matches MAC address prefixes against an embedded enterprise IEEE OUI dictionary (Cisco, Apple, HP, Dell, VMware, Hyper-V, Synology, Ubiquiti, Netgear, Brother, Epson).
* **12-Port TCP Security Scan**: Probes ports `21 (FTP)`, `22 (SSH)`, `25 (SMTP)`, `53 (DNS)`, `80 (HTTP)`, `135 (RPC)`, `139 (NetBIOS)`, `443 (HTTPS)`, `445 (SMB)`, `3389 (RDP)`, `5985 (WinRM)`, and `1433 (SQL)`.
* **Heuristic OS Fingerprinting**: Automatically categorizes devices into:
  * `Windows Workstation / Server` (SMB/RDP/WinRM open)
  * `Linux / Unix System` (SSH open, SMB closed)
  * `Network Router / Access Point / Switch` (HTTP/S open on Cisco/Ubiquiti/Netgear MAC)
  * `NAS Storage Appliance` (Synology/QNAP MAC)
  * `Network Printer` (HP/Epson/Brother MAC with web/print ports)
* **Interactive HTML Topology Dashboard**: Renders a self-contained, dark-mode visual topology grid with color-coded device type badges and latency meters.

---

## 📂 Generated Reports (`reports\`)

* `discovered_devices.csv`: Full spreadsheet inventory of all online devices.
* `topology.json`: Deep hierarchical JSON structure suitable for network graphing or API ingestion.
* `network_dashboard.html`: Interactive offline HTML visual topology diagram and asset table.
