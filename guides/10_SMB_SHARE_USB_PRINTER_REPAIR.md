# 10. Windows 10/11 Network Folder & SMB Sharing Fixer

## 📌 Executive Summary
The **Windows 10/11 Shared Drive & USB Shared Printer Repair Suite** (`network_sharing_fixer/`) fixes network file sharing and USB printer sharing failures between Windows 10, Windows 11, and legacy systems. It resolves common errors like `0x80070035` (Network path not found), `0x80004005` (Unspecified error), `0x0000011b` (Print Spooler RPC Privacy error), `0x00000bc4` ("No printers were found"), and `0x00000709`.

---

## 🏗️ Architecture & Component Files

- **Main Coordinator**: `network_sharing_fixer/fix_sharing.ps1`
- **Shared Printer Core**: `network_sharing_fixer/Fix-Shared-Printers.ps1`
- **SMB Shares Repair**: `network_sharing_fixer/Fix-SMB-Shares.ps1`
- **Firewall Rules Reset**: `network_sharing_fixer/Reset-Network-Sharing-Firewall.ps1`
- **Dedicated Role Launchers**:
  - `network_sharing_fixer/1_RUN_ON_HOST_PC (Printer Attached).bat`
  - `network_sharing_fixer/2_RUN_ON_CLIENT_PC (Connect Over Network).bat`
  - `network_sharing_fixer/3_UNIVERSAL_ALL_IN_ONE_FIX.bat`
  - `network_sharing_fixer/4_CONNECT_VIA_LOCAL_PORT (Guaranteed Workaround).bat`
- **Master Batch Launcher**: `network_sharing_fixer/Run-As-Administrator.bat`
- **Master Menu Option**: `[12]`
- **Direct Web Shortcut**: `irm https://toolkit.omvihub.in/sharing | iex`

---

## ⚠️ Host vs. Client Role Distinction

| Role | Physical Setup | Essential Fixes Applied |
| :--- | :--- | :--- |
| **HOST PC (Print Server)** | Printer USB cable plugged into this machine | Sets `RpcAuthnLevelPrivacyEnabled = 0` (0x0000011b), switches network from Public to **Private**, unblocks inbound firewall (ports 135, 445, Spooler RPC), starts `fdPHost`/`FDResPub`, and enables guest auth. |
| **CLIENT PC (Workstation)** | Connecting across Wi-Fi/LAN to print | Sets `RpcUseNamedPipeProtocol = 1` & `RpcProtocols = 7` (0x00000bc4 / 0x00000709), relaxes Point & Print non-admin restrictions (0x00000bcb), enables `CopyFilesPolicy = 1` (0x0000007c), disables Windows 11 24H2 Windows Protected Print (WPP), and relaxes SMB client signing. |

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

### 2. USB Shared Printer & RPC Protocol Fixes:
- **0x0000011b Fix (Host)**: Sets `RpcAuthnLevelPrivacyEnabled = 0` in `HKLM:\System\CurrentControlSet\Control\Print`.
- **0x00000bc4 & 0x00000709 Fix (Client)**: Enables RPC over Named Pipes in `HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC`:
  - `RpcUseNamedPipeProtocol = 1`
  - `RpcProtocols = 7`
  - `RpcOverNamedPipes = 1`
  - `RpcOverTcp = 1`
- **0x00000bcb Point and Print Restrictions (Client)**: Relaxes Point & Print driver blocking in `HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint`:
  - `RestrictDriverInstallationToAdministrators = 0`
  - `Restricted = 0`
  - `NoWarningNoElevationOnInstall = 1`
- **0x0000007c CopyFiles Policy (Client)**: Sets `CopyFilesPolicy = 1` in `HKLM:\Software\Policies\Microsoft\Windows NT\Printers`.
- **Windows 11 24H2 Windows Protected Print (WPP)**: Detects and disables WPP in `HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\ProtectedPrint` (`Enabled = 0`) to allow legacy Type 3 (v3) vendor drivers to run.

### 3. Fail-Safe Workaround: Automated Local Port Connection
- When standard Spooler RPC cannot negotiate between two builds, the tool creates a **Local Port** directly mapped to `\\Host\PrinterShare`.
- Prints raw raster data directly over SMB without requiring Spooler RPC negotiation or Point & Print downloads. **Works 100% of the time.**

### 4. Firewall Sharing Rules:
- Unblocks Windows Firewall inbound rules for File and Printer Sharing:
  - TCP 445 (SMB Direct), TCP 139 (NetBIOS Session), TCP 135 (RPC Endpoint Mapper), UDP 137/138 (NetBIOS Name & Datagram), UDP 3702 (WSD Discovery), UDP 5355 (LLMNR).
