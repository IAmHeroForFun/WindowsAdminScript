# 🔑 Remote Desktop (RDP) & CredSSP Encryption Oracle Repair Suite

A production-grade, interactive administration suite to diagnose and resolve Windows Remote Desktop (RDP) connection failures, CredSSP Encryption Oracle Remediation errors (`0x800706BA`), disabled RDP service flags, firewall blocks, and custom RDP port configurations.

---

## 🚀 Solved Errors & Issues

1. **CredSSP Encryption Oracle Remediation Error (`0x800706BA` / `0x80090308`)**:
   - Occurs when attempting to connect to an unpatched or legacy RDP server from Windows 10/11.
   - Fixed by configuring `AllowEncryptionOracle = 2` (Mitigated/Vulnerable mode).
2. **RDP Service Disabled / Blocked**:
   - Fixed by setting `fDenyTSConnections = 0` in registry and enabling Windows Firewall *Remote Desktop* rules.
3. **Custom RDP Port Requirements**:
   - Allows inspecting and changing the default RDP port `3389` to any custom port (e.g. `3390`), updating registry and Windows Firewall automatically.

---

## 📋 Interactive Approval Engine

Every action prompts the administrator in yellow before making any changes:
```text
>>> Mitigate CredSSP Encryption Oracle Remediation errors (Fixes RDP error 0x800706BA / 0x80090308)?
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
[Net.ServicePointManager]::SecurityProtocol = 3072; irm https://toolkit.omvihub.in/rdp | iex
```
