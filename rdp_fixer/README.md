# 🔑 Remote Desktop (RDP) & CredSSP Encryption Oracle Repair Suite

A production-grade, interactive administration suite to diagnose and resolve Windows Remote Desktop (RDP) connection failures, CredSSP Encryption Oracle Remediation errors (`0x800706BA`), Windows 11 session freezes, black screens, firewall blocks, and custom RDP port configurations.

---

## 🚀 Solved Errors & Issues

1. **CredSSP Encryption Oracle Remediation Error (`0x800706BA` / `0x80090308`)**:
   - Occurs when attempting to connect to an unpatched or legacy RDP server from Windows 10/11.
   - Fixed by configuring `AllowEncryptionOracle = 2` (Mitigated/Vulnerable mode).
2. **Windows 11 RDP Session Freeze / UDP Disconnects**:
   - Known Windows 11 22H2/23H2 bug causing RDP to randomly disconnect or freeze over UDP transport.
   - Fixed by setting `fClientDisableUDP = 1` and `SelectTransport = 1` (forces reliable TCP).
3. **Black Screen Hangs upon Connection**:
   - Buggy graphics/WDDM drivers causing a black screen on connect.
   - Fixed by forcing the stable XDDM display driver (`fEnableWddmDriver = 0`).
4. **RDP Service Disabled / Blocked**:
   - Fixed by setting `fDenyTSConnections = 0` in registry and enabling Windows Firewall *Remote Desktop* rules.
5. **Network Level Authentication (NLA) Mismatch**:
   - Resolves legacy client lockouts by adjusting `UserAuthentication`.
6. **Pre-flight Target Connectivity Probe**:
   - Interactive probe testing remote host IP/DNS and TCP port reachability before initiating sessions.
7. **Custom RDP Port Requirements**:
   - Allows inspecting and changing the default RDP port `3389` to any custom port (e.g. `3390`), updating registry and Windows Firewall automatically.

---

## 📋 Interactive Approval Engine

Every action prompts the administrator in yellow before making any changes:
```text
>>> Disable RDP UDP transport (fClientDisableUDP = 1) to fix Windows 11 RDP session freezes/disconnects?
Proceed? (Y/N, Q to Cancel)
```
- Enter `Y` to execute the step.
- Enter `N` (or press Enter) to skip safely.
- Enter `Q` to cancel and return.

---

## 💻 Execution

### Run Locally
Right-click `Run-As-Administrator.bat` and select **Run as Administrator**.

### Centralized Web Execution
Via the master toolkit entrypoint:
```powershell
irm https://toolkit.omvihub.in | iex
```
Select `[12] Remote Desktop (RDP) & CredSSP Connection Fixer`.
