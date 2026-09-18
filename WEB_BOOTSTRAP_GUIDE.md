# 🌐 OmviHub IT Toolkit - Web Bootstrapper & AWS Lightsail Deployment Guide

This guide explains how to deploy your 15-module Windows IT Toolkit to GitHub and AWS Lightsail (Nginx) so any administrator can launch it globally using the clean single Massgrave-style one-liner:

```powershell
irm https://toolkit.omvihub.in | iex
```

---

## 🏗️ How the Architecture Works

1. When an administrator executes `irm https://toolkit.omvihub.in | iex`, AWS Lightsail Nginx detects PowerShell and proxies the lightweight **`install.ps1` bootstrapper script** directly from your GitHub repository.
2. The bootstrapper script:
   * **Elevation**: Automatically requests Administrator UAC elevation if not already elevated.
   * **Security**: Enforces TLS 1.2 / 1.3 cryptographic protocols.
   * **Acquisition**: Downloads the latest release archive from GitHub and synchronizes the modules directly into **`C:\SysMaster\`**.
   * **Data Preservation**: Updates all script logic while strictly protecting and preserving 100% of existing historical inventories (`inventory.csv`), reports, and logs.
   * **Execution**: Unblocks files and immediately launches the interactive Master Menu console (`windows_it_toolkit.ps1`).
   * **Cleanup**: Upon exit (`Q`), temporary scripts are cleaned up, leaving only your generated reports in `C:\SysMaster\reports\`.

---

## 🐙 Step 1: Repository Structure on GitHub

Ensure your public GitHub repository (`https://github.com/IAmHeroForFun/WindowsAdminScript`) contains the complete 15-tool hierarchy:

```text
WindowsAdminScript/
├── README.md
├── WEB_BOOTSTRAP_GUIDE.md
├── toolkit.conf
├── install.ps1                    # 🌟 Cloud bootstrapper
├── windows_it_toolkit.ps1         # Master menu script
├── Windows_IT_Toolkit.bat         # Local double-click launcher
├── inventory/                     # Local, subnet & remote inventory
├── network_auditor/               # 6-phase socket & port auditor
├── slowness_debug/                # Sherlock Slow PC debugger & tune-up
├── search_fixer/                  # Windows & Outlook search repair
├── win11_debloater/               # Windows 11 enterprise debloater
├── server_audit/                  # Server security & forensic auditor
├── printer_manager/               # Spooler, queues & driver isolation
├── network_sharing_fixer/         # Windows 10/11 SMB & USB printer sharing
├── rdp_fixer/                     # RDP & CredSSP Oracle repair
├── office_fixer/                  # MS Office diagnostic & PST recovery
├── sql_database_fixer/            # Database ports & MSSQL protocols
├── antivirus_fixer/               # Defender reset & exclusions
└── guides/                        # Technical documentation library
```

---

## ☁️ Step 2: AWS Lightsail Nginx Setup

Connect to your AWS Lightsail Linux instance via SSH and configure Nginx:

### 1. Web Root Directory
```bash
sudo mkdir -p /var/www/toolkit
sudo chown -R www-data:www-data /var/www/toolkit
```

### 2. Ensure Valid SSL / TLS (Certbot)
PowerShell's `irm` requires a trusted HTTPS certificate:
```bash
sudo apt update && sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d toolkit.omvihub.in
```

### 3. Apply Zero-Maintenance Nginx Configuration
Edit `/etc/nginx/conf.d/toolkit.conf` (or `/etc/nginx/sites-available/toolkit.omvihub.in`):

```nginx
server {
    server_name toolkit.omvihub.in;
    root /var/www/toolkit;

    # SSL Certificates managed by Certbot
    listen [::]:443 ssl ipv6only=on;
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/toolkit.omvihub.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/toolkit.omvihub.in/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Global Proxy Settings for GitHub Raw Content
    proxy_ssl_server_name on;
    proxy_ssl_name raw.githubusercontent.com;
    proxy_http_version 1.1;
    proxy_set_header Host raw.githubusercontent.com;
    proxy_set_header Connection "";
    proxy_set_header Accept-Encoding ""; # Prevents gzip compression issues in PowerShell

    # Root Install Script Handler
    location = /install.ps1 {
        proxy_pass https://raw.githubusercontent.com/IAmHeroForFun/WindowsAdminScript/master/install.ps1;
        default_type text/plain;
        add_header Content-Type "text/plain; charset=utf-8";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }

    # Massgrave Root Router (PowerShell gets install script, Browser gets GitHub repo)
    location = / {
        if ($http_user_agent ~* "PowerShell|curl|wget|WindowsPowerShell") {
            rewrite ^/$ /install.ps1 last;
        }
        return 301 https://github.com/IAmHeroForFun/WindowsAdminScript;
    }
}

server {
    if ($host = toolkit.omvihub.in) {
        return 301 https://$host$request_uri;
    }

    listen 80;
    listen [::]:80;
    server_name toolkit.omvihub.in;
    return 404;
}
```

### 4. Test & Reload Nginx
```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🚀 Step 3: Global Execution

On any Windows 7–11 or Windows Server machine worldwide, open PowerShell and run:

```powershell
irm https://toolkit.omvihub.in | iex
```

The bootstrapper runs automatically, elevates if needed, downloads the suite, launches the master menu with all 15 tools, and cleanly exits when done.
