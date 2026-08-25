# 11. Remote Desktop (RDP) & CredSSP Connection Fixer

## 📌 Executive Summary
The **Remote Desktop (RDP) & CredSSP Connection Repair Suite** (`rdp_fixer/`) fixes Remote Desktop connectivity failures, authentication errors, and CredSSP Encryption Oracle Remediation blocks (`0x80004005` / `0x800706BA` / `0x80090308`). It also allows enabling RDP, managing Network Level Authentication (NLA), and changing the RDP listening port.

---

## 🏗️ Architecture & Component Files

- **Main Coordinator**: `rdp_fixer/fix_rdp.ps1`
- **CredSSP Fixer**: `rdp_fixer/Fix-CredSSP-Oracle.ps1`
- **RDP Service Enabler**: `rdp_fixer/Enable-RDP-Service.ps1`
- **Port Migrator**: `rdp_fixer/Configure-RDP-Port.ps1`
- **Batch Launcher**: `rdp_fixer/Run-As-Administrator.bat`
- **Master Menu Option**: `[11]`
- **Direct Web Shortcut**: `irm https://toolkit.omvihub.in/rdp | iex`

---

## 🔧 Technical Remediation Details

### 1. CredSSP Encryption Oracle Remediation (`Fix-CredSSP-Oracle.ps1`):
- Target Key: `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters`
- DWORD Value: `AllowEncryptionOracle = 2` ("Vulnerable / Mitigated")
- Benefit: Allows the client computer to establish RDP sessions with servers that have not yet applied the May 2018 CredSSP security update, resolving the error: *"An authentication error has occurred. The function requested is not supported... Encryption Oracle Remediation"*.

### 2. Enable Remote Desktop Services (`Enable-RDP-Service.ps1`):
- **Enable Terminal Server**: Sets `fDenyTSConnections = 0` in `HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server`.
- **NLA Configuration**: Offers option to toggle Network Level Authentication (`UserAuthentication = 0` or `1` in `WinStations\RDP-Tcp`).
- **Service Configuration**: Sets `TermService` (Remote Desktop Services) to Automatic and starts it.
- **Firewall Rules**: Enables the built-in `Remote Desktop` inbound firewall rule group.

### 3. Custom RDP Port Migration (`Configure-RDP-Port.ps1`):
- Displays current RDP port (default 3389).
- Allows changing to a custom port (e.g. 3390, 50000).
- Updates `PortNumber` DWORD in `HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`.
- Creates a dedicated inbound Windows Firewall rule for the new custom port.
