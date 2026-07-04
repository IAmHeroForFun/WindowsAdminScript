# 🏛️ Complete Self-Hosted MSP Monitoring & Reporting Platform [Option 14]

A self-hosted, modular enterprise IT administration and reporting ecosystem designed as an on-premise alternative to Lansweeper, PRTG Network Monitor, NinjaOne, and ManageEngine OpManager. Engineered for 100% PowerShell 5.1 compatibility without cloud dependencies or subscription licensing.

---

## 🏗️ 10 Integrated Administrative Modules

1. **Endpoint Inventory**: Harvests hardware vendor, motherboard model, physical memory (RAM), processor specifications, and OS versioning.
2. **Security Audit**: Audits SMBv1 vulnerability, Windows Firewall profile state across network boundaries, User Account Control (`EnableLUA`), and Defender policies.
3. **Patch Compliance**: Evaluates installed hotfix counts, days since last servicing cycle, and flags unsupported End-of-Life (EOL) operating systems.
4. **Backup Verification**: Probes Volume Shadow Copy Service (`VSS`) health and enumerates local restore point snapshots.
5. **Certificate Monitoring**: Scans the Local Machine certificate store for SSL/TLS certificates expiring within 30 days.
6. **Uptime Monitoring**: Checks real-time ICMP ping latency and packet loss against external routing endpoints (`8.8.8.8`).
7. **Asset Lifecycle Management**: Computes physical hardware age from BIOS release date and flags assets exceeding standard 3-to-5 year replacement SLAs.
8. **Network Discovery**: Inspects active subnet neighbor footprint via ARP table resolution.
9. **Executive Reporting**: Generates a responsive, dark-mode HTML Master Command Center dashboard with severity distribution counters.
10. **Historical Trend Analysis**: Persists timestamped assessment scores to a local JSON and CSV database to track compliance improvements over time.

---

## 📈 3 Executive KPI Scoring Engines

* **MSP Health Score (0–100)**: Overall infrastructure stability and operational resilience.
* **Client Risk Score (0–100)**: Business exposure and cybersecurity threat vulnerability.
* **Infrastructure Risk Score (0–100)**: Hardware lifecycle obsolescence and servicing gap level.

---

## ⚡ Automated Background Monitoring & Email Alerting

* **Scheduled Task Automation**: Install a persistent daily background monitoring job:
  ```powershell
  powershell.exe -ExecutionPolicy Bypass -File "D:\projects\script\msp_platform\msp_platform.ps1" -InstallScheduledTask
  ```
* **Automated SMTP Alerting**: Receive instant email alerts if the MSP Health Score drops below 70:
  ```powershell
  powershell.exe -ExecutionPolicy Bypass -File "D:\projects\script\msp_platform\msp_platform.ps1" -SendEmailAlert -SmtpServer "smtp.office365.com" -AlertEmailTo "admin@msp.com"
  ```

---

## 📂 Generated Deliverables (`reports\`)

* `msp_master_dashboard.html`: Self-contained HTML Command Center dashboard.
* `historical_trends.json`: Persistent JSON historical trend database.
* `historical_trends.csv`: CSV spreadsheet tracking historical KPI scores.
* `msp_risk_scores.csv`: Itemized findings and risk levels.
