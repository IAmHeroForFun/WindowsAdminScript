# 🛡️ Enterprise Security, Compliance & Recovery Auditor [Option 10]

An enterprise-grade MSP security, patch compliance, backup engine, disk reliability, and remote access assessment suite. Designed for 100% automated role detection across Windows 10/11 workstations and Windows Server 2012 R2 through 2025.

---

## 🔎 Comprehensive Audit Modules

1. **Security & Identity Hardening**:
   * Audits Local Admins, Domain Admins, Built-in Guest/Administrator status.
   * Checks SMBv1 vulnerability, SMB signing, BitLocker encryption status, Windows Defender real-time AV & signature age, Windows Firewall profiles, User Account Control (UAC), LAPS deployment, PowerShell ScriptBlock Logging, Secure Boot, and hardware TPM 2.0 readiness.
2. **Patch Compliance & Lifecycle**:
   * Evaluates installed hotfix counts, last installed patch timestamp, servicing gaps (>30/60 days), and detects End-of-Life (EOL) operating systems. Computes a weighted **Patch Compliance Score**.
3. **Backup & Disaster Recovery Readiness**:
   * Inspects Volume Shadow Copy (VSS) engine status, enumerates local system restore snapshots, and audits kernel/memory crash dump settings (`MEMORY.DMP` readiness). Computes **Backup Readiness Score** and **Recovery Score**.
4. **Disk Health & Storage Reliability**:
   * Collects physical disk SMART health indicators, drive capacity, and scans System Event Logs (ID 7, 11, 51, 55) over the past 30 days for underlying hardware read/write disk faults.
5. **Network Health & Routing**:
   * Audits active NIC configurations, IP/Gateway assignments, and tests internet ICMP latency (`8.8.8.8`). Computes **Network Health Score**.
6. **RDP & Remote Access Audit**:
   * Verifies RDP listening port, active state, and ensures Network Level Authentication (NLA) is enforced to prevent brute-force attacks.

---

## 📊 Generated Case Files (`reports\`)

* `security_findings.csv`: Complete security posture findings, risk levels, and engineering fixes.
* `patch_compliance.csv`: Patch history and OS lifecycle analysis.
* `backup_readiness.csv`: VSS snapshot and disaster recovery status.
* `disk_health.csv`: SMART hardware health and controller event logs.
* `network_health.csv`: NIC parameters and gateway latency results.
* `overall_health_score.csv`: High-level executive scorecard.
* `audit.log`: Timestamped audit execution log.
* `enterprise_dashboard.html`: Self-contained, dark-mode offline executive HTML dashboard with visual health gauges and severity badges.

---

## ⚡ Optional Safe Auto-Fix Framework

When run interactively (or with `-RunAutoFix`), the script can safely remediate critical baseline risks upon confirmation:
* Enable all Windows Firewall profiles (`netsh advfirewall set allprofiles state on`).
* Eradicate vulnerable SMBv1 registry bindings (`LanmanServer\Parameters\SMB1 = 0`).
* Enforce User Account Control (`EnableLUA = 1`).
