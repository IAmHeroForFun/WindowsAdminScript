# 08. Server Security & Configuration Audit (GPOs, Accounts, Shares)

## 📌 Executive Summary
The **Server Security & Configuration Audit Tool** (`server_audit/audit_server.ps1`) performs an exhaustive forensic audit on Windows Server (2008 R2 through 2025) and Domain Controllers / Member Servers. It audits Domain and Local User Accounts, password policies, stale accounts, SMB file share permissions, Active Directory roles, NTP time synchronization, and Windows Server Backup health.

---

## 🏗️ Architecture & Script Mapping

- **Primary Script**: `server_audit/audit_server.ps1`
- **Batch Launcher**: `server_audit/run_server_audit.bat`
- **Master Menu Option**: `[8]`
- **Direct Web Shortcut**: `irm https://toolkit.omvihub.in/server | iex`

---

## 🔍 Forensic Audit Checkpoints

1. **User Accounts & Security Posture**:
   - Enumerates Local & Active Directory user accounts.
   - Evaluates password age, expired accounts, `PasswordNeverExpires` flags, and disabled status.
   - Identifies stale accounts inactive for >90 days.

2. **Privileged Group Memberships**:
   - Audits members of `Administrators`, `Domain Admins`, `Enterprise Admins`, `Schema Admins`, and `Remote Desktop Users`.

3. **SMB File Shares & NTFS Access Rights**:
   - Queries all shared folders (`Win32_Share`).
   - Flags dangerous public shares (`Everyone` or `Anonymous` with Full Control or Change permissions).

4. **Active Directory & Domain Role Health**:
   - Detects if host is a Primary Domain Controller (PDC), Backup DC, or Member Server.
   - Inspects FSMO role holders (`netdom query fsmo`).

5. **NTP Time Synchronization Health**:
   - Queries `w32tm /query /status` to check NTP stratum, reference source, and time offset drift.

6. **Windows Server Backup & Shadow Copy Status**:
   - Audits `wbadmin get status` and VSS Shadow Storage allocation.

---

## 📊 Generated Reports

- **Server Audit Summary**: `C:\SysMaster\reports\server_audit_report_<ComputerName>_<Timestamp>.txt`
- **User Account Inventory CSV**: `C:\SysMaster\reports\server_users_<ComputerName>.csv`
- **SMB Shares Security CSV**: `C:\SysMaster\reports\server_shares_<ComputerName>.csv`
