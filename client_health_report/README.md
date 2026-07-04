# 💼 MSP One-Click Client Health Report Generator [Option 13]

A boardroom and CEO-ready executive IT health assessment generator engineered for Managed Service Providers (MSPs). Rapidly audits server health, disk storage capacity, disaster recovery backup status, endpoint cybersecurity hardening, Windows update compliance, SSL/TLS certificate expiration, system event logs, firewall profiles, and antivirus status.

---

## 📑 Executive Report Sections

1. **Executive Summary**: High-level boardroom narrative summarizing infrastructure risk, compliance status, and operational stability.
2. **Executive Health Score**: A weighted 0–100 numerical gauge categorizing the client into `EXCELLENT`, `NEEDS ATTENTION`, or `CRITICAL RISK`.
3. **Risk Breakdown Grid**: Visual scorecard tallying Critical, High, Medium, and Low risk findings.
4. **Critical & Security Findings Table**: Detailed itemization of vulnerable protocols (SMBv1), disabled firewall profiles, outdated antivirus signatures, unpatched OS CVEs, and expiring SSL certificates.
5. **Backup Readiness & Server Health Table**: Verification of Volume Shadow Copy Service (VSS), local snapshot counts, and drive storage capacity.
6. **Engineering Recommendations**: Concrete, actionable remediation steps for every finding.

---

## 🖨️ Boardroom Print-to-PDF Formatting

The generated HTML report (`reports\executive_report.html`) includes custom print media stylesheets (`@media print`). 
To convert this report into a paying business client deliverable:
1. Open `reports\executive_report.html` in Microsoft Edge or Google Chrome.
2. Press **Ctrl+P** (or right-click -> Print).
3. Select **Save as PDF**.
4. Enable **Background graphics** under More settings.
5. Click **Save** to generate `executive_report.pdf`!

---

## 📂 Generated Deliverables (`reports\`)

* `executive_report.html`: Print-to-PDF boardroom executive HTML report.
* `findings.csv`: Full spreadsheet export of all audit items, severities, and engineering advice.
