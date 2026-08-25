# 14. SQL Database Port & Protocol Diagnostic Fixer (1433, 3306, 5432)

## 📌 Executive Summary
The **SQL Database Port & Protocol Diagnostic & Repair Suite** (`sql_database_fixer/`) resolves remote database connection timeouts, blocked firewall ports, and disabled TCP/IP network protocols for Microsoft SQL Server, MySQL, PostgreSQL, Oracle, MongoDB, and Redis.

---

## 🏗️ Architecture & Component Files

- **Main Coordinator**: `sql_database_fixer/fix_sql.ps1`
- **Firewall Fixer**: `sql_database_fixer/Fix-SQL-Firewall-Ports.ps1`
- **MSSQL Protocol Fixer**: `sql_database_fixer/Fix-MSSQL-Services-Protocols.ps1`
- **Connectivity Auditor**: `sql_database_fixer/Audit-SQL-Connectivity.ps1`
- **Batch Launcher**: `sql_database_fixer/Run-As-Administrator.bat`
- **Master Menu Option**: `[14]`
- **Direct Web Shortcut**: `irm https://toolkit.omvihub.in/sql | iex`

---

## 🔧 Database Ports Unblocked

Creates named Windows Firewall inbound rules with proper protocol specifications:

| Database Engine | Port Number | Protocol | Purpose |
| :--- | :--- | :--- | :--- |
| **Microsoft SQL Server (Default)** | `1433` | TCP | Standard SQL Engine listener |
| **SQL Server Browser Service** | `1434` | UDP | Named instance port discovery |
| **MySQL / MariaDB** | `3306` | TCP | Standard client connection port |
| **PostgreSQL** | `5432` | TCP | Standard client connection port |
| **Oracle Database** | `1521` | TCP | TNS listener port |
| **MongoDB** | `27017` | TCP | MongoDB mongod listener |
| **Redis Cache** | `6379` | TCP | Redis key-value store |

---

## ⚙️ Microsoft SQL Server Protocol & Service Repair

1. **SQL Server Browser Service**:
   - Enables and starts `SQLBrowser` (Required for connecting to named instances like `SERVER\SQLEXPRESS`).

2. **TCP/IP Protocol Enabling**:
   - Inspects SQL Server WMI namespaces (`root\Microsoft\SqlServer\ComputerManagement*`) and registry hives (`HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\<Instance>\MSSQLServer\SuperSocketNetLib\Tcp`).
   - Sets `Enabled = 1` and configures `TcpPort = 1433` / `TcpDynamicPorts = ""` for all detected SQL instances.

3. **Active Listening Socket Audit**:
   - Inspects `netstat` to confirm which database processes (`sqlservr.exe`, `mysqld.exe`, `postgres.exe`) are actively bound to `0.0.0.0` or `127.0.0.1`.
