# 🖨️ Printer Diagnostic & Management Suite

An enterprise-grade administrative suite for diagnosing, optimizing, and deploying printers across Windows 7 through 11 and Windows Server 2008 R2 through 2025.

---

## 🚀 Features & Tools

1. **Diagnose Spooler & Force Purge Stuck Queue**:
   - Scans for print jobs stuck in `Deleting` or `Error` status.
   - Gracefully shuts down the Print Spooler service, force-terminates `spoolsv.exe` and isolation hosts if locked, purges the queue directories (`*.SPL` and `*.SHD` files), and restarts the service.

2. **Run Printer Fleet Inventory Scan & Security Posture**:
   - Audits Windows Protected Print (WPP) state and detects if legacy v3 third-party drivers are blocked.
   - Classifies driver models (Type 3 vs Type 4) and providers (Microsoft Class vs Third-Party).
   - Exports the enriched inventory to `printer_inventory.csv`.

3. **Diagnose Network Printer Port Latency & Connectivity**:
   - Audits active Standard TCP/IP print ports.
   - Measures network latency via ICMP pings and tests standard print transport channels (`RAW 9100`, `LPR 515`) to isolate hanging ports.

4. **Configure Print Driver Isolation**:
   - Audits installed print drivers and adjusts isolation mode (`Isolated`, `Shared`, `None`) to prevent driver crashes from terminating `spoolsv.exe`.

5. **Purge Stale/Orphaned Ports & Offline Printers**:
   - Identifies offline print queues and orphaned IP/WSD ports without queues.
   - Safely deletes orphaned ports to eliminate registry pollution and print dialog hangs.

6. **Add Standard TCP/IP Network Printer Port & Queue**:
   - Automates standard TCP/IP print port creation and maps queues directly.

7. **Diagnose Shared Printer Target Path (`\\HOST\Printer`)**:
   - Multi-layer reachability diagnosis before attempting connections:
     1. Host IP resolution (DNS / NetBIOS).
     2. TCP 445 (SMB) port connectivity.
     3. TCP 135 (RPC Endpoint Mapper) & static print RPC port reachability.
     4. SMB share namespace accessibility (`\\HOST\`).
     5. Local printer queue status check.
   - Saves detailed diagnostic report to `reports/printer_path_test_<timestamp>.txt`.

8. **Analyze PrintService Event Logs & Decode Win32 Error Codes**:
   - Queries recent warning and error records from `Microsoft-Windows-PrintService/Admin`.
   - Decodes common shared printer error codes:
     - `0x0000011b` (RPC packet privacy constraint)
     - `0x00000709` (RPC binding / name resolution failure)
     - `0x00000bc4` (Windows 11 RPC over TCP default block)
     - `0x0000007c` (CopyFiles driver copy policy restriction)
     - `Error 5 / Access Denied` (Point and Print restriction)
   - Provides immediate, targeted triage recommendations.

---

## 💻 How to Run

### Local Execution (GUI/Console)
Right-click `run_printer_manager.bat` and select **Run as Administrator**.

### Centralized Web Execution
Via the master toolkit entrypoint:
```powershell
irm https://toolkit.omvihub.in | iex
```
Select `[10] Printer Diagnostic & Management Suite`.
