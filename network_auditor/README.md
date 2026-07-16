# 🌐 Network Security, Scanner & Diagnostics Auditor

A comprehensive all-in-one network auditing tool for IT and Network Administrators.
Compatible with **Windows 7–11** and **Windows Server 2008 R2–2025**.
Zero external dependencies — uses only native PowerShell and Windows built-in tools.

---

## 🚀 6-Phase Audit Flow

| Phase | Name | Description |
|-------|------|-------------|
| **1** | Windows Firewall Status | Checks Domain, Private, and Public firewall profiles (ON/OFF). |
| **2** | DNS & Hosts File Integrity | Audits active DNS servers for safety, and scans hosts file for unauthorized redirect mappings. |
| **3** | Listening Port Inventory | Lists all TCP/UDP listening sockets with **SAFE / CAUTION / UNSAFE** security ratings and owning process info. |
| **4** | Outbound Session Monitor | Logs all active ESTABLISHED outbound connections with async reverse DNS hostname resolution. |
| **R** | Interactive Remediation | Prompts Y/N per unsafe/caution port. Offers **[K]ill Process** or **[B]lock in Firewall** with system-process safety guards. |
| **5** | Subnet IP & Port Scanner | Auto-detects local subnet, runs a parallel async ping sweep, then TCP-probes each live host for 10 common management ports (SSH, RDP, SMB, HTTP/S, WinRM, MSSQL, MySQL, Telnet). |
| **6** | Latency & DNS Diagnostics | 10-packet ping audit (Gateway / LAN DNS / Google / Cloudflare / Quad9) with min/max/avg/loss table, DNS resolution speed benchmark across 5 resolvers, and a 6-hop traceroute. |

---

## 📋 Security Ratings Explained

| Rating | Color | Meaning |
|--------|-------|---------|
| ✅ **SAFE** | Green | Socket bound to loopback (`127.0.0.1` / `[::1]`) — no external exposure. |
| ⚠️ **CAUTION** | Yellow | Socket bound globally (`0.0.0.0` / `*`) — verify the process and restrict access. |
| 🔴 **UNSAFE** | Red | Legacy or plaintext protocol (FTP 21, Telnet 23, NetBIOS 137-139) — disable immediately. |

---

## 📁 Reports Generated

All reports are saved to `network_auditor\reports\`:

| File | Contents |
|------|----------|
| `network_security_report_HOSTNAME.csv` | Full port audit with ratings, descriptions, and suggestions |
| `subnet_scan_HOSTNAME_YYYYMMDD_HHmm.csv` | Live hosts, hostnames, and open management ports |
| `network_diagnostics_HOSTNAME_YYYYMMDD_HHmm.txt` | Ping latency stats and DNS resolver benchmark results |

---

## 💻 How to Run

### Local Execution
Right-click `run_network_audit.bat` → **Run as Administrator**

### Web Bootstrap (One-liner)
```powershell
irm https://toolkit.omvihub.in/netaudit | iex
```

---

## 🔒 Safety Notes

- Killing a process (`[K]`) that belongs to `svchost`, `lsass`, `System`, or similar Windows core services **will crash or reboot** the machine. The tool warns you and requires typing `CONFIRM` to proceed.
- Firewall block rules (`[B]`) are the safe alternative — they block new inbound connections without stopping any process.
- All firewall rules added by this tool are named `IT-Toolkit-Blocked-Port-XXXX` for easy identification and rollback via Windows Defender Firewall.

---

## 🖥️ Compatibility

| OS | Supported |
|----|-----------|
| Windows 7 / Server 2008 R2 | ✅ (WMI + netstat fallback) |
| Windows 8.1 / Server 2012 R2 | ✅ |
| Windows 10 / Server 2016-2019 | ✅ |
| Windows 11 / Server 2022-2025 | ✅ |
| PowerShell 2.0 – 7.x | ✅ |
