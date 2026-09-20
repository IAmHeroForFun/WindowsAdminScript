# 🛡️ Windows Defender Signature Reset & Exclusion Repair Suite

A production-grade, interactive administration suite to reset corrupted Windows Defender signatures, test Defender cloud reachability, audit Tamper Protection and Attack Surface Reduction (ASR) rules, and manage folder/process exclusions.

---

## 🚀 Key Features

1. **Tamper Protection State Inspection**:
   - Inspects `HKLM:\SOFTWARE\Microsoft\Windows Defender\Features\TamperProtection` and informs the admin if kernel tamper locking is active.
2. **Defender Cloud Protection Reachability Probe**:
   - Tests HTTPS connectivity on port 443 to `wdcp.microsoft.com`, `wdcpalt.microsoft.com`, `smartscreen.microsoft.com`, and `definitionupdates.microsoft.com`.
   - Identifies if enterprise network proxies or firewalls are blocking real-time cloud-delivered intelligence.
3. **Defender Signature Definition Reset**:
   - Flushes corrupted definition databases using `MpCmdRun.exe -RemoveDefinitions -All`.
   - Forces fresh definition downloads from Microsoft Update servers.
4. **Interactive Exclusion Manager**:
   - Displays all active folder exclusions (`ExclusionPath`) and process exclusions (`ExclusionProcess`).
   - Interactive prompt to add new folder or process exclusions cleanly.
5. **Attack Surface Reduction (ASR) Rules Audit**:
   - Audits configured enterprise ASR rules via `Get-MpPreference`.
6. **Security Center WMI Auditor**:
   - Audits `root\SecurityCenter2` WMI namespace to inspect registered antivirus engine health.

---

## 📋 Interactive Approval Engine

Every action prompts the administrator in yellow before making any changes:
```text
>>> Test Microsoft Defender Cloud Protection & SmartScreen service reachability?
Proceed? (Y/N, Q to Cancel)
```
- Enter `Y` to execute the step.
- Enter `N` (or press Enter) to skip safely.
- Enter `Q` to abort and return.

---

## 💻 Execution

### Run Locally
Right-click `Run-As-Administrator.bat` and select **Run as Administrator**.

### Centralized Web Execution
Via the master toolkit entrypoint:
```powershell
irm https://toolkit.omvihub.in | iex
```
Select `[16] Windows Defender Signature Reset & Exclusion Engine`.
