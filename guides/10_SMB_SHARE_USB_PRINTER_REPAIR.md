# 10. Windows 10/11 Network Folder & SMB Sharing Fixer

## 📌 Executive Summary
The **Windows 10/11 Shared Drive & USB Shared Printer Repair Suite** (`network_sharing_fixer/`) fixes network file sharing and USB printer sharing failures between Windows 10, Windows 11, and legacy systems. It resolves common errors like `0x80070035` (Network path not found), `0x80004005` (Unspecified error), and `0x0000011b` (Print Spooler RPC Privacy error).

---

## 🏗️ Architecture & Component Files

- **Main Coordinator**: `network_sharing_fixer/fix_sharing.ps1`
- **SMB Shares Repair**: `network_sharing_fixer/Fix-SMB-Shares.ps1`
- **Shared Printer Fixer**: `network_sharing_fixer/Fix-Shared-Printers.ps1`
- **Firewall Rules Reset**: `network_sharing_fixer/Reset-Network-Sharing-Firewall.ps1`
- **Batch Launcher**: `network_sharing_fixer/Run-As-Administrator.bat`
- **Master Menu Option**: `[10]`
- **Direct Web Shortcut**: `irm https://toolkit.omvihub.in/sharing | iex`

---

## 🔧 Technical Remediation Details

### 1. SMB Shared Folder Access:
- **Insecure Guest Logons**: Enables `AllowInsecureGuestAuth = 1` in `HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters` (Required for Windows 10/11 connecting to guest NAS / Workgroup shares).
- **SMB Client Signing**: Sets `RequireSecuritySignature = 0` and `EnableSecuritySignature = 1` to resolve strict signing handshake drops.
- **Network Discovery Services**: Configures startup to Automatic and starts:
  - `fdPHost` (Function Discovery Provider Host)
  - `FDResPub` (Function Discovery Resource Publication)
  - `lmhosts` (TCP/IP NetBIOS Helper)
  - `LanmanServer` & `LanmanWorkstation`

### 2. USB Shared Printer & 0x0000011b Fix:
- **Print Spooler RPC Privacy Key**: Sets `RpcAuthnLevelPrivacyEnabled = 0` in `HKLM:\System\CurrentControlSet\Control\Print` (Remediates the infamous September 2021 `0x0000011b` patch error).
- **Point and Print Restrictions**: Disables Point & Print driver blocking in `HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint`:
  - `Restricted = 0`
  - `UpdatePromptSettings = 0`

### 3. Firewall Sharing Rules:
- Unblocks Windows Firewall inbound rules for File and Printer Sharing:
  - TCP 445 (SMB Direct), TCP 139 (NetBIOS Session), UDP 137/138 (NetBIOS Name & Datagram), UDP 3702 (WSD Discovery), UDP 5355 (LLMNR).
