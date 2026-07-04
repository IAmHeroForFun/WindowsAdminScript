<#
.SYNOPSIS
    OmviHub Cloud Software Deployer - Ultimate 100% Genuine Ninite-Style Graphical Application (173 Master Catalog)
.DESCRIPTION
    A complete, standalone graphical application engineered in native PowerShell (Windows Forms) that replicates
    and surpasses the authentic Ninite experience:
    
    1. Selection Screen: 4-Column checkbox layout categorized across 14 authentic Ninite software categories (173 Applications).
    2. Runtimes & VC++ Redists: Dedicated category for all Visual C++ Redistributables (2005 through 2022 x86/x64), .NET Frameworks, .NET Desktop Runtimes, Java JDK/JRE, and DirectX!
    3. Developer Tools & IDEs: Comprehensive suite including VS Code, VS 2022 Community, IntelliJ IDEA, PyCharm, Eclipse, Android Studio, Git, Docker, Podman, Python, Node.js, DBeaver, and Postman!
    4. Messaging, Imaging, Utilities & Gaming: Loaded with 10+ options per category including Discord, Slack, Telegram, Signal, WhatsApp, ShareX, Greenshot, Blender, Figma, Krita, Sysinternals, TreeSize, WizTree, PowerToys, HWiNFO, Steam, Epic Games, and more!
    5. Responsive Design: Compact starting size (1050x660), resizable borders, enabled Maximize/Minimize buttons, and dynamically anchored action buttons and progress bar.
    6. Zero AWS Bandwidth Used: Uses native Microsoft Winget and Chocolatey to download directly from official vendor CDNs at gigabit edge speeds.
#>

[CmdletBinding()]
param (
    [string[]]$Packages = @(),
    [string]$Preset = "",
    [switch]$NoGUI,
    [switch]$ForceInstall
)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------
# 1. ADMIN ELEVATION CHECK
# ---------------------------------------------------------
function Test-IsAdmin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Host "==========================================================================" -ForegroundColor DarkYellow
    Write-Host "  [ELEVATION REQUIRED] OmviHub Ninite Software Deployer requires Admin rights." -ForegroundColor Yellow
    Write-Host "  Requesting UAC Elevation... Please click 'Yes' on the prompt." -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor DarkYellow
    
    $CommandLine = "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    if ($Packages.Count -gt 0) { $CommandLine += " -Packages $($Packages -join ',')" }
    if ($Preset) { $CommandLine += " -Preset $Preset" }
    if ($NoGUI) { $CommandLine += " -NoGUI" }
    
    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList $CommandLine -Verb RunAs -Wait
        exit
    } catch {
        Write-Host "`n[ERROR] Administrative elevation failed or cancelled." -ForegroundColor Red
        Write-Host "`nPress Enter to exit..." -ForegroundColor DarkGray; [void](Read-Host)
        exit 1
    }
}

Clear-Host
Write-Host "Initializing OmviHub Ninite-Style Cloud Software Deployer (173 Ultimate Master Catalog)..." -ForegroundColor Cyan

# ---------------------------------------------------------
# 2. PACKAGE MANAGER ENGINE BOOTSTRAPPER
# ---------------------------------------------------------
$PackageManager = "None"
if (Get-Command winget -ErrorAction SilentlyContinue) {
    $PackageManager = "Winget"
} elseif (Get-Command choco -ErrorAction SilentlyContinue) {
    $PackageManager = "Chocolatey"
} else {
    Write-Host "[!] Neither Winget nor Chocolatey detected. Bootstrapping Chocolatey..." -ForegroundColor Yellow
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        $env:Path += ";$env:ALLUSERSPROFILE\chocolatey\bin"
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            $PackageManager = "Chocolatey"
        } else {
            throw "Chocolatey command not found after installation."
        }
    } catch {
        Write-Host "[ERROR] Failed to bootstrap package manager: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please install Microsoft Winget or Chocolatey manually." -ForegroundColor Yellow
        Write-Host "`nPress Enter to exit..." -ForegroundColor DarkGray; [void](Read-Host)
        exit 1
    }
}

# ---------------------------------------------------------
# 3. MASTER SOFTWARE CATALOG (173 ULTIMATE ENTERPRISE APPLICATIONS)
# ---------------------------------------------------------
$Catalog = @(
    # ================= COLUMN 0 =================
    # 1. Web Browsers (Col 0)
    [PSCustomObject]@{ Id = 1;  Category = "Web Browsers"; Name = "Google Chrome"; WingetID = "Google.Chrome"; ChocoID = "googlechrome"; Description = "Fast, secure web browser by Google"; Col = 0 },
    [PSCustomObject]@{ Id = 2;  Category = "Web Browsers"; Name = "Mozilla Firefox"; WingetID = "Mozilla.Firefox"; ChocoID = "firefox"; Description = "Open-source privacy-focused web browser"; Col = 0 },
    [PSCustomObject]@{ Id = 3;  Category = "Web Browsers"; Name = "Microsoft Edge"; WingetID = "Microsoft.Edge"; ChocoID = "microsoft-edge"; Description = "Chromium-based enterprise web browser"; Col = 0 },
    [PSCustomObject]@{ Id = 4;  Category = "Web Browsers"; Name = "Brave Browser"; WingetID = "Brave.Brave"; ChocoID = "brave"; Description = "Privacy-first ad-blocking web browser"; Col = 0 },
    [PSCustomObject]@{ Id = 5;  Category = "Web Browsers"; Name = "Opera Browser"; WingetID = "Opera.Opera"; ChocoID = "opera"; Description = "Fast web browser with built-in VPN and ad blocker"; Col = 0 },
    [PSCustomObject]@{ Id = 6;  Category = "Web Browsers"; Name = "Opera GX Gaming"; WingetID = "Opera.OperaGX"; ChocoID = "opera-gx"; Description = "Browser built specifically for gamers with CPU/RAM limiters"; Col = 0 },
    [PSCustomObject]@{ Id = 7;  Category = "Web Browsers"; Name = "Vivaldi Browser"; WingetID = "VivaldiTechnologies.Vivaldi"; ChocoID = "vivaldi"; Description = "Highly customizable web browser for power users"; Col = 0 },
    [PSCustomObject]@{ Id = 8;  Category = "Web Browsers"; Name = "Tor Browser"; WingetID = "TheTorProject.TorBrowser"; ChocoID = "tor-browser"; Description = "Anonymous browsing network for absolute privacy"; Col = 0 },
    [PSCustomObject]@{ Id = 9;  Category = "Web Browsers"; Name = "LibreWolf Privacy"; WingetID = "LibreWolf.LibreWolf"; ChocoID = "librewolf"; Description = "Custom Firefox build focused on privacy, security and freedom"; Col = 0 },

    # 2. Messaging & Communication (Col 0)
    [PSCustomObject]@{ Id = 10; Category = "Messaging & Communication"; Name = "Zoom Workplace"; WingetID = "Zoom.Zoom"; ChocoID = "zoom"; Description = "Video conferencing and enterprise meetings"; Col = 0 },
    [PSCustomObject]@{ Id = 11; Category = "Messaging & Communication"; Name = "Microsoft Teams"; WingetID = "Microsoft.Teams"; ChocoID = "microsoft-teams"; Description = "Enterprise messaging and collaboration"; Col = 0 },
    [PSCustomObject]@{ Id = 12; Category = "Messaging & Communication"; Name = "Discord"; WingetID = "Discord.Discord"; ChocoID = "discord"; Description = "Voice, video, and text communication"; Col = 0 },
    [PSCustomObject]@{ Id = 13; Category = "Messaging & Communication"; Name = "Slack"; WingetID = "SlackTechnologies.Slack"; ChocoID = "slack"; Description = "Team communication and workflow collaboration"; Col = 0 },
    [PSCustomObject]@{ Id = 14; Category = "Messaging & Communication"; Name = "Telegram Desktop"; WingetID = "Telegram.TelegramDesktop"; ChocoID = "telegram"; Description = "Fast and secure cloud-based messaging"; Col = 0 },
    [PSCustomObject]@{ Id = 15; Category = "Messaging & Communication"; Name = "WhatsApp Desktop"; WingetID = "WhatsApp.WhatsApp"; ChocoID = "whatsapp"; Description = "Desktop messaging client for WhatsApp"; Col = 0 },
    [PSCustomObject]@{ Id = 16; Category = "Messaging & Communication"; Name = "Signal Private Messenger"; WingetID = "Open Whisper Systems.Signal"; ChocoID = "signal"; Description = "End-to-end encrypted messaging across platforms"; Col = 0 },
    [PSCustomObject]@{ Id = 17; Category = "Messaging & Communication"; Name = "Skype"; WingetID = "Microsoft.Skype"; ChocoID = "skype"; Description = "Video and voice calling platform"; Col = 0 },
    [PSCustomObject]@{ Id = 18; Category = "Messaging & Communication"; Name = "Thunderbird Email"; WingetID = "Mozilla.Thunderbird"; ChocoID = "thunderbird"; Description = "Open-source email, newsfeed, and chat client"; Col = 0 },
    [PSCustomObject]@{ Id = 19; Category = "Messaging & Communication"; Name = "Viber Desktop"; WingetID = "Viber.Viber"; ChocoID = "viber"; Description = "Free calls and messages on PC"; Col = 0 },
    [PSCustomObject]@{ Id = 20; Category = "Messaging & Communication"; Name = "Element Matrix Client"; WingetID = "Element.Element"; ChocoID = "element-desktop"; Description = "Secure and decentralized communication platform"; Col = 0 },
    [PSCustomObject]@{ Id = 21; Category = "Messaging & Communication"; Name = "Pidgin Instant Messenger"; WingetID = "Pidgin.Pidgin"; ChocoID = "pidgin"; Description = "Universal chat client supporting multi-protocol messaging"; Col = 0 },
    [PSCustomObject]@{ Id = 22; Category = "Messaging & Communication"; Name = "HexChat IRC Client"; WingetID = "HexChat.HexChat"; ChocoID = "hexchat"; Description = "Graphical IRC chat client based on XChat"; Col = 0 },
    [PSCustomObject]@{ Id = 23; Category = "Messaging & Communication"; Name = "eM Client Email"; WingetID = "eMClient.eMClient"; ChocoID = "emclient"; Description = "Full-featured email client with calendar and contacts"; Col = 0 },

    # 3. Cloud Storage & Backup (Col 0)
    [PSCustomObject]@{ Id = 24; Category = "Cloud Storage & Backup"; Name = "Google Drive"; WingetID = "Google.GoogleDrive"; ChocoID = "googledrive"; Description = "Cloud storage sync and backup client"; Col = 0 },
    [PSCustomObject]@{ Id = 25; Category = "Cloud Storage & Backup"; Name = "Microsoft OneDrive"; WingetID = "Microsoft.OneDrive"; ChocoID = "onedrive"; Description = "Microsoft cloud storage and file sync"; Col = 0 },
    [PSCustomObject]@{ Id = 26; Category = "Cloud Storage & Backup"; Name = "Dropbox"; WingetID = "Dropbox.Dropbox"; ChocoID = "dropbox"; Description = "Popular cloud workspace and file synchronization"; Col = 0 },
    [PSCustomObject]@{ Id = 27; Category = "Cloud Storage & Backup"; Name = "Nextcloud Desktop"; WingetID = "Nextcloud.NextcloudDesktop"; ChocoID = "nextcloud-client"; Description = "Self-hosted private cloud storage synchronization"; Col = 0 },
    [PSCustomObject]@{ Id = 28; Category = "Cloud Storage & Backup"; Name = "Duplicati Backup"; WingetID = "Duplicati.Duplicati"; ChocoID = "duplicati"; Description = "Encrypted bandwidth-efficient cloud backup"; Col = 0 },
    [PSCustomObject]@{ Id = 29; Category = "Cloud Storage & Backup"; Name = "Cobian Reflector Backup"; WingetID = "Cobian.Reflector"; ChocoID = "cobian-reflector"; Description = "Advanced multi-threaded file backup program"; Col = 0 },
    [PSCustomObject]@{ Id = 30; Category = "Cloud Storage & Backup"; Name = "Macrium Reflect Free/Home"; WingetID = "Macrium.Reflect"; ChocoID = "macriumreflect"; Description = "Complete disk imaging and system recovery solution"; Col = 0 },

    # 4. Runtimes & VC++ Redists (Col 0) - THE HOLY GRAIL OF NINITE!
    [PSCustomObject]@{ Id = 31; Category = "Runtimes & VC++ Redists"; Name = "MS Visual C++ 2015-2022 x64"; WingetID = "Microsoft.VCRedist.2015+.x64"; ChocoID = "vcredist140"; Description = "Microsoft Visual C++ 2015-2022 Redistributable (64-bit)"; Col = 0 },
    [PSCustomObject]@{ Id = 32; Category = "Runtimes & VC++ Redists"; Name = "MS Visual C++ 2015-2022 x86"; WingetID = "Microsoft.VCRedist.2015+.x86"; ChocoID = "vcredist140-x86"; Description = "Microsoft Visual C++ 2015-2022 Redistributable (32-bit)"; Col = 0 },
    [PSCustomObject]@{ Id = 33; Category = "Runtimes & VC++ Redists"; Name = "MS Visual C++ 2013 x64"; WingetID = "Microsoft.VCRedist.2013.x64"; ChocoID = "vcredist2013"; Description = "Microsoft Visual C++ 2013 Redistributable Package"; Col = 0 },
    [PSCustomObject]@{ Id = 34; Category = "Runtimes & VC++ Redists"; Name = "MS Visual C++ 2012 x64"; WingetID = "Microsoft.VCRedist.2012.x64"; ChocoID = "vcredist2012"; Description = "Microsoft Visual C++ 2012 Redistributable Package"; Col = 0 },
    [PSCustomObject]@{ Id = 35; Category = "Runtimes & VC++ Redists"; Name = "MS Visual C++ 2010 x64"; WingetID = "Microsoft.VCRedist.2010.x64"; ChocoID = "vcredist2010"; Description = "Microsoft Visual C++ 2010 Redistributable Package"; Col = 0 },
    [PSCustomObject]@{ Id = 36; Category = "Runtimes & VC++ Redists"; Name = "MS Visual C++ 2008 x64"; WingetID = "Microsoft.VCRedist.2008.x64"; ChocoID = "vcredist2008"; Description = "Microsoft Visual C++ 2008 Redistributable Package"; Col = 0 },
    [PSCustomObject]@{ Id = 37; Category = "Runtimes & VC++ Redists"; Name = "MS Visual C++ 2005 x64"; WingetID = "Microsoft.VCRedist.2005.x64"; ChocoID = "vcredist2005"; Description = "Microsoft Visual C++ 2005 Redistributable Package"; Col = 0 },
    [PSCustomObject]@{ Id = 38; Category = "Runtimes & VC++ Redists"; Name = "Microsoft .NET Framework 4.8"; WingetID = "Microsoft.DotNet.Framework.4.8"; ChocoID = "dotnetfx"; Description = "Microsoft .NET Framework 4.8 Runtime for Windows apps"; Col = 0 },
    [PSCustomObject]@{ Id = 39; Category = "Runtimes & VC++ Redists"; Name = ".NET Desktop Runtime 8.0"; WingetID = "Microsoft.DotNet.DesktopRuntime.8"; ChocoID = "dotnet-desktopruntime"; Description = "Microsoft .NET 8 Desktop Runtime required for modern WPF/WinForms"; Col = 0 },
    [PSCustomObject]@{ Id = 40; Category = "Runtimes & VC++ Redists"; Name = ".NET Desktop Runtime 6.0"; WingetID = "Microsoft.DotNet.DesktopRuntime.6"; ChocoID = "dotnet-6.0-desktopruntime"; Description = "Microsoft .NET 6 Desktop Runtime LTS"; Col = 0 },
    [PSCustomObject]@{ Id = 41; Category = "Runtimes & VC++ Redists"; Name = "Microsoft .NET SDK 8.0"; WingetID = "Microsoft.DotNet.SDK.8"; ChocoID = "dotnet-sdk"; Description = "Complete .NET 8 Software Development Kit"; Col = 0 },
    [PSCustomObject]@{ Id = 42; Category = "Runtimes & VC++ Redists"; Name = "Oracle Java Runtime (JRE 8)"; WingetID = "Oracle.JavaRuntimeEnvironment"; ChocoID = "jre8"; Description = "Oracle Java Runtime Environment for legacy enterprise Java apps"; Col = 0 },
    [PSCustomObject]@{ Id = 43; Category = "Runtimes & VC++ Redists"; Name = "Temurin JDK 17 (LTS Java)"; WingetID = "EclipseAdaptium.Temurin.17.JDK"; ChocoID = "temurin17"; Description = "Open-source Java SE 17 LTS Runtime and JDK by Eclipse"; Col = 0 },
    [PSCustomObject]@{ Id = 44; Category = "Runtimes & VC++ Redists"; Name = "Temurin JDK 21 (LTS Java)"; WingetID = "EclipseAdaptium.Temurin.21.JDK"; ChocoID = "temurin21"; Description = "Latest Open-source Java SE 21 LTS Runtime and JDK"; Col = 0 },
    [PSCustomObject]@{ Id = 45; Category = "Runtimes & VC++ Redists"; Name = "DirectX End-User Runtime"; WingetID = "Microsoft.DirectX"; ChocoID = "directx"; Description = "Microsoft DirectX End-User Runtime for gaming and 3D graphics"; Col = 0 },

    # ================= COLUMN 1 =================
    # 5. Media & Audio Players (Col 1)
    [PSCustomObject]@{ Id = 46; Category = "Media & Audio Players"; Name = "VLC Media Player"; WingetID = "VideoLAN.VLC"; ChocoID = "vlc"; Description = "Universal multimedia video and audio player"; Col = 1 },
    [PSCustomObject]@{ Id = 47; Category = "Media & Audio Players"; Name = "Spotify"; WingetID = "Spotify.Spotify"; ChocoID = "spotify"; Description = "Music and podcast streaming service"; Col = 1 },
    [PSCustomObject]@{ Id = 48; Category = "Media & Audio Players"; Name = "OBS Studio"; WingetID = "OBSProject.OBSStudio"; ChocoID = "obs-studio"; Description = "Free and open source software for video recording and live streaming"; Col = 1 },
    [PSCustomObject]@{ Id = 49; Category = "Media & Audio Players"; Name = "Audacity Audio Editor"; WingetID = "Audacity.Audacity"; ChocoID = "audacity"; Description = "Multi-track audio recorder and editor"; Col = 1 },
    [PSCustomObject]@{ Id = 50; Category = "Media & Audio Players"; Name = "HandBrake Video Transcoder"; WingetID = "HandBrake.HandBrake"; ChocoID = "handbrake"; Description = "Open-source video transcoder and converter"; Col = 1 },
    [PSCustomObject]@{ Id = 51; Category = "Media & Audio Players"; Name = "K-Lite Codec Pack Full"; WingetID = "CodecGuide.K-LiteCodecPackFull"; ChocoID = "k-litecodecpackfull"; Description = "Comprehensive audio and video codec collection"; Col = 1 },
    [PSCustomObject]@{ Id = 52; Category = "Media & Audio Players"; Name = "K-Lite Codec Pack Mega"; WingetID = "CodecGuide.K-LiteCodecPackMega"; ChocoID = "k-litecodecpackmega"; Description = "The ultimate codec pack including encoding tools and filters"; Col = 1 },
    [PSCustomObject]@{ Id = 53; Category = "Media & Audio Players"; Name = "foobar2000"; WingetID = "PeterPawlowski.foobar2000"; ChocoID = "foobar2000"; Description = "Advanced audio player for the Windows platform"; Col = 1 },
    [PSCustomObject]@{ Id = 54; Category = "Media & Audio Players"; Name = "AIMP Audio Player"; WingetID = "AIMP.AIMP"; ChocoID = "aimp"; Description = "Lightweight audio player and music organizer"; Col = 1 },
    [PSCustomObject]@{ Id = 55; Category = "Media & Audio Players"; Name = "iTunes"; WingetID = "Apple.iTunes"; ChocoID = "itunes"; Description = "Apple music and iOS device management suite"; Col = 1 },
    [PSCustomObject]@{ Id = 56; Category = "Media & Audio Players"; Name = "GOM Player"; WingetID = "GOMLab.GOMPlayer"; ChocoID = "gomplayer"; Description = "Video player with built-in support for all popular codecs"; Col = 1 },
    [PSCustomObject]@{ Id = 57; Category = "Media & Audio Players"; Name = "PotPlayer Multimedia"; WingetID = "Daum.PotPlayer"; ChocoID = "potplayer"; Description = "Smooth multimedia video player with hardware acceleration"; Col = 1 },
    [PSCustomObject]@{ Id = 58; Category = "Media & Audio Players"; Name = "MusicBee Audio Player"; WingetID = "StevenMayall.MusicBee"; ChocoID = "musicbee"; Description = "Ultimate music manager and playback application"; Col = 1 },
    [PSCustomObject]@{ Id = 59; Category = "Media & Audio Players"; Name = "Winamp Legacy Player"; WingetID = "Radionomy.Winamp"; ChocoID = "winamp"; Description = "The legendary audio player that really whips the llama's ass"; Col = 1 },
    [PSCustomObject]@{ Id = 60; Category = "Media & Audio Players"; Name = "Shotcut Video Editor"; WingetID = "Meltytech.Shotcut"; ChocoID = "shotcut"; Description = "Free, open source, cross-platform video editor"; Col = 1 },

    # 6. Imaging & Graphic Design (Col 1)
    [PSCustomObject]@{ Id = 61; Category = "Imaging & Graphic Design"; Name = "ShareX Screen Capture"; WingetID = "ShareX.ShareX"; ChocoID = "sharex"; Description = "Screen capture, file sharing and productivity tool"; Col = 1 },
    [PSCustomObject]@{ Id = 62; Category = "Imaging & Graphic Design"; Name = "Greenshot Screenshot"; WingetID = "Greenshot.Greenshot"; ChocoID = "greenshot"; Description = "Lightweight screenshot software for Windows"; Col = 1 },
    [PSCustomObject]@{ Id = 63; Category = "Imaging & Graphic Design"; Name = "Lightshot Screenshot"; WingetID = "Skillbrains.Lightshot"; ChocoID = "lightshot"; Description = "Fast customizable screenshot tool with instant cloud upload"; Col = 1 },
    [PSCustomObject]@{ Id = 64; Category = "Imaging & Graphic Design"; Name = "PicPick Screen Capture"; WingetID = "NGWIN.PicPick"; ChocoID = "picpick"; Description = "All-in-one design tool with screen capture, color picker, and editor"; Col = 1 },
    [PSCustomObject]@{ Id = 65; Category = "Imaging & Graphic Design"; Name = "Paint.NET"; WingetID = "dotPDNLLC.paintdotnet"; ChocoID = "paint.net"; Description = "Simple and powerful raster image and photo editor"; Col = 1 },
    [PSCustomObject]@{ Id = 66; Category = "Imaging & Graphic Design"; Name = "GIMP Photo Editor"; WingetID = "GIMP.GIMP"; ChocoID = "gimp"; Description = "GNU Image Manipulation Program for professional photo retouching"; Col = 1 },
    [PSCustomObject]@{ Id = 67; Category = "Imaging & Graphic Design"; Name = "Inkscape Vector Graphics"; WingetID = "Inkscape.Inkscape"; ChocoID = "inkscape"; Description = "Professional vector graphics editor"; Col = 1 },
    [PSCustomObject]@{ Id = 68; Category = "Imaging & Graphic Design"; Name = "IrfanView Image Viewer"; WingetID = "IrfanSkiljan.IrfanView"; ChocoID = "irfanview"; Description = "Fast and compact graphic viewer and converter"; Col = 1 },
    [PSCustomObject]@{ Id = 69; Category = "Imaging & Graphic Design"; Name = "FastStone Image Viewer"; WingetID = "FastStone.ImageViewer"; ChocoID = "faststoneimageviewer"; Description = "Fast, stable, user-friendly image browser and editor"; Col = 1 },
    [PSCustomObject]@{ Id = 70; Category = "Imaging & Graphic Design"; Name = "XnView MP Image Viewer"; WingetID = "XnSoft.XnViewMP"; ChocoID = "xnviewmp"; Description = "Versatile and powerful photo viewer, image manager and resizer"; Col = 1 },
    [PSCustomObject]@{ Id = 71; Category = "Imaging & Graphic Design"; Name = "ImageGlass Image Viewer"; WingetID = "d2phap.ImageGlass"; ChocoID = "imageglass"; Description = "Lightweight, open-source photo viewer supporting 80+ formats"; Col = 1 },
    [PSCustomObject]@{ Id = 72; Category = "Imaging & Graphic Design"; Name = "Blender 3D Suite"; WingetID = "BlenderFoundation.Blender"; ChocoID = "blender"; Description = "Free and open source 3D creation suite"; Col = 1 },
    [PSCustomObject]@{ Id = 73; Category = "Imaging & Graphic Design"; Name = "Krita Digital Painting"; WingetID = "KDE.Krita"; ChocoID = "krita"; Description = "Professional free and open source painting program"; Col = 1 },
    [PSCustomObject]@{ Id = 74; Category = "Imaging & Graphic Design"; Name = "Figma Desktop"; WingetID = "Figma.Figma"; ChocoID = "figma"; Description = "Collaborative interface design and prototyping tool"; Col = 1 },
    [PSCustomObject]@{ Id = 75; Category = "Imaging & Graphic Design"; Name = "Scribus Publishing"; WingetID = "Scribus.Scribus"; ChocoID = "scribus"; Description = "Open source desktop publishing application"; Col = 1 },
    [PSCustomObject]@{ Id = 76; Category = "Imaging & Graphic Design"; Name = "Sweet Home 3D Design"; WingetID = "eTeks.SweetHome3D"; ChocoID = "sweethome3d"; Description = "Interior design application to draw floor plans and arrange furniture"; Col = 1 },

    # 7. Documents & Productivity (Col 1)
    [PSCustomObject]@{ Id = 77; Category = "Documents & Productivity"; Name = "LibreOffice Suite"; WingetID = "TheDocumentFoundation.LibreOffice"; ChocoID = "libreoffice-fresh"; Description = "Powerful open source office productivity suite"; Col = 1 },
    [PSCustomObject]@{ Id = 78; Category = "Documents & Productivity"; Name = "Apache OpenOffice"; WingetID = "Apache.OpenOffice"; ChocoID = "openoffice"; Description = "Leading open-source office software suite"; Col = 1 },
    [PSCustomObject]@{ Id = 79; Category = "Documents & Productivity"; Name = "Adobe Acrobat Reader"; WingetID = "Adobe.Acrobat.Reader.64-bit"; ChocoID = "adobereader"; Description = "Industry standard PDF viewing and printing software"; Col = 1 },
    [PSCustomObject]@{ Id = 80; Category = "Documents & Productivity"; Name = "Foxit PDF Reader"; WingetID = "Foxit.FoxitReader"; ChocoID = "foxitreader"; Description = "Fast, affordable, and secure PDF viewer"; Col = 1 },
    [PSCustomObject]@{ Id = 81; Category = "Documents & Productivity"; Name = "SumatraPDF Reader"; WingetID = "SumatraPDF.SumatraPDF"; ChocoID = "sumatrapdf"; Description = "Lightweight PDF, eBook, XPS, DjVu, CHM, Comic Book reader"; Col = 1 },
    [PSCustomObject]@{ Id = 82; Category = "Documents & Productivity"; Name = "PDFCreator"; WingetID = "pdfforge.PDFCreator"; ChocoID = "pdfcreator"; Description = "Convert any printable document to PDF"; Col = 1 },
    [PSCustomObject]@{ Id = 83; Category = "Documents & Productivity"; Name = "PDF24 Creator Suite"; WingetID = "GeekSoftware.PDF24Creator"; ChocoID = "pdf24"; Description = "Free and easy to use PDF solutions and utility toolbox"; Col = 1 },
    [PSCustomObject]@{ Id = 84; Category = "Documents & Productivity"; Name = "Notion Workspace"; WingetID = "Notion.Notion"; ChocoID = "notion"; Description = "All-in-one workspace for notes, docs, and project collaboration"; Col = 1 },
    [PSCustomObject]@{ Id = 85; Category = "Documents & Productivity"; Name = "Obsidian Knowledge Base"; WingetID = "Obsidian.Obsidian"; ChocoID = "obsidian"; Description = "Powerful knowledge base that works on local Markdown files"; Col = 1 },
    [PSCustomObject]@{ Id = 86; Category = "Documents & Productivity"; Name = "Joplin Note Taking"; WingetID = "Joplin.Joplin"; ChocoID = "joplin"; Description = "Open source note taking and to-do application with encryption"; Col = 1 },
    [PSCustomObject]@{ Id = 87; Category = "Documents & Productivity"; Name = "Evernote"; WingetID = "Evernote.Evernote"; ChocoID = "evernote"; Description = "Cross-platform note taking and task organization"; Col = 1 },
    [PSCustomObject]@{ Id = 88; Category = "Documents & Productivity"; Name = "Calibre eBook Manager"; WingetID = "calibre.calibre"; ChocoID = "calibre"; Description = "The comprehensive e-book software solution"; Col = 1 },
    [PSCustomObject]@{ Id = 89; Category = "Documents & Productivity"; Name = "CherryTree Notes"; WingetID = "GiuseppePenone.CherryTree"; ChocoID = "cherrytree"; Description = "Hierarchical note taking application featuring rich text and syntax highlighting"; Col = 1 },
    [PSCustomObject]@{ Id = 90; Category = "Documents & Productivity"; Name = "Zotero Citation Mgr"; WingetID = "Zotero.Zotero"; ChocoID = "zotero"; Description = "Free, easy-to-use tool to help you collect, organize, and cite research"; Col = 1 },

    # ================= COLUMN 2 =================
    # 8. Developer Tools & IDEs (Col 2)
    [PSCustomObject]@{ Id = 91;  Category = "Developer Tools & IDEs"; Name = "Visual Studio Code"; WingetID = "Microsoft.VisualStudioCode"; ChocoID = "vscode"; Description = "Lightweight source code editor by Microsoft"; Col = 2 },
    [PSCustomObject]@{ Id = 92;  Category = "Developer Tools & IDEs"; Name = "VS 2022 Community IDE"; WingetID = "Microsoft.VisualStudio.2022.Community"; ChocoID = "visualstudio2022community"; Description = "Full-featured, extensible IDE for building modern applications"; Col = 2 },
    [PSCustomObject]@{ Id = 93;  Category = "Developer Tools & IDEs"; Name = "IntelliJ IDEA Community"; WingetID = "JetBrains.IntelliJIDEA.Community"; ChocoID = "intellijidea-community"; Description = "Leading Java and Kotlin IDE by JetBrains"; Col = 2 },
    [PSCustomObject]@{ Id = 94;  Category = "Developer Tools & IDEs"; Name = "PyCharm Community IDE"; WingetID = "JetBrains.PyCharm.Community"; ChocoID = "pycharm-community"; Description = "Intelligent Python IDE by JetBrains"; Col = 2 },
    [PSCustomObject]@{ Id = 95;  Category = "Developer Tools & IDEs"; Name = "Eclipse IDE for Java"; WingetID = "EclipseFoundation.EclipseJava"; ChocoID = "eclipse"; Description = "Famous open source enterprise development environment"; Col = 2 },
    [PSCustomObject]@{ Id = 96;  Category = "Developer Tools & IDEs"; Name = "Android Studio IDE"; WingetID = "Google.AndroidStudio"; ChocoID = "androidstudio"; Description = "Official integrated development environment for Android app development"; Col = 2 },
    [PSCustomObject]@{ Id = 97;  Category = "Developer Tools & IDEs"; Name = "Git for Windows"; WingetID = "Git.Git"; ChocoID = "git"; Description = "Distributed version control system and bash"; Col = 2 },
    [PSCustomObject]@{ Id = 98;  Category = "Developer Tools & IDEs"; Name = "GitHub Desktop Client"; WingetID = "GitHub.GitHubDesktop"; ChocoID = "github-desktop"; Description = "Simple GUI client for managing GitHub repositories"; Col = 2 },
    [PSCustomObject]@{ Id = 99;  Category = "Developer Tools & IDEs"; Name = "TortoiseGit Windows Shell"; WingetID = "TortoiseGit.TortoiseGit"; ChocoID = "tortoisegit"; Description = "Windows Explorer interface for Git version control"; Col = 2 },
    [PSCustomObject]@{ Id = 100; Category = "Developer Tools & IDEs"; Name = "Python 3.12 Runtime"; WingetID = "Python.Python.3.12"; ChocoID = "python312"; Description = "Latest stable Python 3.12 programming language runtime"; Col = 2 },
    [PSCustomObject]@{ Id = 101; Category = "Developer Tools & IDEs"; Name = "Python 3.11 Runtime"; WingetID = "Python.Python.3.11"; ChocoID = "python311"; Description = "Widely compatible Python 3.11 programming runtime"; Col = 2 },
    [PSCustomObject]@{ Id = 102; Category = "Developer Tools & IDEs"; Name = "Node.js LTS Runtime"; WingetID = "OpenJS.NodeJS.LTS"; ChocoID = "nodejs-lts"; Description = "Long Term Support JavaScript runtime built on Chrome V8"; Col = 2 },
    [PSCustomObject]@{ Id = 103; Category = "Developer Tools & IDEs"; Name = "Node.js Current Runtime"; WingetID = "OpenJS.NodeJS"; ChocoID = "nodejs"; Description = "Latest Current JavaScript runtime with newest features"; Col = 2 },
    [PSCustomObject]@{ Id = 104; Category = "Developer Tools & IDEs"; Name = "Docker Desktop"; WingetID = "Docker.DockerDesktop"; ChocoID = "docker-desktop"; Description = "Containerization platform for building and sharing applications"; Col = 2 },
    [PSCustomObject]@{ Id = 105; Category = "Developer Tools & IDEs"; Name = "Podman Desktop"; WingetID = "RedHat.Podman-Desktop"; ChocoID = "podman-desktop"; Description = "Open source container and Kubernetes management without Docker daemon"; Col = 2 },
    [PSCustomObject]@{ Id = 106; Category = "Developer Tools & IDEs"; Name = "PowerShell 7 Core"; WingetID = "Microsoft.PowerShell"; ChocoID = "powershell-core"; Description = "Modern cross-platform PowerShell engine and automation shell"; Col = 2 },
    [PSCustomObject]@{ Id = 107; Category = "Developer Tools & IDEs"; Name = "Sublime Text 4 Editor"; WingetID = "SublimeHQ.SublimeText.4"; ChocoID = "sublimetext4"; Description = "Sophisticated text editor for code, markup and prose"; Col = 2 },
    [PSCustomObject]@{ Id = 108; Category = "Developer Tools & IDEs"; Name = "Notepad++ Code Editor"; WingetID = "Notepad++.Notepad++"; ChocoID = "notepadplusplus"; Description = "Advanced source code and configuration editor"; Col = 2 },
    [PSCustomObject]@{ Id = 109; Category = "Developer Tools & IDEs"; Name = "Postman API Client"; WingetID = "Postman.Postman"; ChocoID = "postman"; Description = "API platform for building, testing and using APIs"; Col = 2 },
    [PSCustomObject]@{ Id = 110; Category = "Developer Tools & IDEs"; Name = "DBeaver Community SQL"; WingetID = "dbeaver.dbeaver"; ChocoID = "dbeaver"; Description = "Universal database tool for developers and SQL administrators"; Col = 2 },
    [PSCustomObject]@{ Id = 111; Category = "Developer Tools & IDEs"; Name = "MySQL Workbench"; WingetID = "Oracle.MySQLWorkbench"; ChocoID = "mysql.workbench"; Description = "Unified visual tool for MySQL database architects and developers"; Col = 2 },
    [PSCustomObject]@{ Id = 112; Category = "Developer Tools & IDEs"; Name = "WinMerge Diff Tool"; WingetID = "WinMerge.WinMerge"; ChocoID = "winmerge"; Description = "Open source visual differencing and merging tool for files and folders"; Col = 2 },

    # 9. IT Admin & System Tools (Col 2)
    [PSCustomObject]@{ Id = 113; Category = "IT Admin & System Tools"; Name = "Sysinternals Suite"; WingetID = "Microsoft.SysinternalsSuite"; ChocoID = "sysinternals"; Description = "Advanced Windows system administration utilities"; Col = 2 },
    [PSCustomObject]@{ Id = 114; Category = "IT Admin & System Tools"; Name = "PuTTY SSH Client"; WingetID = "PuTTY.PuTTY"; ChocoID = "putty"; Description = "Telnet and SSH terminal client"; Col = 2 },
    [PSCustomObject]@{ Id = 115; Category = "IT Admin & System Tools"; Name = "WinSCP SFTP/SCP Client"; WingetID = "WinSCP.WinSCP"; ChocoID = "winscp"; Description = "SFTP, SCP, and FTP client for remote transfer"; Col = 2 },
    [PSCustomObject]@{ Id = 116; Category = "IT Admin & System Tools"; Name = "FileZilla FTP Client"; WingetID = "TimKosse.FileZilla.Client"; ChocoID = "filezilla"; Description = "Fast and reliable cross-platform FTP, FTPS and SFTP client"; Col = 2 },
    [PSCustomObject]@{ Id = 117; Category = "IT Admin & System Tools"; Name = "MobaXterm Terminal Server"; WingetID = "Mobatek.MobaXterm"; ChocoID = "mobaxterm"; Description = "Ultimate toolbox for remote computing with X11 server and tabbed SSH"; Col = 2 },
    [PSCustomObject]@{ Id = 118; Category = "IT Admin & System Tools"; Name = "TreeSize Free"; WingetID = "JAM Software.TreeSize.Free"; ChocoID = "treesizefree"; Description = "Disk space analyzer and folder hierarchy manager"; Col = 2 },
    [PSCustomObject]@{ Id = 119; Category = "IT Admin & System Tools"; Name = "WizTree Disk Analyzer"; WingetID = "AntibodySoftware.WizTree"; ChocoID = "wiztree"; Description = "The world's fastest disk space analyzer utility"; Col = 2 },
    [PSCustomObject]@{ Id = 120; Category = "IT Admin & System Tools"; Name = "WinDirStat Disk Usage"; WingetID = "WinDirStat.WinDirStat"; ChocoID = "windirstat"; Description = "Disk usage statistics viewer and cleanup tool with treemap"; Col = 2 },
    [PSCustomObject]@{ Id = 121; Category = "IT Admin & System Tools"; Name = "PowerToys"; WingetID = "Microsoft.PowerToys"; ChocoID = "powertoys"; Description = "Microsoft system tuning and productivity utilities"; Col = 2 },
    [PSCustomObject]@{ Id = 122; Category = "IT Admin & System Tools"; Name = "Windows Terminal"; WingetID = "Microsoft.WindowsTerminal"; ChocoID = "microsoft-windows-terminal"; Description = "Modern tabbed command-line console"; Col = 2 },
    [PSCustomObject]@{ Id = 123; Category = "IT Admin & System Tools"; Name = "HWiNFO64 Monitor"; WingetID = "REALiX.HWiNFO"; ChocoID = "hwinfo"; Description = "Comprehensive hardware analysis, monitoring and reporting"; Col = 2 },
    [PSCustomObject]@{ Id = 124; Category = "IT Admin & System Tools"; Name = "CPU-Z Hardware Info"; WingetID = "CPUID.CPU-Z"; ChocoID = "cpu-z"; Description = "System information software detailing CPU, RAM, and Motherboard"; Col = 2 },
    [PSCustomObject]@{ Id = 125; Category = "IT Admin & System Tools"; Name = "GPU-Z Graphics Info"; WingetID = "TechPowerUp.GPU-Z"; ChocoID = "gpu-z"; Description = "Video card and GPU hardware information utility"; Col = 2 },
    [PSCustomObject]@{ Id = 126; Category = "IT Admin & System Tools"; Name = "CrystalDiskInfo"; WingetID = "CrystalDewWorld.CrystalDiskInfo"; ChocoID = "crystaldiskinfo"; Description = "HDD/SSD health monitoring utility displaying SMART data"; Col = 2 },
    [PSCustomObject]@{ Id = 127; Category = "IT Admin & System Tools"; Name = "CrystalDiskMark"; WingetID = "CrystalDewWorld.CrystalDiskMark"; ChocoID = "crystaldiskmark"; Description = "Disk drive read/write performance benchmarking tool"; Col = 2 },
    [PSCustomObject]@{ Id = 128; Category = "IT Admin & System Tools"; Name = "Speccy System Spec"; WingetID = "Piriform.Speccy"; ChocoID = "speccy"; Description = "Fast, lightweight system information tool for PC hardware"; Col = 2 },
    [PSCustomObject]@{ Id = 129; Category = "IT Admin & System Tools"; Name = "Revo Uninstaller Free"; WingetID = "RevoUninstaller.RevoUninstaller"; ChocoID = "revo-uninstaller"; Description = "Thorough application uninstaller and registry cleanup tool"; Col = 2 },
    [PSCustomObject]@{ Id = 130; Category = "IT Admin & System Tools"; Name = "BleachBit Disk Cleaner"; WingetID = "BleachBit.BleachBit"; ChocoID = "bleachbit"; Description = "Free system cleaner to free disk space and guard privacy"; Col = 2 },
    [PSCustomObject]@{ Id = 131; Category = "IT Admin & System Tools"; Name = "Rufus USB Boot Maker"; WingetID = "Rufus.Rufus"; ChocoID = "rufus"; Description = "Create bootable USB drives easily from ISOs"; Col = 2 },
    [PSCustomObject]@{ Id = 132; Category = "IT Admin & System Tools"; Name = "Ventoy Multiboot USB"; WingetID = "Ventoy.Ventoy"; ChocoID = "ventoy"; Description = "Open source tool to create multiboot USB drive for ISO files"; Col = 2 },
    [PSCustomObject]@{ Id = 133; Category = "IT Admin & System Tools"; Name = "ImgBurn CD/DVD Burner"; WingetID = "LIGHTNINGUK.ImgBurn"; ChocoID = "imgburn"; Description = "Lightweight CD / DVD / HD DVD / Blu-ray burning application"; Col = 2 },
    [PSCustomObject]@{ Id = 134; Category = "IT Admin & System Tools"; Name = "TeraCopy File Transfer"; WingetID = "CodeSector.TeraCopy"; ChocoID = "teracopy"; Description = "Utility designed to copy and move files at maximum speed"; Col = 2 },

    # 10. File Utilities & Compression (Col 2)
    [PSCustomObject]@{ Id = 135; Category = "File Utilities & Compression"; Name = "7-Zip"; WingetID = "7zip.7zip"; ChocoID = "7zip"; Description = "High-compression file archiving utility"; Col = 2 },
    [PSCustomObject]@{ Id = 136; Category = "File Utilities & Compression"; Name = "WinRAR"; WingetID = "RARLab.WinRAR"; ChocoID = "winrar"; Description = "Popular archive and compression tool"; Col = 2 },
    [PSCustomObject]@{ Id = 137; Category = "File Utilities & Compression"; Name = "PeaZip"; WingetID = "PeaZip.PeaZip"; ChocoID = "peazip"; Description = "Free file archiver utility supporting over 200 archive types"; Col = 2 },
    [PSCustomObject]@{ Id = 138; Category = "File Utilities & Compression"; Name = "Everything Search Engine"; WingetID = "voidtools.Everything"; ChocoID = "everything"; Description = "Instant real-time filename search engine"; Col = 2 },
    [PSCustomObject]@{ Id = 139; Category = "File Utilities & Compression"; Name = "OpenHashTab Checksum"; WingetID = "namazso.OpenHashTab"; ChocoID = "openhashtab"; Description = "File checksum verification tab in explorer"; Col = 2 },
    [PSCustomObject]@{ Id = 140; Category = "File Utilities & Compression"; Name = "LockHunter File Unlocker"; WingetID = "CrystalRich.LockHunter"; ChocoID = "lockhunter"; Description = "Foolproof tool to delete files blocked by unknown processes"; Col = 2 },
    [PSCustomObject]@{ Id = 141; Category = "File Utilities & Compression"; Name = "NirSoft Utilities Launcher"; WingetID = "NirSoft.NirLauncher"; ChocoID = "nirlauncher"; Description = "Package of more than 200 portable system utilities by NirSoft"; Col = 2 },
    [PSCustomObject]@{ Id = 142; Category = "File Utilities & Compression"; Name = "AutoHotkey Scripting"; WingetID = "AutoHotkey.AutoHotkey"; ChocoID = "autohotkey"; Description = "Powerful macro-creation and hotkey scripting language"; Col = 2 },

    # ================= COLUMN 3 =================
    # 11. Remote Support & Access (Col 3)
    [PSCustomObject]@{ Id = 143; Category = "Remote Support & Access"; Name = "RustDesk Remote Desktop"; WingetID = "RustDesk.RustDesk"; ChocoID = "rustdesk"; Description = "Open-source remote desktop and RMM software"; Col = 3 },
    [PSCustomObject]@{ Id = 144; Category = "Remote Support & Access"; Name = "AnyDesk Remote Desktop"; WingetID = "AnyDeskSoftwareGmbH.AnyDesk"; ChocoID = "anydesk"; Description = "Fast remote desktop assistance application"; Col = 3 },
    [PSCustomObject]@{ Id = 145; Category = "Remote Support & Access"; Name = "TeamViewer"; WingetID = "TeamViewer.TeamViewer"; ChocoID = "teamviewer"; Description = "Enterprise remote support and collaboration"; Col = 3 },
    [PSCustomObject]@{ Id = 146; Category = "Remote Support & Access"; Name = "RealVNC Viewer"; WingetID = "RealVNC.VNCViewer"; ChocoID = "realvnc-viewer"; Description = "Remote desktop access software for VNC servers"; Col = 3 },
    [PSCustomObject]@{ Id = 147; Category = "Remote Support & Access"; Name = "mRemoteNG Multi-Remote"; WingetID = "mRemoteNG.mRemoteNG"; ChocoID = "mremoteng"; Description = "Open source tabbed, multi-protocol remote connections manager"; Col = 3 },
    [PSCustomObject]@{ Id = 148; Category = "Remote Support & Access"; Name = "UltraVNC Remote Access"; WingetID = "UltraVNC.UltraVNC"; ChocoID = "ultravnc"; Description = "Powerful, easy to use and free remote PC access software"; Col = 3 },
    [PSCustomObject]@{ Id = 149; Category = "Remote Support & Access"; Name = "Parsec Gaming / Desktop"; WingetID = "Parsec.Parsec"; ChocoID = "parsec"; Description = "Ultra-low latency remote desktop and co-op gaming screen sharing"; Col = 3 },

    # 12. Security & Privacy (Col 3)
    [PSCustomObject]@{ Id = 150; Category = "Security & Privacy"; Name = "Bitwarden Password Mgr"; WingetID = "Bitwarden.Bitwarden"; ChocoID = "bitwarden"; Description = "Open source password manager for all devices"; Col = 3 },
    [PSCustomObject]@{ Id = 151; Category = "Security & Privacy"; Name = "KeePassXC Password Safe"; WingetID = "KeePassXCTeam.KeePassXC"; ChocoID = "keepassxc"; Description = "Cross-platform community edition of KeePass password manager"; Col = 3 },
    [PSCustomObject]@{ Id = 152; Category = "Security & Privacy"; Name = "VeraCrypt Encryption"; WingetID = "IDRIX.VeraCrypt"; ChocoID = "veracrypt"; Description = "Free open source disk encryption software"; Col = 3 },
    [PSCustomObject]@{ Id = 153; Category = "Security & Privacy"; Name = "Malwarebytes Anti-Malware"; WingetID = "Malwarebytes.Malwarebytes"; ChocoID = "malwarebytes"; Description = "Advanced malware protection and remediation scanner"; Col = 3 },
    [PSCustomObject]@{ Id = 154; Category = "Security & Privacy"; Name = "Avast Free Antivirus"; WingetID = "Avast.AvastFreeAntivirus"; ChocoID = "avastfreeantivirus"; Description = "Popular free antivirus and threat defense solution"; Col = 3 },
    [PSCustomObject]@{ Id = 155; Category = "Security & Privacy"; Name = "Spybot Search & Destroy"; WingetID = "SaferNetworking.Spybot"; ChocoID = "spybot"; Description = "Detect and remove spyware, adware and tracking software"; Col = 3 },
    [PSCustomObject]@{ Id = 156; Category = "Security & Privacy"; Name = "ClamWin Free Antivirus"; WingetID = "ClamWin.ClamWin"; ChocoID = "clamwin"; Description = "Open source antivirus scanner for Windows"; Col = 3 },
    [PSCustomObject]@{ Id = 157; Category = "Security & Privacy"; Name = "O&O ShutUp10++ Privacy"; WingetID = "O&OSoftware.ShutUp10++"; ChocoID = "ooshutup10"; Description = "Free antispy tool to take total control over Windows 10/11 telemetry"; Col = 3 },

    # 13. Network & Forensics (Col 3)
    [PSCustomObject]@{ Id = 158; Category = "Network & Forensics"; Name = "Wireshark Packet Sniffer"; WingetID = "WiresharkFoundation.Wireshark"; ChocoID = "wireshark"; Description = "Network protocol analyzer and packet sniffer"; Col = 3 },
    [PSCustomObject]@{ Id = 159; Category = "Network & Forensics"; Name = "Advanced IP Scanner"; WingetID = "Famatech.AdvancedIPScanner"; ChocoID = "advanced-ip-scanner"; Description = "Fast LAN subnet scanner with remote control"; Col = 3 },
    [PSCustomObject]@{ Id = 160; Category = "Network & Forensics"; Name = "Nmap Security Scanner"; WingetID = "Insecure.Nmap"; ChocoID = "nmap"; Description = "Security scanner and network exploration tool"; Col = 3 },
    [PSCustomObject]@{ Id = 161; Category = "Network & Forensics"; Name = "OpenVPN Client"; WingetID = "OpenVPNTechnologies.OpenVPN"; ChocoID = "openvpn"; Description = "Enterprise SSL VPN tunneling client"; Col = 3 },
    [PSCustomObject]@{ Id = 162; Category = "Network & Forensics"; Name = "WireGuard VPN Tunnel"; WingetID = "WireGuard.WireGuard"; ChocoID = "wireguard"; Description = "Extremely simple yet fast modern VPN tunnel"; Col = 3 },
    [PSCustomObject]@{ Id = 163; Category = "Network & Forensics"; Name = "Tailscale Zero-Trust VPN"; WingetID = "Tailscale.Tailscale"; ChocoID = "tailscale"; Description = "Zero-config mesh VPN based on WireGuard"; Col = 3 },
    [PSCustomObject]@{ Id = 164; Category = "Network & Forensics"; Name = "Netcat / Ncat Tool"; WingetID = "Insecure.Ncat"; ChocoID = "netcat"; Description = "Feature-packed networking utility which reads and writes data across networks"; Col = 3 },
    [PSCustomObject]@{ Id = 165; Category = "Network & Forensics"; Name = "GlassWire Firewall/Monitor"; WingetID = "GlassWire.GlassWire"; ChocoID = "glasswire"; Description = "Visual network monitoring and firewall security tool"; Col = 3 },

    # 14. Other Utilities & Gaming (Col 3)
    [PSCustomObject]@{ Id = 166; Category = "Other Utilities & Gaming"; Name = "Steam Gaming Client"; WingetID = "Valve.Steam"; ChocoID = "steam"; Description = "The ultimate destination for playing, discussing, and creating games"; Col = 3 },
    [PSCustomObject]@{ Id = 167; Category = "Other Utilities & Gaming"; Name = "Epic Games Launcher"; WingetID = "EpicGames.EpicGamesLauncher"; ChocoID = "epicgameslauncher"; Description = "Store and launcher for Epic Games titles and Unreal Engine"; Col = 3 },
    [PSCustomObject]@{ Id = 168; Category = "Other Utilities & Gaming"; Name = "GOG Galaxy Launcher"; WingetID = "GOG.Galaxy"; ChocoID = "goggalaxy"; Description = "DRM-free gaming platform and unified PC game library"; Col = 3 },
    [PSCustomObject]@{ Id = 169; Category = "Other Utilities & Gaming"; Name = "EA app Desktop"; WingetID = "ElectronicArts.EADesktop"; ChocoID = "ea-app"; Description = "Electronic Arts PC gaming platform and game manager"; Col = 3 },
    [PSCustomObject]@{ Id = 170; Category = "Other Utilities & Gaming"; Name = "Ubisoft Connect Client"; WingetID = "Ubisoft.Connect"; ChocoID = "uplay"; Description = "Ecosystem of player services and games for Ubisoft titles"; Col = 3 },
    [PSCustomObject]@{ Id = 171; Category = "Other Utilities & Gaming"; Name = "EarTrumpet Volume Mixer"; WingetID = "File-New-Project.EarTrumpet"; ChocoID = "eartrumpet"; Description = "Powerful volume control app for Windows that replaces default audio tray"; Col = 3 },
    [PSCustomObject]@{ Id = 172; Category = "Other Utilities & Gaming"; Name = "Microsoft PC Manager"; WingetID = "Microsoft.PCManager"; ChocoID = "microsoft-pc-manager"; Description = "Official Microsoft system safeguard and performance booster"; Col = 3 },
    [PSCustomObject]@{ Id = 173; Category = "Other Utilities & Gaming"; Name = "Rainmeter Customization"; WingetID = "Rainmeter.Rainmeter"; ChocoID = "rainmeter"; Description = "Desktop customization tool displaying customizable skins and widgets"; Col = 3 }
)

# ---------------------------------------------------------
# 4. PRE-CONFIGURED ENTERPRISE BUNDLES
# ---------------------------------------------------------
$Bundles = @{
    "ALL_ADMIN"      = @(113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 138, 158, 159, 160, 106)
    "ALL_BROWSERS"   = @(1, 2, 3, 4, 5, 6, 7, 8, 9)
    "ALL_MEDIA"      = @(46, 47, 48, 49, 50, 51, 53, 61, 62, 63, 65, 66, 67, 72, 73)
    "ALL_NETWORK"    = @(114, 115, 116, 143, 144, 145, 158, 159, 160, 161, 162, 163, 164, 165)
    "ALL_DEV"        = @(91, 92, 93, 94, 97, 98, 100, 102, 104, 105, 106, 107, 108, 109, 110, 112, 39, 41, 44)
    "ALL_RUNTIMES"   = @(31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45)
    "ALL_ESSENTIALS" = @(1, 10, 11, 31, 39, 46, 61, 77, 79, 108, 135, 138)
}

# ---------------------------------------------------------
# 5. APPLICATION SELECTION & EXECUTION LOGIC
# ---------------------------------------------------------
$SelectedApps = @()

if ($Packages.Count -gt 0) {
    Write-Host "[+] Processing command-line package selections..." -ForegroundColor Cyan
    foreach ($Pkg in $Packages) {
        $Match = $Catalog | Where-Object { $_.Id -eq $Pkg -or $_.WingetID -eq $Pkg -or $_.ChocoID -eq $Pkg -or $_.Name -like "*$Pkg*" }
        if ($Match) { $SelectedApps += $Match } else { Write-Host " [!] Unknown package: $Pkg" -ForegroundColor Yellow }
    }
} elseif ($Preset -and $Bundles.ContainsKey($Preset.ToUpper())) {
    Write-Host "[+] Loading pre-configured bundle: $($Preset.ToUpper())..." -ForegroundColor Cyan
    $BundleIds = $Bundles[$Preset.ToUpper()]
    $SelectedApps = $Catalog | Where-Object { $_.Id -in $BundleIds }
} else {
    $GUISuccess = $false
    
    if (-not $NoGUI) {
        try {
            Add-Type -AssemblyName System.Windows.Forms
            Add-Type -AssemblyName System.Drawing

            # Create Main Form (Responsive, Resizable, Compact Starting Size for 173 Apps!)
            $Form = New-Object System.Windows.Forms.Form
            $Form.Text = "OmviHub Ninite Software Deployer (173 Ultimate Enterprise Catalog)"
            $Form.Size = New-Object System.Drawing.Size([int]1050, [int]660)
            $Form.MinimumSize = New-Object System.Drawing.Size([int]900, [int]500)
            $Form.StartPosition = "CenterScreen"
            $Form.BackColor = [System.Drawing.Color]::FromArgb(18, 24, 38) # Deep Dark Navy #121826
            $Form.ForeColor = [System.Drawing.Color]::White
            $Form.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
            $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
            $Form.MaximizeBox = $true
            $Form.MinimizeBox = $true

            # Header Panel
            $HeaderPanel = New-Object System.Windows.Forms.Panel
            $HeaderPanel.Size = New-Object System.Drawing.Size([int]1050, [int]80)
            $HeaderPanel.Dock = [System.Windows.Forms.DockStyle]::Top
            $HeaderPanel.BackColor = [System.Drawing.Color]::FromArgb(26, 35, 50)
            $Form.Controls.Add($HeaderPanel)

            $TitleLabel = New-Object System.Windows.Forms.Label
            $TitleLabel.Text = "OmviHub Ultimate Ninite Software Deployer"
            $TitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
            $TitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(56, 189, 248) # Bright Cyan
            $TitleLabel.Location = New-Object System.Drawing.Point(20, 15)
            $TitleLabel.Size = New-Object System.Drawing.Size([int]650, [int]32)
            $HeaderPanel.Controls.Add($TitleLabel)

            $SubTitle = New-Object System.Windows.Forms.Label
            $SubTitle.Text = "Check the apps you want to install and click Install. 173 applications across 14 categories downloaded via $PackageManager."
            $SubTitle.ForeColor = [System.Drawing.Color]::FromArgb(148, 163, 184) # Muted Slate
            $SubTitle.Location = New-Object System.Drawing.Point(22, 48)
            $SubTitle.Size = New-Object System.Drawing.Size([int]1000, [int]22)
            $HeaderPanel.Controls.Add($SubTitle)

            # =========================================================
            # PANEL 1: SELECTION SCREEN (4 COLUMNS OF CHECKBOXES)
            # =========================================================
            $SelectionPanel = New-Object System.Windows.Forms.Panel
            $SelectionPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
            $Form.Controls.Add($SelectionPanel)
            $SelectionPanel.BringToFront()

            # Bottom Action Bar for Selection Panel
            $BottomBar = New-Object System.Windows.Forms.Panel
            $BottomBar.Size = New-Object System.Drawing.Size([int]1050, [int]85)
            $BottomBar.Dock = [System.Windows.Forms.DockStyle]::Bottom
            $BottomBar.BackColor = [System.Drawing.Color]::FromArgb(26, 35, 50)
            $SelectionPanel.Controls.Add($BottomBar)

            $InstallBtn = New-Object System.Windows.Forms.Button
            $InstallBtn.Text = "Install Selected Software (0 Selected)"
            $InstallBtn.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
            $InstallBtn.BackColor = [System.Drawing.Color]::FromArgb(100, 116, 139) # Disabled Slate initially
            $InstallBtn.ForeColor = [System.Drawing.Color]::White
            $InstallBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            $InstallBtn.FlatAppearance.BorderSize = 0
            $InstallBtn.Size = New-Object System.Drawing.Size([int]320, [int]45)
            $InstallBtn.Location = New-Object System.Drawing.Point([int]690, [int]20)
            $InstallBtn.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
            $InstallBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
            $BottomBar.Controls.Add($InstallBtn)

            $SelectAllBtn = New-Object System.Windows.Forms.Button
            $SelectAllBtn.Text = "Select All"
            $SelectAllBtn.BackColor = [System.Drawing.Color]::FromArgb(51, 65, 85)
            $SelectAllBtn.ForeColor = [System.Drawing.Color]::White
            $SelectAllBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            $SelectAllBtn.Size = New-Object System.Drawing.Size([int]85, [int]35)
            $SelectAllBtn.Location = New-Object System.Drawing.Point([int]15, [int]25)
            $BottomBar.Controls.Add($SelectAllBtn)

            $ClearAllBtn = New-Object System.Windows.Forms.Button
            $ClearAllBtn.Text = "Clear All"
            $ClearAllBtn.BackColor = [System.Drawing.Color]::FromArgb(51, 65, 85)
            $ClearAllBtn.ForeColor = [System.Drawing.Color]::White
            $ClearAllBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            $ClearAllBtn.Size = New-Object System.Drawing.Size([int]85, [int]35)
            $ClearAllBtn.Location = New-Object System.Drawing.Point([int]105, [int]25)
            $BottomBar.Controls.Add($ClearAllBtn)

            $AdminPresetBtn = New-Object System.Windows.Forms.Button
            $AdminPresetBtn.Text = "IT Admin Pack"
            $AdminPresetBtn.BackColor = [System.Drawing.Color]::FromArgb(168, 85, 247) # Purple
            $AdminPresetBtn.ForeColor = [System.Drawing.Color]::White
            $AdminPresetBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $AdminPresetBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            $AdminPresetBtn.Size = New-Object System.Drawing.Size([int]115, [int]35)
            $AdminPresetBtn.Location = New-Object System.Drawing.Point([int]198, [int]25)
            $BottomBar.Controls.Add($AdminPresetBtn)

            $WorkerPresetBtn = New-Object System.Windows.Forms.Button
            $WorkerPresetBtn.Text = "Worker Pack"
            $WorkerPresetBtn.BackColor = [System.Drawing.Color]::FromArgb(14, 165, 233) # Cyan
            $WorkerPresetBtn.ForeColor = [System.Drawing.Color]::White
            $WorkerPresetBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $WorkerPresetBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            $WorkerPresetBtn.Size = New-Object System.Drawing.Size([int]110, [int]35)
            $WorkerPresetBtn.Location = New-Object System.Drawing.Point([int]318, [int]25)
            $BottomBar.Controls.Add($WorkerPresetBtn)

            $DevPresetBtn = New-Object System.Windows.Forms.Button
            $DevPresetBtn.Text = "Dev Suite"
            $DevPresetBtn.BackColor = [System.Drawing.Color]::FromArgb(234, 88, 12) # Orange
            $DevPresetBtn.ForeColor = [System.Drawing.Color]::White
            $DevPresetBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $DevPresetBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            $DevPresetBtn.Size = New-Object System.Drawing.Size([int]100, [int]35)
            $DevPresetBtn.Location = New-Object System.Drawing.Point([int]433, [int]25)
            $BottomBar.Controls.Add($DevPresetBtn)

            $RuntimesPresetBtn = New-Object System.Windows.Forms.Button
            $RuntimesPresetBtn.Text = "Runtimes & VC++"
            $RuntimesPresetBtn.BackColor = [System.Drawing.Color]::FromArgb(236, 72, 153) # Pink
            $RuntimesPresetBtn.ForeColor = [System.Drawing.Color]::White
            $RuntimesPresetBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $RuntimesPresetBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            $RuntimesPresetBtn.Size = New-Object System.Drawing.Size([int]135, [int]35)
            $RuntimesPresetBtn.Location = New-Object System.Drawing.Point([int]538, [int]25)
            $BottomBar.Controls.Add($RuntimesPresetBtn)

            # Checkbox Columns Area
            $ColumnsArea = New-Object System.Windows.Forms.Panel
            $ColumnsArea.Dock = [System.Windows.Forms.DockStyle]::Fill
            $ColumnsArea.AutoScroll = $true
            $ColumnsArea.Padding = New-Object System.Windows.Forms.Padding(15)
            $SelectionPanel.Controls.Add($ColumnsArea)

            # 4 Wide Columns for 173 Applications!
            [int]$ColWidth = 240
            [int[]]$ColX = @(20, 275, 530, 785)
            [int[]]$ColY = @(15, 15, 15, 15)

            $CheckBoxes = @()
            $UniqueCats = $Catalog | Select-Object -ExpandProperty Category -Unique

            foreach ($Cat in $UniqueCats) {
                $CatApps = $Catalog | Where-Object { $_.Category -eq $Cat }
                [int]$ColIndex = [int]$CatApps[0].Col
                [int]$BoxHeight = 35 + ([int]$CatApps.Count * 26)

                $GroupBox = New-Object System.Windows.Forms.GroupBox
                $GroupBox.Text = "  $Cat  "
                $GroupBox.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
                $GroupBox.ForeColor = [System.Drawing.Color]::FromArgb(56, 189, 248)
                $GroupBox.Location = New-Object System.Drawing.Point($ColX[$ColIndex], $ColY[$ColIndex])
                $GroupBox.Size = New-Object System.Drawing.Size([int]$ColWidth, [int]$BoxHeight)
                $ColumnsArea.Controls.Add($GroupBox)

                [int]$AppY = 26
                foreach ($App in $CatApps) {
                    $CB = New-Object System.Windows.Forms.CheckBox
                    $CB.Text = $App.Name
                    $CB.Font = New-Object System.Drawing.Font("Segoe UI", 9)
                    $CB.ForeColor = [System.Drawing.Color]::White
                    $CB.Location = New-Object System.Drawing.Point(15, [int]$AppY)
                    [int]$CBWidth = [int]$ColWidth - 25
                    $CB.Size = New-Object System.Drawing.Size([int]$CBWidth, [int]22)
                    $CB.Tag = $App
                    $CB.Cursor = [System.Windows.Forms.Cursors]::Hand
                    
                    $ToolTip = New-Object System.Windows.Forms.ToolTip
                    $ToolTip.SetToolTip($CB, $App.Description)

                    $CB.Add_CheckedChanged({
                        [int]$CheckedCount = ($CheckBoxes | Where-Object { $_.Checked }).Count
                        $InstallBtn.Text = "Install Selected Software ($CheckedCount Selected)"
                        if ($CheckedCount -gt 0) {
                            $InstallBtn.BackColor = [System.Drawing.Color]::FromArgb(34, 197, 94) # Bright Green
                        } else {
                            $InstallBtn.BackColor = [System.Drawing.Color]::FromArgb(100, 116, 139)
                        }
                    })

                    $GroupBox.Controls.Add($CB)
                    $CheckBoxes += $CB
                    $AppY += 24
                }

                $ColY[$ColIndex] += $BoxHeight + 15
            }

            # =========================================================
            # PANEL 2: LIVE NINITE INSTALLATION PROGRESS SCREEN
            # =========================================================
            $ProgressPanel = New-Object System.Windows.Forms.Panel
            $ProgressPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
            $ProgressPanel.Visible = $false
            $Form.Controls.Add($ProgressPanel)

            # Bottom Bar for Progress Panel
            $ProgBottomBar = New-Object System.Windows.Forms.Panel
            $ProgBottomBar.Size = New-Object System.Drawing.Size([int]1050, [int]95)
            $ProgBottomBar.Dock = [System.Windows.Forms.DockStyle]::Bottom
            $ProgBottomBar.BackColor = [System.Drawing.Color]::FromArgb(26, 35, 50)
            $ProgressPanel.Controls.Add($ProgBottomBar)

            $ProgressBar = New-Object System.Windows.Forms.ProgressBar
            $ProgressBar.Location = New-Object System.Drawing.Point([int]20, [int]20)
            $ProgressBar.Size = New-Object System.Drawing.Size([int]990, [int]25)
            $ProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
            $ProgressBar.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
            $ProgBottomBar.Controls.Add($ProgressBar)

            $ProgressStatusLabel = New-Object System.Windows.Forms.Label
            $ProgressStatusLabel.Text = "Overall Progress: 0 of 0 completed (0%)"
            $ProgressStatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $ProgressStatusLabel.ForeColor = [System.Drawing.Color]::FromArgb(248, 250, 252)
            $ProgressStatusLabel.Location = New-Object System.Drawing.Point([int]20, [int]55)
            $ProgressStatusLabel.Size = New-Object System.Drawing.Size([int]650, [int]25)
            $ProgBottomBar.Controls.Add($ProgressStatusLabel)

            $CloseReportBtn = New-Object System.Windows.Forms.Button
            $CloseReportBtn.Text = "View HTML Report & Close"
            $CloseReportBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $CloseReportBtn.BackColor = [System.Drawing.Color]::FromArgb(56, 189, 248) # Cyan
            $CloseReportBtn.ForeColor = [System.Drawing.Color]::FromArgb(15, 23, 42)
            $CloseReportBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            $CloseReportBtn.Size = New-Object System.Drawing.Size([int]260, [int]35)
            $CloseReportBtn.Location = New-Object System.Drawing.Point([int]750, [int]50)
            $CloseReportBtn.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
            $CloseReportBtn.Visible = $false
            $CloseReportBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
            $ProgBottomBar.Controls.Add($CloseReportBtn)

            # DataGridView Table for Live Installation Status
            $Grid = New-Object System.Windows.Forms.DataGridView
            $Grid.Dock = [System.Windows.Forms.DockStyle]::Fill
            $Grid.BackgroundColor = [System.Drawing.Color]::FromArgb(18, 24, 38)
            $Grid.ForeColor = [System.Drawing.Color]::White
            $Grid.GridColor = [System.Drawing.Color]::FromArgb(51, 65, 85)
            $Grid.BorderStyle = [System.Windows.Forms.BorderStyle]::None
            $Grid.AllowUserToAddRows = $false
            $Grid.AllowUserToDeleteRows = $false
            $Grid.ReadOnly = $true
            $Grid.RowHeadersVisible = $false
            $Grid.SelectionMode = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
            $Grid.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
            $Grid.DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(30, 41, 59)
            $Grid.DefaultCellStyle.ForeColor = [System.Drawing.Color]::White
            $Grid.DefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 10)
            $Grid.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(51, 65, 85)
            $Grid.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(15, 23, 42)
            $Grid.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(56, 189, 248)
            $Grid.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $Grid.ColumnHeadersHeight = 40
            $Grid.RowTemplate.Height = 36
            $Grid.EnableHeadersVisualStyles = $false

            $Grid.ColumnCount = 4
            $Grid.Columns[0].Name = "Application Name"
            $Grid.Columns[0].FillWeight = 30
            $Grid.Columns[1].Name = "Category"
            $Grid.Columns[1].FillWeight = 25
            $Grid.Columns[2].Name = "Package Identifier"
            $Grid.Columns[2].FillWeight = 25
            $Grid.Columns[3].Name = "Current Status"
            $Grid.Columns[3].FillWeight = 20
            $ProgressPanel.Controls.Add($Grid)

            # =========================================================
            # BUTTON EVENT HANDLERS
            # =========================================================
            $SelectAllBtn.Add_Click({ foreach ($CB in $CheckBoxes) { $CB.Checked = $true } })
            $ClearAllBtn.Add_Click({ foreach ($CB in $CheckBoxes) { $CB.Checked = $false } })

            $AdminPresetBtn.Add_Click({
                $AdminIds = $Bundles["ALL_ADMIN"]
                foreach ($CB in $CheckBoxes) { if ($CB.Tag.Id -in $AdminIds) { $CB.Checked = $true } else { $CB.Checked = $false } }
            })

            $WorkerPresetBtn.Add_Click({
                $WorkerIds = $Bundles["ALL_ESSENTIALS"]
                foreach ($CB in $CheckBoxes) { if ($CB.Tag.Id -in $WorkerIds) { $CB.Checked = $true } else { $CB.Checked = $false } }
            })

            $DevPresetBtn.Add_Click({
                $DevIds = $Bundles["ALL_DEV"]
                foreach ($CB in $CheckBoxes) { if ($CB.Tag.Id -in $DevIds) { $CB.Checked = $true } else { $CB.Checked = $false } }
            })

            $RuntimesPresetBtn.Add_Click({
                $RuntimeIds = $Bundles["ALL_RUNTIMES"]
                foreach ($CB in $CheckBoxes) { if ($CB.Tag.Id -in $RuntimeIds) { $CB.Checked = $true } else { $CB.Checked = $false } }
            })

            $InstallBtn.Add_Click({
                $Checked = $CheckBoxes | Where-Object { $_.Checked }
                if ($Checked.Count -eq 0) {
                    [System.Windows.Forms.MessageBox]::Show("Please check at least one application box to install!", "No Software Selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                    return
                }

                $script:SelectedApps = $Checked | ForEach-Object { $_.Tag }
                
                # Switch to Progress Screen!
                $SelectionPanel.Visible = $false
                $ProgressPanel.Visible = $true
                $ProgressPanel.BringToFront()
                $SubTitle.Text = "Installing $($SelectedApps.Count) applications. Please wait while packages are downloaded and verified..."
                
                # Populate Grid with selected apps
                $Grid.Rows.Clear()
                foreach ($App in $SelectedApps) {
                    $PkgId = if ($PackageManager -eq "Winget") { $App.WingetID } else { $App.ChocoID }
                    [int]$RowIdx = [int]$Grid.Rows.Add($App.Name, $App.Category, $PkgId, "[..] Waiting in queue...")
                    $Grid.Rows[$RowIdx].Cells[3].Style.ForeColor = [System.Drawing.Color]::FromArgb(148, 163, 184)
                }

                $ProgressBar.Value = 0
                $ProgressStatusLabel.Text = "Overall Progress: 0 of $($SelectedApps.Count) completed (0%)"
                [System.Windows.Forms.Application]::DoEvents()
                $Form.Refresh()

                # Start Async Deployment Loop
                $ReportsDir = Join-Path $PSScriptRoot "reports"
                if (-not (Test-Path $ReportsDir)) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null }
                $script:DeploymentResults = @()
                [int]$TotalApps = [int]$SelectedApps.Count
                [int]$CurrentIdx = 0

                for ([int]$i = 0; $i -lt $TotalApps; $i++) {
                    $App = $SelectedApps[$i]
                    $CurrentIdx++

                    # Update UI for currently installing app
                    $Grid.Rows[$i].Cells[3].Value = "[>>] Downloading & Installing..."
                    $Grid.Rows[$i].Cells[3].Style.ForeColor = [System.Drawing.Color]::FromArgb(56, 189, 248) # Cyan
                    $Grid.Rows[$i].Selected = $true
                    $Grid.FirstDisplayedScrollingRowIndex = $i
                    [System.Windows.Forms.Application]::DoEvents()
                    $Form.Refresh()

                    [datetime]$StartTime = Get-Date
                    $Status = "Failed"
                    $ErrorMsg = "None"

                    try {
                        # Ensure no leftover package manager locks before starting install
                        Stop-Process -Name "winget", "WindowsPackageManagerServer" -Force -ErrorAction SilentlyContinue

                        if ($PackageManager -eq "Winget") {
                            $ArgsList = @("/c", "winget", "install", "--id", $App.WingetID, "--exact", "--silent", "--accept-package-agreements", "--accept-source-agreements", "--scope", "machine")
                            if ($ForceInstall) { $ArgsList += "--force" }
                            $Proc = Start-Process -FilePath "cmd.exe" -ArgumentList $ArgsList -WindowStyle Hidden -PassThru -ErrorAction SilentlyContinue
                            if ($Proc) {
                                [int]$TimeoutSec = 300; [double]$Elapsed = 0
                                while (-not $Proc.HasExited -and $Elapsed -lt $TimeoutSec) {
                                    Start-Sleep -Milliseconds 500; $Elapsed += 0.5
                                    [System.Windows.Forms.Application]::DoEvents(); $Form.Refresh()
                                }
                                if (-not $Proc.HasExited) {
                                    $Proc | Stop-Process -Force -ErrorAction SilentlyContinue
                                    Stop-Process -Name "winget", "WindowsPackageManagerServer", "cmd" -Force -ErrorAction SilentlyContinue
                                    $Status = "Failed"; $ErrorMsg = "Timed out after 300s (stuck in queue/installer)"
                                } elseif ($Proc.ExitCode -eq 0 -or $Proc.ExitCode -eq -1978335189 -or $Proc.ExitCode -eq -1978335212 -or $Proc.ExitCode -eq 2316632075) {
                                    $Status = "Success"
                                } else { $Status = "Failed"; $ErrorMsg = "Winget exit code $($Proc.ExitCode)" }
                            } else { $Status = "Failed"; $ErrorMsg = "Failed to launch winget process." }

                            if ($Status -like "*Failed*" -and (Get-Command choco -ErrorAction SilentlyContinue)) {
                                $Grid.Rows[$i].Cells[3].Value = "[>>] Winget failed -> Retrying via Choco..."
                                [System.Windows.Forms.Application]::DoEvents()
                                $ChocoArgs = @("/c", "choco", "install", $App.ChocoID, "-y", "--no-progress", "--ignore-checksums", "--force")
                                $ChocoProc = Start-Process -FilePath "cmd.exe" -ArgumentList $ChocoArgs -WindowStyle Hidden -PassThru -ErrorAction SilentlyContinue
                                if ($ChocoProc) {
                                    [int]$TimeoutSec = 300; [double]$Elapsed = 0
                                    while (-not $ChocoProc.HasExited -and $Elapsed -lt $TimeoutSec) {
                                        Start-Sleep -Milliseconds 500; $Elapsed += 0.5
                                        [System.Windows.Forms.Application]::DoEvents(); $Form.Refresh()
                                    }
                                    if (-not $ChocoProc.HasExited) {
                                        $ChocoProc | Stop-Process -Force -ErrorAction SilentlyContinue
                                        $Status = "Failed"; $ErrorMsg = "Both Winget and Choco timed out."
                                    } elseif ($ChocoProc.ExitCode -eq 0 -or $ChocoProc.ExitCode -eq 1641 -or $ChocoProc.ExitCode -eq 3010) {
                                        $Status = "Success (Choco Fallback)"
                                    } else { $Status = "Failed"; $ErrorMsg = "Both Winget and Choco failed." }
                                }
                            }
                        } elseif ($PackageManager -eq "Chocolatey") {
                            $ChocoArgs = @("/c", "choco", "install", $App.ChocoID, "-y", "--no-progress", "--ignore-checksums", "--force")
                            $ChocoProc = Start-Process -FilePath "cmd.exe" -ArgumentList $ChocoArgs -WindowStyle Hidden -PassThru -ErrorAction SilentlyContinue
                            if ($ChocoProc) {
                                [int]$TimeoutSec = 300; [double]$Elapsed = 0
                                while (-not $ChocoProc.HasExited -and $Elapsed -lt $TimeoutSec) {
                                    Start-Sleep -Milliseconds 500; $Elapsed += 0.5
                                    [System.Windows.Forms.Application]::DoEvents(); $Form.Refresh()
                                }
                                if (-not $ChocoProc.HasExited) {
                                    $ChocoProc | Stop-Process -Force -ErrorAction SilentlyContinue
                                    $Status = "Failed"; $ErrorMsg = "Choco timed out after 300s."
                                } elseif ($ChocoProc.ExitCode -eq 0 -or $ChocoProc.ExitCode -eq 1641 -or $ChocoProc.ExitCode -eq 3010) {
                                    $Status = "Success"
                                } else { $Status = "Failed"; $ErrorMsg = "Choco exit code $($ChocoProc.ExitCode)" }
                            } else { $Status = "Failed"; $ErrorMsg = "Failed to launch choco process." }
                        }
                    } catch {
                        $Status = "Error"
                        $ErrorMsg = $_.Exception.Message
                    }

                    [double]$Duration = ((Get-Date) - $StartTime).TotalSeconds
                    $script:DeploymentResults += [PSCustomObject]@{
                        Timestamp    = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                        Category     = $App.Category
                        Name         = $App.Name
                        PackageID    = if ($PackageManager -eq "Winget") { $App.WingetID } else { $App.ChocoID }
                        Status       = $Status
                        DurationSec  = [math]::Round($Duration, 1)
                        ErrorMessage = $ErrorMsg
                    }

                    # Update UI Row Status
                    if ($Status -like "*Success*") {
                        $Grid.Rows[$i].Cells[3].Value = "[OK] Installed Successfully"
                        $Grid.Rows[$i].Cells[3].Style.ForeColor = [System.Drawing.Color]::FromArgb(34, 197, 94) # Green
                    } else {
                        $Grid.Rows[$i].Cells[3].Value = "[FAILED] Error: $ErrorMsg"
                        $Grid.Rows[$i].Cells[3].Style.ForeColor = [System.Drawing.Color]::FromArgb(239, 68, 68) # Red
                    }

                    # Update Progress Bar
                    $ProgressBar.Value = [math]::Round(($CurrentIdx / $TotalApps) * 100)
                    $ProgressStatusLabel.Text = "Overall Progress: $CurrentIdx of $TotalApps completed ($($ProgressBar.Value)%)"
                    [System.Windows.Forms.Application]::DoEvents()
                    $Form.Refresh()
                }

                # Completion State
                $SubTitle.Text = "All installations completed! Click below to view the full HTML audit report."
                $TitleLabel.Text = "Software Deployment Complete!"
                $TitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(34, 197, 94)
                $CloseReportBtn.Visible = $true
                [System.Windows.Forms.Application]::DoEvents()
                $Form.Refresh()
            })

            $CloseReportBtn.Add_Click({
                $Form.DialogResult = [System.Windows.Forms.DialogResult]::OK
                $Form.Close()
            })

            # Show Dialog
            $Result = $Form.ShowDialog()
            if ($Result -eq [System.Windows.Forms.DialogResult]::OK -and $SelectedApps.Count -gt 0) {
                $GUISuccess = $true
            } else {
                Write-Host "`n[!] Graphical window closed. Aborting." -ForegroundColor Yellow
                exit
            }
        } catch {
            Write-Host "[!] Graphical window failed: $($_.Exception.Message). Falling back to console menu..." -ForegroundColor Yellow
        }
    }
    
    # Console Fallback
    if (-not $GUISuccess) {
        Write-Host "`n==========================================================================" -ForegroundColor Cyan
        Write-Host "     OMVIHUB CONSOLE SOFTWARE CATALOG (173 APPS) [SELECT BY NUMBER]" -ForegroundColor White
        Write-Host "==========================================================================" -ForegroundColor Cyan
        
        $Categories = $Catalog | Select-Object -ExpandProperty Category -Unique
        foreach ($Cat in $Categories) {
            Write-Host "`n-- $Cat --" -ForegroundColor Yellow
            $CatApps = $Catalog | Where-Object { $_.Category -eq $Cat }
            foreach ($App in $CatApps) {
                Write-Host "  [$($App.Id)] $($App.Name) " -NoNewline -ForegroundColor White
                Write-Host "($($App.Description))" -ForegroundColor DarkGray
            }
        }
        
        Write-Host "`n-- PRE-CONFIGURED ENTERPRISE BUNDLES --" -ForegroundColor Green
        Write-Host "  [ALL_ADMIN]      IT Admin Suite (Sysinternals, Putty, WinSCP, FileZilla, MobaXterm, TreeSize, etc.)" -ForegroundColor White
        Write-Host "  [ALL_BROWSERS]   All Web Browsers (Chrome, Firefox, Edge, Brave, Opera, GX, Vivaldi, Tor, LibreWolf)" -ForegroundColor White
        Write-Host "  [ALL_MEDIA]      Media & Design (VLC, Spotify, OBS, HandBrake, ShareX, Greenshot, GIMP, Blender)" -ForegroundColor White
        Write-Host "  [ALL_NETWORK]    Network & Forensics (Wireshark, IP Scanner, Nmap, OpenVPN, WireGuard, Tailscale)" -ForegroundColor White
        Write-Host "  [ALL_DEV]        Developer Suite (VS Code, VS 2022, IntelliJ, PyCharm, Git, Python, Docker, Node.js)" -ForegroundColor White
        Write-Host "  [ALL_RUNTIMES]   Runtimes & VC++ (.NET 4.8, .NET 8/6, VC++ 2015-2022 x64/x86, VC++ 2013-2005, Java, DirectX)" -ForegroundColor White
        Write-Host "  [ALL_ESSENTIALS] Standard Worker Essentials (Chrome, Zoom, VLC, ShareX, LibreOffice, Notepad++)" -ForegroundColor White
        Write-Host "==========================================================================" -ForegroundColor Cyan
        
        $InputStr = Read-Host "`nEnter application numbers separated by commas (e.g. 1, 10, 31, 46, 91) or BUNDLE name"
        if (-not $InputStr -or $InputStr.Trim() -eq "") { exit }
        
        $CleanInput = $InputStr.Trim().ToUpper()
        if ($Bundles.ContainsKey($CleanInput)) {
            $BundleIds = $Bundles[$CleanInput]
            $SelectedApps = $Catalog | Where-Object { $_.Id -in $BundleIds }
        } else {
            $IdStrings = $CleanInput -split "," | ForEach-Object { $_.Trim() }
            $Ids = @()
            foreach ($Str in $IdStrings) { if ($Str -match "^\d+$") { $Ids += [int]$Str } }
            $SelectedApps = $Catalog | Where-Object { $_.Id -in $Ids }
        }

        # Execute console deployment loop
        $ReportsDir = Join-Path $PSScriptRoot "reports"
        if (-not (Test-Path $ReportsDir)) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null }
        $script:DeploymentResults = @()
        [int]$TotalApps = [int]$SelectedApps.Count
        [int]$CurrentIdx = 0

        foreach ($App in $SelectedApps) {
            $CurrentIdx++
            Write-Host "[${CurrentIdx}/${TotalApps}] Installing $($App.Name)..." -ForegroundColor Yellow -NoNewline
            [datetime]$StartTime = Get-Date; $Status = "Failed"; $ErrorMsg = "None"
            try {
                Stop-Process -Name "winget", "WindowsPackageManagerServer" -Force -ErrorAction SilentlyContinue

                if ($PackageManager -eq "Winget") {
                    $ArgsList = @("/c", "winget", "install", "--id", $App.WingetID, "--exact", "--silent", "--accept-package-agreements", "--accept-source-agreements", "--scope", "machine")
                    if ($ForceInstall) { $ArgsList += "--force" }
                    $Proc = Start-Process -FilePath "cmd.exe" -ArgumentList $ArgsList -WindowStyle Hidden -PassThru -ErrorAction SilentlyContinue
                    if ($Proc) {
                        [int]$TimeoutSec = 300; [double]$Elapsed = 0
                        while (-not $Proc.HasExited -and $Elapsed -lt $TimeoutSec) { Start-Sleep -Milliseconds 500; $Elapsed += 0.5 }
                        if (-not $Proc.HasExited) {
                            $Proc | Stop-Process -Force -ErrorAction SilentlyContinue
                            Stop-Process -Name "winget", "WindowsPackageManagerServer", "cmd" -Force -ErrorAction SilentlyContinue
                            $Status = "Failed"; $ErrorMsg = "Timed out after 300s"; Write-Host " [FAILED (TIMEOUT)]" -ForegroundColor Red
                        } elseif ($Proc.ExitCode -eq 0 -or $Proc.ExitCode -eq -1978335189 -or $Proc.ExitCode -eq -1978335212 -or $Proc.ExitCode -eq 2316632075) {
                            $Status = "Success"; Write-Host " [OK - Winget]" -ForegroundColor Green
                        } else { $Status = "Failed"; $ErrorMsg = "Winget exit code $($Proc.ExitCode)"; Write-Host " [FAILED]" -ForegroundColor Red }
                    } else { $Status = "Failed"; $ErrorMsg = "Failed to launch winget."; Write-Host " [FAILED]" -ForegroundColor Red }

                    if ($Status -like "*Failed*" -and (Get-Command choco -ErrorAction SilentlyContinue)) {
                        Write-Host " -> Retrying via Choco..." -ForegroundColor Yellow -NoNewline
                        $ChocoArgs = @("/c", "choco", "install", $App.ChocoID, "-y", "--no-progress", "--ignore-checksums", "--force")
                        $ChocoProc = Start-Process -FilePath "cmd.exe" -ArgumentList $ChocoArgs -WindowStyle Hidden -PassThru -ErrorAction SilentlyContinue
                        if ($ChocoProc) {
                            [int]$TimeoutSec = 300; [double]$Elapsed = 0
                            while (-not $ChocoProc.HasExited -and $Elapsed -lt $TimeoutSec) { Start-Sleep -Milliseconds 500; $Elapsed += 0.5 }
                            if (-not $ChocoProc.HasExited) {
                                $ChocoProc | Stop-Process -Force -ErrorAction SilentlyContinue
                                $Status = "Failed"; $ErrorMsg = "Both Winget and Choco timed out."; Write-Host " [FAILED (TIMEOUT)]" -ForegroundColor Red
                            } elseif ($ChocoProc.ExitCode -eq 0 -or $ChocoProc.ExitCode -eq 1641 -or $ChocoProc.ExitCode -eq 3010) {
                                $Status = "Success (Choco Fallback)"; Write-Host " [OK - Choco]" -ForegroundColor Green
                            } else { $Status = "Failed"; $ErrorMsg = "Both Winget and Choco failed."; Write-Host " [FAILED]" -ForegroundColor Red }
                        }
                    }
                } elseif ($PackageManager -eq "Chocolatey") {
                    $ChocoArgs = @("/c", "choco", "install", $App.ChocoID, "-y", "--no-progress", "--ignore-checksums", "--force")
                    $ChocoProc = Start-Process -FilePath "cmd.exe" -ArgumentList $ChocoArgs -WindowStyle Hidden -PassThru -ErrorAction SilentlyContinue
                    if ($ChocoProc) {
                        [int]$TimeoutSec = 300; [double]$Elapsed = 0
                        while (-not $ChocoProc.HasExited -and $Elapsed -lt $TimeoutSec) { Start-Sleep -Milliseconds 500; $Elapsed += 0.5 }
                        if (-not $ChocoProc.HasExited) {
                            $ChocoProc | Stop-Process -Force -ErrorAction SilentlyContinue
                            $Status = "Failed"; $ErrorMsg = "Choco timed out after 300s."; Write-Host " [FAILED (TIMEOUT)]" -ForegroundColor Red
                        } elseif ($ChocoProc.ExitCode -eq 0 -or $ChocoProc.ExitCode -eq 1641 -or $ChocoProc.ExitCode -eq 3010) {
                            $Status = "Success"; Write-Host " [OK - Choco]" -ForegroundColor Green
                        } else { $Status = "Failed"; $ErrorMsg = "Choco exit code $($ChocoProc.ExitCode)"; Write-Host " [FAILED]" -ForegroundColor Red }
                    } else { $Status = "Failed"; $ErrorMsg = "Failed to launch choco."; Write-Host " [FAILED]" -ForegroundColor Red }
                }
            } catch { $Status = "Error"; $ErrorMsg = $_.Exception.Message; Write-Host " [ERROR: $ErrorMsg]" -ForegroundColor Red }
            
            [double]$Duration = ((Get-Date) - $StartTime).TotalSeconds
            $script:DeploymentResults += [PSCustomObject]@{
                Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); Category = $App.Category; Name = $App.Name
                PackageID = if ($PackageManager -eq "Winget") { $App.WingetID } else { $App.ChocoID }
                Status = $Status; DurationSec = [math]::Round($Duration, 1); ErrorMessage = $ErrorMsg
            }
        }
    }
}

if ($DeploymentResults.Count -eq 0) { exit }

# ---------------------------------------------------------
# 6. GENERATE CSV AUDIT LOG
# ---------------------------------------------------------
$ReportsDir = Join-Path $PSScriptRoot "reports"
$CsvPath = Join-Path $ReportsDir "deployment_history.csv"
$AppendCsv = Test-Path $CsvPath
$DeploymentResults | Export-Csv -Path $CsvPath -NoTypeInformation -Append:$AppendCsv -Force
Write-Host "`n[+] Deployment history recorded in: $CsvPath" -ForegroundColor Green

# ---------------------------------------------------------
# 7. GENERATE SELF-CONTAINED DARK-MODE HTML REPORT
# ---------------------------------------------------------
$HtmlPath = Join-Path $ReportsDir "deployment_report.html"
$SuccessCount = ($DeploymentResults | Where-Object { $_.Status -like "*Success*" }).Count
$FailCount    = ($DeploymentResults | Where-Object { $_.Status -notlike "*Success*" }).Count

$RowsHtml = ""
foreach ($Res in $DeploymentResults) {
    $BadgeClass = if ($Res.Status -like "*Success*") { "badge-success" } else { "badge-danger" }
    $RowsHtml += "<tr><td>$($Res.Timestamp)</td><td><span class=`"category-tag`">$($Res.Category)</span></td><td style=`"font-weight: 600; color: #f8fafc;`">$($Res.Name)</td><td style=`"font-family: monospace; color: #38bdf8;`">$($Res.PackageID)</td><td><span class=`"badge $BadgeClass`">$($Res.Status)</span></td><td>$($Res.DurationSec)s</td><td style=`"color: #f87171; font-size: 0.85rem;`">$($Res.ErrorMessage)</td></tr>`n"
}

$HtmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OmviHub Cloud Software Deployment Report</title>
    <style>
        :root {
            --bg-primary: #0f172a;
            --bg-secondary: #1e293b;
            --bg-card: #334155;
            --text-main: #f8fafc;
            --text-muted: #94a3b8;
            --accent-blue: #38bdf8;
            --accent-green: #22c55e;
            --accent-red: #ef4444;
            --accent-purple: #c084fc;
        }
        body {
            font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
            background-color: var(--bg-primary);
            color: var(--text-main);
            margin: 0;
            padding: 2rem;
            line-height: 1.5;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        .header {
            background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
            border-left: 5px solid var(--accent-purple);
            padding: 2rem; border-radius: 0.75rem;
            box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.5);
            margin-bottom: 2rem; display: flex; justify-content: space-between; align-items: center;
        }
        .header h1 { margin: 0; font-size: 1.8rem; color: var(--text-main); display: flex; align-items: center; gap: 0.75rem; }
        .header p { margin: 0.5rem 0 0 0; color: var(--text-muted); font-size: 0.95rem; }
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 1.5rem; margin-bottom: 2rem; }
        .stat-card {
            background-color: var(--bg-secondary); padding: 1.5rem; border-radius: 0.75rem;
            border-top: 4px solid var(--accent-blue); box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.3);
        }
        .stat-card.success { border-color: var(--accent-green); }
        .stat-card.danger { border-color: var(--accent-red); }
        .stat-card h3 { margin: 0; font-size: 0.85rem; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.05em; }
        .stat-card .value { font-size: 2.2rem; font-weight: 700; margin-top: 0.5rem; color: var(--text-main); }
        .section-title { font-size: 1.3rem; margin-bottom: 1rem; color: var(--accent-blue); border-bottom: 2px solid var(--bg-card); padding-bottom: 0.5rem; }
        table {
            width: 100%; border-collapse: collapse; background-color: var(--bg-secondary);
            border-radius: 0.75rem; overflow: hidden; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.3); margin-bottom: 2rem;
        }
        th, td { padding: 1rem; text-align: left; border-bottom: 1px solid var(--bg-card); }
        th { background-color: #0b1120; color: var(--text-muted); font-weight: 600; font-size: 0.85rem; text-transform: uppercase; letter-spacing: 0.05em; }
        tr:hover { background-color: rgba(255, 255, 255, 0.03); }
        .badge { padding: 0.35rem 0.75rem; border-radius: 9999px; font-size: 0.75rem; font-weight: 700; text-transform: uppercase; display: inline-block; }
        .badge-success { background-color: rgba(34, 197, 94, 0.2); color: #4ade80; border: 1px solid rgba(34, 197, 94, 0.4); }
        .badge-danger { background-color: rgba(239, 68, 68, 0.2); color: #f87171; border: 1px solid rgba(239, 68, 68, 0.4); }
        .category-tag { background-color: var(--bg-card); color: var(--text-main); padding: 0.25rem 0.6rem; border-radius: 0.375rem; font-size: 0.8rem; }
        .footer { text-align: center; color: var(--text-muted); font-size: 0.85rem; margin-top: 3rem; padding-top: 1.5rem; border-top: 1px solid var(--bg-card); }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div>
                <h1>OmviHub Cloud Software Deployment Report</h1>
                <p>Ninite-Style Hybrid CDN Package Deployment Command Center (173 Catalog)</p>
            </div>
            <div style="text-align: right;">
                <p style="color: var(--text-main); font-weight: 600;">$env:COMPUTERNAME</p>
                <p style="font-size: 0.85rem;">Engine: $PackageManager</p>
            </div>
        </div>

        <div class="stats-grid">
            <div class="stat-card">
                <h3>Total Processed</h3>
                <div class="value">$TotalApps</div>
            </div>
            <div class="stat-card success">
                <h3>Successful Deploys</h3>
                <div class="value" style="color: var(--accent-green);">$SuccessCount</div>
            </div>
            <div class="stat-card danger">
                <h3>Failed / Errors</h3>
                <div class="value" style="color: var(--accent-red);">$FailCount</div>
            </div>
        </div>

        <div class="section-title">Itemized Deployment Log</div>
        <table>
            <thead>
                <tr>
                    <th>Timestamp</th>
                    <th>Category</th>
                    <th>Application Name</th>
                    <th>Package Identifier</th>
                    <th>Status</th>
                    <th>Duration</th>
                    <th>Error Detail</th>
                </tr>
            </thead>
            <tbody>
                $RowsHtml
            </tbody>
        </table>

        <div class="footer">
            Generated by OmviHub Windows & Windows Server IT Administration Toolkit [Option 16] &bull; 100% Offline-Compatible Report
        </div>
    </div>
</body>
</html>
"@

$HtmlContent | Out-File -FilePath $HtmlPath -Encoding utf8 -Force
Write-Host "[+] HTML deployment dashboard generated: $HtmlPath" -ForegroundColor Green

if (-not $NoGUI) {
    Start-Process $HtmlPath
} else {
    Write-Host "`nWould you like to open the HTML deployment dashboard now? [Y/N]" -ForegroundColor Yellow
    $OpenChoice = Read-Host
    if ($OpenChoice -eq "Y" -or $OpenChoice -eq "y") { Start-Process $HtmlPath }
}
