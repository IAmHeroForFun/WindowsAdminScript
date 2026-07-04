<#
.SYNOPSIS
    OmviHub Windows & Windows Server IT Toolkit - Web Bootstrapper [Massgrave Style]
.DESCRIPTION
    A lightweight, production-grade 2-stage web bootstrapper designed to be executed via:
    irm https://toolkit.omvihub.in | iex   (or irm https://toolkit.omvihub.in/install.ps1 | iex)
    
    Features:
    - Automatic Administrative Elevation (UAC prompt handling)
    - TLS 1.2 / 1.3 Security Enforcement for Windows 7 / Server 2008 R2+ compatibility
    - Intelligent Update Engine: Downloads latest code while strictly preserving 100% of existing reports, CSV logs, and historical SLA data
    - Bypasses PowerShell Execution Policy & SmartScreen file blocking
    - Seamlessly launches the interactive Master IT Toolkit console
.AUTHOR
    OmviHub IT Automation & Infrastructure Team
#>

[CmdletBinding()]
param (
    [string]$DownloadUrl = "https://github.com/omvihub/Windows-IT-Toolkit/archive/refs/heads/main.zip",
    [string]$InstallDir = "C:\OmviHub_Toolkit",
    [switch]$ForceOverwriteAll
)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------
# 1. ENFORCE TLS 1.2 / 1.3 & SECURITY PROTOCOLS
# ---------------------------------------------------------
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
} catch {
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { }
}

# ---------------------------------------------------------
# 2. CHECK & REQUEST ADMINISTRATIVE ELEVATION
# ---------------------------------------------------------
function Test-IsAdmin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Host "==========================================================================" -ForegroundColor DarkYellow
    Write-Host "  [ELEVATION REQUIRED] OmviHub IT Toolkit requires Administrator privileges." -ForegroundColor Yellow
    Write-Host "  Requesting UAC Elevation... Please click 'Yes' on the prompt." -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor DarkYellow
    
    $CommandLine = "-NoExit -NoProfile -ExecutionPolicy Bypass -Command `"irm https://toolkit.omvihub.in/install.ps1 | iex`""
    if ($MyInvocation.MyCommand.Path) {
        $CommandLine = "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    }
    
    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList $CommandLine -Verb RunAs -Wait
        exit
    } catch {
        Write-Host "`n[ERROR] Administrative elevation was cancelled or failed. Cannot proceed." -ForegroundColor Red
        Write-Host "`nPress Enter to exit..." -ForegroundColor DarkGray; [void](Read-Host)
        exit 1
    }
}

Clear-Host
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "       OMVIHUB WINDOWS & WINDOWS SERVER IT TOOLKIT - BOOTSTRAPPER" -ForegroundColor White
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "Target Installation Directory : $InstallDir" -ForegroundColor Cyan
Write-Host "Source Archive URL            : $DownloadUrl" -ForegroundColor DarkGray
Write-Host "Host System                   : $env:COMPUTERNAME ($($env:OS))" -ForegroundColor DarkGray
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host ""

# ---------------------------------------------------------
# 3. PREPARE STAGING & INSTALLATION DIRECTORIES
# ---------------------------------------------------------
$StagingDir = Join-Path $env:TEMP "OmviHub_Staging_$(Get-Random)"
if (Test-Path $StagingDir) { Remove-Item -Path $StagingDir -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $StagingDir -Force | Out-Null

if (-not (Test-Path $InstallDir)) {
    Write-Host "[+] Creating permanent system toolkit directory: $InstallDir" -ForegroundColor Green
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# ---------------------------------------------------------
# 4. DOWNLOAD & EXTRACT TOOLKIT ARCHIVE
# ---------------------------------------------------------
$ZipPath = Join-Path $StagingDir "toolkit.zip"
$ExtractPath = Join-Path $StagingDir "extracted"

Write-Host "[+] Downloading latest toolkit release from OmviHub cloud..." -ForegroundColor Cyan
try {
    # Try downloading with WebClient or Invoke-WebRequest
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath -UseBasicParsing
    } else {
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile($DownloadUrl, $ZipPath)
    }
    Write-Host " -> Download successful ($((Get-Item $ZipPath).Length / 1KB | ForEach-Object { '{0:N2}' -f $_ }) KB)" -ForegroundColor Green
} catch {
    Write-Host "`n[ERROR] Failed to download toolkit archive from $DownloadUrl" -ForegroundColor Red
    Write-Host "Reason: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "`nPlease verify internet connectivity and ensure your GitHub repository URL is correct and public!" -ForegroundColor DarkGray
    Remove-Item -Path $StagingDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "`nPress Enter to exit..." -ForegroundColor DarkGray; [void](Read-Host)
    exit 1
}

Write-Host "[+] Extracting archive modules into staging buffer..." -ForegroundColor Cyan
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $ExtractPath)
} catch {
    try {
        Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force
    } catch {
        Write-Host "`n[ERROR] Failed to extract ZIP archive: $($_.Exception.Message)" -ForegroundColor Red
        Remove-Item -Path $StagingDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "`nPress Enter to exit..." -ForegroundColor DarkGray; [void](Read-Host)
        exit 1
    }
}

# Locate the root folder inside the extracted zip (GitHub zips create a top-level folder like repo-main)
$ExtractedRoot = Get-ChildItem -Path $ExtractPath -Directory | Select-Object -First 1
if (-not $ExtractedRoot) { $ExtractedRoot = $ExtractPath } else { $ExtractedRoot = $ExtractedRoot.FullName }

# ---------------------------------------------------------
# 5. INTELLIGENT DATA PRESERVATION & CODE UPDATE ENGINE
# ---------------------------------------------------------
Write-Host "[+] Updating toolkit modules (preserving historical reports & data)..." -ForegroundColor Cyan

function Copy-ToolkitPreservingData {
    param([string]$SourceDir, [string]$DestDir)
    
    $Items = Get-ChildItem -Path $SourceDir -Force
    foreach ($Item in $Items) {
        $TargetItemPath = Join-Path $DestDir $Item.Name
        
        if ($Item.PSIsContainer) {
            if (-not (Test-Path $TargetItemPath)) {
                New-Item -ItemType Directory -Path $TargetItemPath -Force | Out-Null
            }
            Copy-ToolkitPreservingData -SourceDir $Item.FullName -DestDir $TargetItemPath
        } else {
            # Check if this file is protected historical data or user report
            $IsProtectedData = $false
            if (-not $ForceOverwriteAll -and (Test-Path $TargetItemPath)) {
                # Protect if inside reports, backups, installed_software folders
                if ($DestDir -match "\\reports(\\|$)" -or $DestDir -match "\\backups(\\|$)" -or $DestDir -match "\\installed_software(\\|$)") {
                    $IsProtectedData = $true
                }
                # Protect if extension is CSV, JSON, LOG, OLD, BAK (except sample files if needed)
                if ($Item.Extension -in @(".csv", ".json", ".log", ".bak", ".old")) {
                    $IsProtectedData = $true
                }
            }
            
            if ($IsProtectedData) {
                # Skip overwriting existing historical data
            } else {
                Copy-Item -Path $Item.FullName -Destination $TargetItemPath -Force
            }
        }
    }
}

Copy-ToolkitPreservingData -SourceDir $ExtractedRoot -DestDir $InstallDir
Write-Host " -> Toolkit code successfully synchronized to $InstallDir!" -ForegroundColor Green

# Clean up staging directory
Remove-Item -Path $StagingDir -Recurse -Force -ErrorAction SilentlyContinue

# ---------------------------------------------------------
# 6. UNBLOCK FILES & SET EXECUTION POLICIES
# ---------------------------------------------------------
Write-Host "[+] Unblocking script modules to bypass SmartScreen & execution policies..." -ForegroundColor Cyan
Get-ChildItem -Path $InstallDir -Recurse -Include "*.ps1", "*.bat", "*.cmd" -ErrorAction SilentlyContinue | ForEach-Object {
    try { Unblock-File -Path $_.FullName -ErrorAction SilentlyContinue } catch { }
}

# ---------------------------------------------------------
# 7. LAUNCH MASTER MENU
# ---------------------------------------------------------
Write-Host "`n==========================================================================" -ForegroundColor Magenta
Write-Host "  BOOTSTRAP COMPLETE! LAUNCHING OMVIHUB MASTER IT TOOLKIT CONSOLE..." -ForegroundColor White
Write-Host "==========================================================================" -ForegroundColor Magenta
Start-Sleep -Seconds 2

$MasterScript = Join-Path $InstallDir "windows_it_toolkit.ps1"
if (Test-Path $MasterScript) {
    & $MasterScript
} else {
    Write-Host "[ERROR] Could not locate master script at $MasterScript" -ForegroundColor Red
    Write-Host "Please verify that your ZIP archive contains windows_it_toolkit.ps1 at the root level." -ForegroundColor Yellow
}
