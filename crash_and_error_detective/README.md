# 🛑 Server Crash, Reboot & Error Forensic Detective

Scans the past 30 days of Windows Server event telemetry to uncover unexpected power cuts, clean shutdowns, Blue Screen BugChecks (BSODs), and top recurring application/system errors. Features an offline IT remediation dictionary paired with live online Microsoft Knowledge Base lookup links.

---

## 🔎 What It Audits

1. **Power Cut & Shutdown Audit (Past 30 Days)**:
   * **Event ID 1074**: Planned clean shutdowns or restarts (documents initiator).
   * **Event ID 6008**: Unexpected server power loss or abrupt hardware freeze.
   * **Event ID 41**: Kernel-Power critical reboot.
   * **Event ID 1001**: Blue Screen of Death (BSOD) stop dump generation.
2. **Top Recurring Critical & Error Patterns**:
   * Extracts the top recurring critical errors from System and Application logs, pairing each Event ID and source provider with actionable root-cause IT troubleshooting advice.
3. **Live Web Intelligence Engine**:
   * Automatically detects if the server has internet access. If online, embeds direct, pre-formatted Google and Microsoft Learn TechNet troubleshooting URLs directly into your reports!

---

## 📊 Extracted Reports (`reports\`)
* `server_shutdowns_audit.csv`: Spreadsheet of all shutdown and power events.
* `server_critical_errors.csv`: Spreadsheet of top system errors and suggested fixes.
* `server_crash_and_error_report.html`: Beautiful interactive web dashboard with clickable knowledge base links!
