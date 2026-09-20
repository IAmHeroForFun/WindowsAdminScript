# 🕵️‍♂️ Sherlock Slow: PC Slowness Detective & Turbo Fixer

A comprehensive, interactive performance profiling tool designed to diagnose *why* a Windows PC feels sluggish and provide targeted, safe one-click turbo tune-ups.

---

## 🏎️ What Sherlock Slow Investigates

1. **CPU Health, Throttling & Resource Hog Audit**:
   - Samples real-time CPU utilization and identifies the top 5 processes hogging processing power.
   - **PROCHOT Thermal / Power Throttling Detection**: Compares current CPU clock speed vs. maximum rating to catch the infamous **0.79 GHz clamp** (thermal or faulty sensor lock).
   - **WMI Provider Host (`WmiPrvSE.exe`) Tracer**: Pinpoints rogue client processes submitting excessive WMI queries when WMI CPU usage spikes.
2. **Memory & Pagefile Capacity (RAM Audit)**:
   - Calculates available vs. consumed physical RAM and alerts on memory overflows and aggressive disk paging.
3. **Hard Drive Engine & Storage Latency**:
   - Detects mechanical spinning hard drives (HDDs) vs. high-speed NVMe/SATA SSDs.
   - **Storage Response Latency & Queue Depth**: Audits average transfer latency (`AvgDiskSecPerTransfer`) to catch disk freezes (>50ms response times).
   - Flags low C: drive free space (< 15%).
4. **Zombie Uptime & Pending Reboot Audit**:
   - Measures continuous uptime days and detects pending Windows Update reboots causing background maintenance overhead.
5. **Backseat Drivers (Startup Applications)**:
   - Enumerates auto-launching registry items slowing down boot times.

---

## 🚀 How to Use

### Local Run
Double-click **`run_slowness_detective.bat`**.

### Centralized Web Execution
Via the master toolkit entrypoint:
```powershell
irm https://toolkit.omvihub.in | iex
```
Select `[5] Sherlock Slow PC Diagnostics Suite`.
