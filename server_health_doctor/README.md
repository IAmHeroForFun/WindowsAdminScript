# 🩺 Windows Server Health & Misconfiguration Doctor

A diagnostic tool designed specifically for Windows Server infrastructure (Server 2008 R2 through Server 2025). Hunts for silent faults, bad IT habits, and critical misconfigurations that cause network outages, Active Directory replication breaks, or backup failures.

---

## 🔎 Out-of-the-Ordinary Faults Scanned

1. **DNS Resolver Misconfigurations (The #1 Active Directory Killer)**:
   Detects if someone accidentally put public DNS (`8.8.8.8`, `1.1.1.1`) or a router gateway IP directly on a Domain Controller or domain-joined server's network card. Also flags production servers using dynamic DHCP instead of static IPs.
2. **Time Synchronization & NTP Health**:
   Verifies that the `w32time` service is running and properly syncing. If server time drifts >5 minutes, Kerberos authentication and domain logins break immediately.
3. **Disabled Windows Firewall Profiles**:
   Flags vulnerable servers where Domain, Private, or Public firewall profiles have been turned off completely.
4. **Volume Shadow Copy (VSS) & Disk Hardware Faults**:
   Checks VSS backup engine health and scans the System Event Log for recent disk controller or NTFS hardware errors logged over the past 7 days.
5. **TLS 1.2 Security Protocol Check**:
   Verifies that modern TLS 1.2 encryption hasn't been disabled in the registry.
6. **Unexpected Shutdown & Crash Audit**:
   Scans event logs for unexpected reboots or power loss events (Event ID 6008/41).

---

## 🚀 How to Run
Double-click **`run_server_doctor.bat`**. Full diagnostic case reports are automatically generated inside `reports\`.
