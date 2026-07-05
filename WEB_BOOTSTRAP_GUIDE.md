# 🌐 OmviHub IT Toolkit - Web Bootstrapper & AWS Lightsail Deployment Guide

This guide explains how to deploy your 16-module Windows IT Toolkit to GitHub and AWS Lightsail (Nginx) so any administrator can launch it globally using the Massgrave-style one-liner:

```powershell
irm https://toolkit.omvihub.in | iex
# OR
irm https://toolkit.omvihub.in/install.ps1 | iex
```

---

## 🏗️ How the Architecture Works

1. When a user runs `irm https://toolkit.omvihub.in | iex`, AWS Lightsail Nginx serves the lightweight **`install.ps1` bootstrapper script**.
2. That bootstrapper script:
   * Requests **Administrator UAC elevation** if not already elevated.
   * Enforces **TLS 1.2 / 1.3** security protocols.
   * Downloads the latest toolkit release archive (`main.zip`) from GitHub (or directly from AWS Lightsail).
   * Silently installs or synchronizes the modules directly into **`C:\SysMaster\`**.
   * **Intelligent Preservation**: Updates all script logic while strictly protecting and preserving 100% of existing historical reports (`history.json`), inventories (`inventory.csv`), and HTML dashboards!
   * Unblocks all files and launches the interactive Master Menu console!

---

## 🐙 Step 1: What to do on GitHub

### 1. Push your Toolkit to GitHub
Create a public repository (e.g., `https://github.com/omvihub/Windows-IT-Toolkit`) and push this entire directory structure:
```text
Windows-IT-Toolkit/
├── README.md
├── install.ps1                    # 🌟 The bootstrapper script
├── windows_it_toolkit.ps1         # Master menu script
├── Windows_IT_Toolkit.bat         # Master double-click launcher
├── inventory/
├── network_mapper/
├── uptime_monitor/
├── msp_platform/
├── winre_recovery_assistant/
├── software_deployer/
└── ... (all 16 tool folders)
```

### 2. Verify your ZIP Download URL
In your public repo, your default download URL will be:
`https://github.com/IAmHeroForFun/WindowsAdminScript/archive/refs/heads/master.zip`

*(Note: If your GitHub username or repository name is different, open `install.ps1` and update line 15: `$DownloadUrl = "https://..."`).*

---

## ☁️ Step 2: What to do on AWS Lightsail (Nginx Setup)

Connect to your AWS Lightsail Linux instance (Ubuntu / Debian / Amazon Linux) via SSH and follow these exact steps:

### 1. Create the Web Root Directory
Create the folder where Nginx will store your bootstrapper script:
```bash
sudo mkdir -p /var/www/toolkit
sudo chown -R www-data:www-data /var/www/toolkit
```

### 2. Copy `install.ps1` to AWS Lightsail
Upload `install.ps1` from your local machine to `/var/www/toolkit/install.ps1` on your AWS server (using SFTP/SCP or by cloning your git repo directly on the server):
```bash
cd /var/www/toolkit
sudo wget https://raw.githubusercontent.com/omvihub/Windows-IT-Toolkit/main/install.ps1 -O install.ps1
```
*(If you want AWS Lightsail to serve the ZIP directly instead of GitHub, also download or copy `main.zip` into `/var/www/toolkit/toolkit.zip` and update `$DownloadUrl` in `install.ps1` to `https://toolkit.omvihub.in/toolkit.zip`!)*

### 3. Ensure Valid SSL / TLS (HTTPS is Mandatory)
PowerShell `irm` requires a valid SSL certificate. Use Certbot to generate a Let's Encrypt certificate:
```bash
sudo apt update && sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d toolkit.omvihub.in
```

### 4. Locate & Configure Your Nginx Server Block
Depending on your AWS Lightsail OS image, your Nginx configuration file is located in one of these paths:

- **Amazon Linux 2 / Amazon Linux 2023 / RHEL / CentOS**: 
  `/etc/nginx/conf.d/toolkit.conf` (or edit `/etc/nginx/nginx.conf` directly)
- **Bitnami Stack (WordPress / LAMP / Nginx)**: 
  `/opt/bitnami/nginx/conf/server_blocks/toolkit.conf` (or `/opt/bitnami/nginx/conf/bitnami/bitnami-ssl.conf`)
- **Ubuntu / Debian (Standard Nginx)**: 
  `/etc/nginx/sites-available/toolkit.omvihub.in` (symlinked to `sites-enabled`)

> **🔍 Don't know where your Nginx file is?** Run this command in SSH to find your exact config path instantly:
> ```bash
> sudo nginx -t
> # Or find all active server blocks:
> sudo grep -rnw "server_name" /etc/nginx /opt/bitnami 2>/dev/null
> ```

Open your Nginx configuration file in an editor (e.g., `sudo nano /path/to/your/nginx.conf`):
Paste the following **Zero-Maintenance Auto-Fetch Nginx Configuration** inside your file (this proxies directly to GitHub so you NEVER have to manually log into AWS or run `wget` again!):
```nginx
server {
    listen 80;
    listen 443 ssl http2;
    server_name toolkit.omvihub.in;

    # SSL Certificates (managed by Certbot)
    ssl_certificate /etc/letsencrypt/live/toolkit.omvihub.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/toolkit.omvihub.in/privkey.pem;

    root /var/www/toolkit;
    index install.ps1 index.html;

    # 1. MASTER TOOLKIT BOOTSTRAPPER (irm https://toolkit.omvihub.in | iex)
    location = /install.ps1 {
        rewrite ^ /IAmHeroForFun/WindowsAdminScript/master/install.ps1 break;
        proxy_pass https://raw.githubusercontent.com;
        proxy_set_header Host raw.githubusercontent.com;
        proxy_ssl_server_name on;
        default_type text/plain;
        add_header Content-Type "text/plain; charset=utf-8";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
    location = /get { rewrite ^ /install.ps1 last; }

    # 2. DIRECT SHORTCUT: WPF Software Deployer (irm https://toolkit.omvihub.in/deploy | iex)
    location ~* ^/(deploy|deploy\.ps1|software)$ {
        rewrite ^ /IAmHeroForFun/WindowsAdminScript/master/deploy.ps1 break;
        proxy_pass https://raw.githubusercontent.com;
        proxy_set_header Host raw.githubusercontent.com;
        proxy_ssl_server_name on;
        default_type text/plain;
        add_header Content-Type "text/plain; charset=utf-8";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }

    # 3. DIRECT SHORTCUT: WinRE Recovery Assistant (irm https://toolkit.omvihub.in/winre | iex)
    location ~* ^/(winre|winre\.ps1|recovery)$ {
        rewrite ^ /IAmHeroForFun/WindowsAdminScript/master/winre.ps1 break;
        proxy_pass https://raw.githubusercontent.com;
        proxy_set_header Host raw.githubusercontent.com;
        proxy_ssl_server_name on;
        default_type text/plain;
        add_header Content-Type "text/plain; charset=utf-8";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }

    # 4. DIRECT SHORTCUT: Client Health Doctor (irm https://toolkit.omvihub.in/health | iex)
    location ~* ^/(health|health\.ps1|doctor)$ {
        rewrite ^ /IAmHeroForFun/WindowsAdminScript/master/health.ps1 break;
        proxy_pass https://raw.githubusercontent.com;
        proxy_set_header Host raw.githubusercontent.com;
        proxy_ssl_server_name on;
        default_type text/plain;
        add_header Content-Type "text/plain; charset=utf-8";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }

    # 5. DIRECT SHORTCUT: Hardware Inventory Scanner (irm https://toolkit.omvihub.in/inventory | iex)
    location ~* ^/(inventory|inventory\.ps1|scan)$ {
        rewrite ^ /IAmHeroForFun/WindowsAdminScript/master/inventory.ps1 break;
        proxy_pass https://raw.githubusercontent.com;
        proxy_set_header Host raw.githubusercontent.com;
        proxy_ssl_server_name on;
        default_type text/plain;
        add_header Content-Type "text/plain; charset=utf-8";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }

    # 6. MASSGRAVE ROUTING TRICK:
    # If root (/) is requested by PowerShell or curl/wget -> serve install.ps1 via live proxy!
    # If root (/) is requested by a Web Browser -> redirect to GitHub repo!
    location = / {
        if ($http_user_agent ~* "PowerShell|curl|wget|WindowsPowerShell") {
            rewrite ^/$ /install.ps1 last;
        }
        return 301 https://github.com/IAmHeroForFun/WindowsAdminScript;
    }
}
```

### 5. Test and Reload Nginx
Test your configuration for syntax errors and restart Nginx:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🚀 Step 3: Global Execution Test & Multi-Tool Shortcuts!

You are now ready to test! On any Windows 10, Windows 11, or Windows Server machine anywhere in the world, open PowerShell as Administrator and run any of your global one-liners:

### 🌟 1. Master IT Toolkit Console (All 16 Modules)
```powershell
irm https://toolkit.omvihub.in | iex
# or: irm https://toolkit.omvihub.in/install.ps1 | iex
```

### ⚡ 2. WPF Software Deployer (Direct Launch)
```powershell
irm https://toolkit.omvihub.in/deploy | iex
# or: irm https://toolkit.omvihub.in/deploy.ps1 | iex
```

### 🚑 3. WinRE Boot Repair Assistant (Direct Launch)
```powershell
irm https://toolkit.omvihub.in/winre | iex
# or: irm https://toolkit.omvihub.in/winre.ps1 | iex
```

### 🩺 4. MSP Client Health Doctor (Direct Launch)
```powershell
irm https://toolkit.omvihub.in/health | iex
# or: irm https://toolkit.omvihub.in/health.ps1 | iex
```

### 💻 5. Hardware Inventory Scanner (Direct Launch)
```powershell
irm https://toolkit.omvihub.in/inventory | iex
# or: irm https://toolkit.omvihub.in/inventory.ps1 | iex
```

> **🎉 Pro Tip**: Because Nginx is configured as a Live GitHub Proxy, whenever you push changes to your GitHub repo, ALL of these shortcuts update globally in real-time without ever touching your AWS server!
