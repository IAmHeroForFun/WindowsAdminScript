# 🔐 Ultimate Deep Infrastructure & Security Diagnostic Suite

Performs enterprise-grade infrastructure and cybersecurity inspection across Windows Server and Windows 7-11 PCs. Audits AD domain replication, local machine SSL certificates, SMBv1 ransomware exposure, active TCP/UDP socket collisions, and stuck pending reboots.

---

## 🔎 What It Audits

1. **Active Directory Replication & DC Health**:
   Executes `repadmin /replsummary` and `dcdiag` on Domain Controllers to detect silent domain synchronization failures.
2. **SSL/TLS Certificate Expiration Scan**:
   Scans `Cert:\LocalMachine\My` for certificates expiring within the next 30 days or already expired.
3. **Legacy SMBv1 Ransomware Vulnerability Check**:
   Audits the registry and optional features to ensure legacy SMBv1 protocol is disabled, protecting against WannaCry/EternalBlue attacks.
4. **Active Socket & Port Mapping**:
   Maps all active TCP/UDP listening ports (`netstat -ano`) to their exact Process IDs (PIDs) and executable names.
5. **Stuck Pending Reboot Audit**:
   Checks Windows Servicing (`CBS RebootPending`), Windows Update (`RebootRequired`), and `Session Manager` (`PendingFileRenameOperations`) for hidden reboot locks.
6. **Crash Dump & Pagefile Readiness**:
   Verifies that Windows Crash Control is configured to generate memory dumps if a Blue Screen occurs.

---

## 📊 Output Case Files (`reports\`)
* `ssl_certificates_audit.csv`: Expiring/expired SSL certificates.
* `listening_ports_map.csv`: Complete map of listening ports and PIDs.
* `deep_diagnostic_report.txt`: Full diagnostic summary text report.
