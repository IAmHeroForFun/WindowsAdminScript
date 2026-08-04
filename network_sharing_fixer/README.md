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
   - `0x00000709`: Could not connect to shared printer.
   - `0x0000007c`: Invalid level error during driver binding.
   - Point and Print restrictions blocking non-admin users from installing shared printer drivers.

---

## 📋 Interactive Approval Engine

Every fix prompts the administrator in yellow:
```text
>>> Enable Insecure Guest Logons (AllowInsecureGuestAuth = 1) to access unauthenticated NAS/PC shares?
Proceed? (Y/N)
```
- Enter `Y` to apply the fix.
- Enter `N` (or press Enter) to skip the fix safely.

---

## 💻 Execution

### Run Locally
Right-click `Run-As-Administrator.bat` and select **Run as Administrator**.

### Web One-Liner
```powershell
[Net.ServicePointManager]::SecurityProtocol = 3072; irm https://toolkit.omvihub.in/sharing | iex
```
