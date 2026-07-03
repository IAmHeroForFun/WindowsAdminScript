# 🏛️ Main Server Forensic & Configuration Audit Suite

Engineered for IT administrators taking over an Active Directory Domain Controller or Main Server from previous IT staff. Automatically uncovers hidden configurations, user accounts, and group policies and exports them into human-readable spreadsheets and web reports.

---

## 📊 Extracted Forensic Reports (`reports\`)

1. **User Accounts & Admin Group Audit (`users_and_admins_audit.csv`)**:
   Extracts every Active Directory or Local user account, full name, enabled/disabled status, password expiration policies, last logon timestamp, and exact group memberships (Domain Admins, Local Administrators).
2. **Readable Group Policy Report (`GPO_Readable_Report.html`)**:
   Generates a structured, interactive web page (`gpresult /h`) detailing every single custom registry setting, mapped drive, printer, firewall policy, and security restriction pushed out across the domain.
3. **Network Exposure Audit (`network_shares_audit.csv`)**:
   Lists all shared server folders, network paths, and descriptions.
4. **Custom Services & Server Roles (`auto_starting_services.csv`)**:
   Audits non-standard background services configured to start automatically at boot.
5. **Scheduled Tasks Extraction (`custom_scheduled_tasks.csv`)**:
   Extracts automated background scripts or maintenance tasks left behind in Windows Task Scheduler.
