# 🌐 OmviHub IT Toolkit - Web Bootstrapper & AWS Lightsail Deployment Guide

This guide explains how to deploy your 15-module Windows IT Toolkit to GitHub and AWS Lightsail (Nginx) so any administrator can launch it globally using the Massgrave-style one-liner:

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
   * Silently installs or synchronizes the modules directly into **`C:\OmviHub_Toolkit\`**.
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
└── ... (all 15 tool folders)
```

### 2. Verify your ZIP Download URL
In your public repo, your default download URL will be:
`https://github.com/omvihub/Windows-IT-Toolkit/archive/refs/heads/main.zip`

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

### 4. Configure Nginx (`/etc/nginx/sites-available/toolkit.omvihub.in`)
Open your Nginx configuration file:
```bash
sudo nano /etc/nginx/sites-available/toolkit.omvihub.in
```

Paste the following production-ready configuration block:
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

    # 1. Ensure .ps1 files are always served as UTF-8 Plain Text without caching issues
    location ~ \.ps1$ {
        default_type text/plain;
        add_header Content-Type "text/plain; charset=utf-8";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }

    # 2. Handle /install.ps1 and /get shortcuts
    location = /get {
        rewrite ^/get$ /install.ps1 last;
    }

    # 3. MASSGRAVE ROUTING TRICK:
    # If root (/) is requested by PowerShell or curl/wget -> serve install.ps1
    # If root (/) is requested by a Web Browser -> redirect to GitHub repo!
    location = / {
        if ($http_user_agent ~* "PowerShell|curl|wget|WindowsPowerShell") {
            rewrite ^/$ /install.ps1 last;
        }
        return 301 https://github.com/omvihub/Windows-IT-Toolkit;
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

## 🚀 Step 3: Global Execution Test!

You are now ready to test! On any Windows 10, Windows 11, or Windows Server machine anywhere in the world, open PowerShell as Administrator and run:

```powershell
irm https://toolkit.omvihub.in | iex
```

### What you will see:
1. **UAC Elevation**: If not running as Admin, it prompts for elevation.
2. **Silent Download & Extraction**: Downloads `main.zip` and extracts to `C:\OmviHub_Toolkit\`.
3. **Data Preservation**: Preserves all existing `reports\`, `backups\`, and `.csv` files.
4. **Master Console**: Instantly launches the 15-module interactive command center!
