# 🗄️ Database & SQL Server Port & Protocol Repair Suite

A production-grade, interactive administration suite to unblock database firewall ports, enable SQL Server Browser service, and configure TCP/IP network protocols for Microsoft SQL Server, MySQL, PostgreSQL, Oracle, MongoDB, and Redis.

---

## 📊 Database Port Matrix

| Database Engine | Standard Ports | Protocol | Purpose |
| :--- | :--- | :--- | :--- |
| **MS SQL Server (Default Instance)** | `1433` | TCP | Database Connections |
| **MS SQL Browser Service** | `1434` | UDP | Resolves Named Instances (`\SQLEXPRESS`) |
| **MySQL / MariaDB** | `3306` | TCP | Database Connections |
| **PostgreSQL** | `5432` | TCP | Database Connections |
| **Oracle Listener** | `1521` | TCP | Database Connections |
| **MongoDB** | `27017` | TCP | Database Connections |
| **Redis Cache** | `6379` | TCP | Key-Value Store Connections |

---

## 📋 Interactive Approval Engine

Every action prompts the administrator in yellow before making any changes:
```text
>>> Set SQL Server Browser Service to Automatic startup & start it (Required for SQLEXPRESS named instances)?
Proceed? (Y/N)
```
- Enter `Y` to execute the step.
- Enter `N` (or press Enter) to skip safely.

---

## 💻 Execution

### Run Locally
Right-click `Run-As-Administrator.bat` and select **Run as Administrator**.

### Web One-Liner
```powershell
[Net.ServicePointManager]::SecurityProtocol = 3072; irm https://toolkit.omvihub.in/sql | iex
```
