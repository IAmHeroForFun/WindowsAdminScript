# 09. Local Print Spooler, Queue & Driver Manager

## 📌 Executive Summary
The **Print Spooler, Queue & Driver Management Suite** (`printer_manager/manage_printers.ps1`) manages local and network printer subsystems. It resolves hung spoolers, purges corrupted print queues, measures TCP/IP port ping latency, isolates print drivers to prevent spooler crashes, cleans up ghost/offline printers, and creates standard TCP/IP network printer queues.

---

## 🏗️ Architecture & Script Mapping

- **Primary Script**: `printer_manager/manage_printers.ps1`
- **Batch Launcher**: `printer_manager/run_printer_manager.bat`
- **Master Menu Option**: `[9]`
- **Direct Web Shortcut**: `irm https://toolkit.omvihub.in/printer | iex`

---

## 🖨️ Modular Capabilities

```text
 [1] Deep Print Spooler Diagnostic & Stuck Job Purger
 [2] Print Queue Health, Paper Jam & Error Inspector
 [3] Diagnose Network Printer Port Latency & Connectivity (Ping/TCP)
 [4] Configure Print Driver Isolation (Prevent Spooler Crashes)
 [5] Purge Stale/Orphaned Ports & Offline Printers (Cleanup)
 [6] Add Standard TCP/IP Network Printer Port & Queue
 [Q] Return to Master Menu
```

1. **Spooler Diagnostic & Stuck Job Purger**:
   - Stops `Spooler` service, wipes stuck `.SHD` and `.SPL` files from `C:\Windows\System32\spool\PRINTERS`, and restarts the service.

2. **Network Port Latency & TCP Socket Probe**:
   - Tests ICMP latency and TCP socket connections on Port 9100 (RAW) and Port 515 (LPR).

3. **Driver Isolation Configuration**:
   - Sets driver isolation to `Isolated` mode in registry/print management to prevent faulty OEM drivers from crashing the entire `spoolsv.exe` process.

4. **Orphaned Ports & Ghost Printer Cleanup**:
   - Enumerates and removes unused `WSD`, `TCP/IP`, and `LPT` ports that no longer have attached physical devices.

5. **Standard TCP/IP Port & Queue Creator**:
   - Creates a standard TCP/IP port (e.g. `192.168.1.150`), assigns driver, and creates the printer queue programmatically.
