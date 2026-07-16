# 🚀 Windows 11 Debloat & Privacy Optimizer

A lightweight, standalone utility engineered specifically for **Windows 11 (Builds 22000+)** to remove UWP bloatware, disable OS telemetry, hide unused taskbar elements, and prevent resource-hogging background applications like OneDrive from auto-starting.

---

## 🛠️ Features

1. **Remove Sponsored UWP Bloatware**:
   * Scans and safely removes pre-installed sponsored packages (TikTok, Spotify, Facebook, Clipchamp, Xbox widgets, news, weather, feedback hubs).
   * Disables Windows Content Delivery Manager policies from auto-installing suggested applications on new profiles.

2. **Disable Telemetry & Diagnostic Data Collection**:
   * Configures Group Policy and registry settings to restrict OS data collection.
   * Stops and disables diagnostic services (`DiagTrack`, `dmwappushservice`).
   * Blocks advertising IDs and tailored telemetry experiences.

3. **Taskbar GUI Optimization**:
   * Hides space-wasting and memory-intensive Taskbar buttons (Widgets, Chat, Task View, Search box).
   * Provides option to align the taskbar to the Left instead of the center.

4. **OneDrive Boot Removal**:
   * Deletes the OneDrive startup agent from the user run registry hive.
   * Shuts down running OneDrive background clients.

---

## 💻 How to Run

### Local Execution (GUI/Console)
Right-click `run_debloater.bat` and select **Run as Administrator**.

### Global Web execution (Massgrave-style)
```powershell
irm https://toolkit.omvihub.in/debloat | iex
```
*(If integrated into Nginx)*
