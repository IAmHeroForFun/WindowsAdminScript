# 05. Sherlock Slow PC Performance Debugger & Turbo Tune-Up

## 📌 Executive Summary
The **Sherlock Slow PC Performance Debugger** (`slowness_debug/slowness_detective.ps1`) is a deep-dive diagnostic and interactive tune-up engine. It runs 7 multi-layered diagnostic checks to calculate a System Speed Health Score (0-100), isolates exact hardware and software bottlenecks, and provides granular, interactive Y/N/Q repair steps to restore system performance.

---

## 🏗️ Architecture & Script Mapping

- **Primary Script**: `slowness_debug/slowness_detective.ps1`
- **Batch Launcher**: `slowness_debug/run_slowness_detective.bat`
- **Master Menu Option**: `[5]`
- **Direct Web Shortcut**: `irm https://toolkit.omvihub.in/slowness | iex`

---

## 🔍 Phase 1: 7-Layer Performance Profiler

1. **System Uptime & Pending Reboot Audit**:
   - Calculates total days/hours online.
   - Checks CBS, Windows Update, and Component-Based Servicing registry keys for pending reboot flags.
2. **CPU Load & Thermal Throttling**:
   - Measures real-time CPU utilization and checks for power/thermal clock speed throttling.
3. **RAM & Memory Pressure**:
   - Calculates physical RAM consumption, committed memory load, and paging file exhaustion.
4. **Disk Drive Space & IO Bottlenecks**:
   - Inspects `C:\` and system drives for low free space (<15% critical threshold).
5. **Disk Fragmentation & Health**:
   - Queries volume fragmentation levels and drive health via WMI.
6. **Network Socket Overload**:
   - Counts active established TCP connections to flag cloud sync/browser thread floods (>250 sockets).
7. **Startup Application Clutter Audit**:
   - Queries `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run`, `HKCU`, and 32-bit Wow6432Node keys to count and analyze auto-launching applications.

---

## ⚡ Phase 2: Granular Interactive Turbo Tune-Up

Each action prompts the user before executing:
1. **[ACTION 1/6] Temp Clutter Cleanup**: Clears `%TEMP%` and `C:\Windows\Temp`.
2. **[ACTION 2/6] Recycle Bin Purge**: Empties Recycle Bin across all local drives via COM interface.
3. **[ACTION 3/6] Advanced Disk Cleanup & Update Cache Purge**: Stops `wuauserv`, wipes `C:\Windows\SoftwareDistribution\Download`, removes `MEMORY.DMP` / minidumps, and purges IIS logs older than 14 days and Windows CBS logs older than 30 days.
4. **[ACTION 4/6] DNS & Network Buffer Reset**: Executes `ipconfig /flushdns` and resets network buffers.
5. **[ACTION 5/6] Power Plan Optimization**: Switches active power scheme to High Performance (`8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c`).
6. **[ACTION 6/6] Startup Audit Export**: Dumps all auto-launch boot items into `startup_audit_<ComputerName>.txt`.

---

## 📊 Reports Generated

- **Diagnostic Case Report**: `C:\SysMaster\reports\slowness_report_<ComputerName>_<Timestamp>.txt`
- **Startup App Audit**: `C:\SysMaster\reports\startup_audit_<ComputerName>.txt`
