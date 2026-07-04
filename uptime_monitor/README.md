# ⏱️ NOC Uptime & Availability Monitoring Platform [Option 12]

A PRTG and Uptime Kuma-style infrastructure uptime and SLA tracking engine. Continuously polls external internet DNS, local default gateways, domain controllers, file server SMB ports, HTTPS portals, and VPN endpoints. Stores cumulative telemetry in a local JSON database and compiles responsive HTML reports with availability sparklines.

---

## 🔍 Monitored Infrastructure Endpoints

* **Internet Routing**: Probes Google Public DNS (`8.8.8.8`) and Cloudflare (`1.1.1.1`) via ICMP.
* **Network Gateway**: Automatically discovers and monitors the local default subnet router.
* **DNS Servers**: Checks active DNS resolvers assigned to the primary network adapter.
* **Domain Controllers**: Checks ICMP ping and LDAP Kerberos authentication port `389` against the active domain controller (`$env:LOGONSERVER`).
* **SMB File Servers**: Probes local and remote file server SMB listening port `445`.
* **Web Portals**: Probes external web endpoints (`https://www.microsoft.com`, `https://www.google.com`) via HTTP HEAD requests.

---

## 📊 Generated Reports (`reports\`)

* `daily_report.html`: 24-hour executive SLA and availability sparkline scorecard.
* `weekly_report.html`: 7-day weekly availability and packet loss trend report.
* `monthly_report.html`: 30-day monthly SLA compliance scorecard.
* `uptime_dashboard.html`: Master NOC command center dashboard tracking all historical data.
* `history.json`: Persistent local JSON historical database.
* `uptime_history.csv`: CSV spreadsheet append-log of every polling cycle.
