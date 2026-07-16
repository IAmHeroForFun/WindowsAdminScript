# 🖨️ Printer Diagnostic & Management Suite

An administrative suite for diagnosing, optimizing, and deploying printers in corporate and local networks.

---

## 🚀 Features

1. **Diagnose Spooler & Force Purge Stuck Queue**:
   * Scans for print jobs stuck in `Deleting` or `Error` status.
   * Gracefully shuts down the Print Spooler service, force-terminates `spoolsv.exe` if locked, purges the queue directories (`*.SPL` and `*.SHD` files), and restarts the service.

2. **Run Printer Fleet Inventory Scan**:
   * Extracts details on all mapped local/network printer queues, driver configurations, and default printer settings.
   * Exports a detailed database report to `printer_manager/reports/printer_inventory.csv`.

3. **Diagnose Network Printer Port Latency & Connectivity**:
   * Audits active Standard TCP/IP print ports.
   * Measures network latency via ICMP pings.
   * Tests standard print transport channels (`RAW 9100`, `LPR 515`) to isolate offline/hanging ports that cause sluggish print dialog boxes in Windows Explorer.

4. **Configure Print Driver Isolation**:
   * Audits installed print drivers and adjusts their isolation mode (`Isolated`, `Shared`, `None`).
   * Transitioning print drivers into isolation prevents a faulty driver crash from taking down the entire system-wide print spooler.

5. **Purge Stale/Orphaned Ports & Offline Printers**:
   * Identifies offline print queues and orphaned IP/WSD ports (ports without any printer queues bound to them).
   * Safely deletes orphaned ports to eliminate registry pollution and network timeout hangs during print selection.

6. **Add Standard TCP/IP Network Printer Port & Queue**:
   * Automates standard TCP/IP print port creation and maps queues directly.

---

## 💻 How to Run

### Local Execution (GUI/Console)
Right-click `run_printer_manager.bat` and select **Run as Administrator**.

### Global Web execution (Massgrave-style)
```powershell
irm https://toolkit.omvihub.in/printer | iex
```
