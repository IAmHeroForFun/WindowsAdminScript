# 🔗 Windows 10/11 Shared Drive & USB Shared Printer Repair Suite

A production-grade, interactive administration suite to diagnose and resolve Windows 10 & 11 local network sharing issues, guest SMB access blocks, and USB shared printer connection failures.

---

## 🚀 Solved Errors & Issues

1. **Shared Drive & NAS Access Errors**:
   - `0x800704f8`: Unauthenticated guest access blocked by organization security policy.
   - `0x80070035`: Network path not found (Network discovery services stopped).
   - `0x80004005`: Unspecified network error on SMB shares.

2. **USB Shared Printer & Point and Print Errors**:
   - `0x0000011b`: Print Spooler RPC authentication privacy error (KB5005565 / KB5005568).
   - `0x00000709`: Could not connect to shared printer (RPC binding failure).
   - `0x00000bc4`: No printers were found (Windows 11 RPC over TCP default blocking).
   - `0x0000007c`: Invalid level error during driver binding (CopyFiles policy block).
   - `Error 5 / Access Denied`: Point and Print restrictions blocking non-admin users from installing shared printer drivers.

---

## 🛡️ Security-First Point & Print Relaxation

Rather than permanently unhardening security by default, the repair suite features:
- **Temporary Point & Print Relaxation**: Temporarily drops driver installation restrictions (`RestrictDriverInstallationToAdministrators = 0`), binds to the remote shared printer (`Add-Printer` / `rundll32 printui.dll`), and **automatically restores the original security posture in a `finally` block**.
- **Permanent Point & Print Bypass**: Kept as an optional fallback when continuous non-admin driver management is required.
- **Domain GPO Guard**: Detects if the machine is Active Directory domain-joined and warns before making changes that could be reverted by Domain Group Policy.
- **Target UNC Path Pre-Flight Diagnostic**: Probes DNS name resolution, SMB (port 445), RPC (port 135), and the share namespace before making registry changes.

---

## 📋 Interactive Approval Engine

Every fix prompts the administrator in yellow:
```text
>>> Enable Insecure Guest Logons (AllowInsecureGuestAuth = 1) to access unauthenticated NAS/PC shares?
Proceed? (Y/N, Q to Cancel)
```
- Enter `Y` to apply the fix.
- Enter `N` (or press Enter) to skip the fix safely.
- Enter `Q` to abort the routine and return immediately.

---

## 💻 Execution

### Run Locally
Right-click `Run-As-Administrator.bat` and select **Run as Administrator**.

### Centralized Web Execution
Via the master toolkit entrypoint:
```powershell
irm https://toolkit.omvihub.in | iex
```
Select `[11] Network Sharing & Printer Sharing Fixer`.
