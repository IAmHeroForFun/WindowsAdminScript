# 16. Web Bootstrap, TLS/SSL & Nginx Deployment Guide

## 📌 Executive Summary
The **Web Bootstrap & Cloud In-Memory Deployment Architecture** allows any Windows client to execute the toolkit or any sub-module instantly via a short one-liner command (similar to Microsoft Massgrave `irm https://massgrave.dev/get | iex`).

This infrastructure is powered by an Nginx reverse proxy running on AWS Lightsail, protected with Let's Encrypt TLS 1.2/1.3 SSL certificates, routing PowerShell requests dynamically to raw GitHub repositories.

---

## 🌐 How the Web One-Liner Works

```mermaid
sequenceDiagram
    autonumber
    actor Admin as SysAdmin (Windows PC)
    participant Nginx as Nginx Proxy (toolkit.omvihub.in)
    participant GitHub as GitHub Raw (IAmHeroForFun/WindowsAdminScript)
    
    Admin->>Nginx: irm https://toolkit.omvihub.in | iex
    Note over Nginx: Inspects User-Agent header (PowerShell/curl)
    Nginx->>GitHub: GET /master/install.ps1
    GitHub-->>Nginx: Returns install.ps1 code
    Nginx-->>Admin: Streams script payload in-memory
    Note over Admin: install.ps1 downloads zip to C:\SysMaster,<br/>launches windows_it_toolkit.ps1,<br/>and auto-cleans on exit!
```

---

## 🔒 Nginx Reverse Proxy Configuration (`toolkit.conf`)

Located on the Linux host / container:
- **Server Name**: `toolkit.omvihub.in`
- **Port**: `443 ssl` (HTTP redirects to HTTPS 301)
- **SSL Certificates**: `/etc/letsencrypt/live/toolkit.omvihub.in/fullchain.pem`
- **Compression Rule**: `proxy_set_header Accept-Encoding "";` (Prevents gzip encoding issues inside PowerShell's `Invoke-RestMethod`).
- **Dynamic Sub-filter Engine**: Rewrites URL shortcuts (e.g. `/pst`, `/search`, `/office`, `/sql`, `/sharing`) to pre-set `$Tool` variables in `install.ps1` before streaming to the client.

---

## 🚀 Server Deployment & Verification Commands

### Test Nginx Configuration:
```bash
docker exec omvi_blog-nginx-1 nginx -t
```

### Reload Nginx Service:
```bash
docker exec omvi_blog-nginx-1 nginx -s reload
```

### Live Test from CachyOS / Linux:
```bash
curl -sSL -A "PowerShell" https://toolkit.omvihub.in/pst | head -n 25
```
