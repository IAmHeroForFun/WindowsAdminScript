<#
.SYNOPSIS
    OmviHub WinRE Boot Repair Assistant - Direct Web Bootstrapper [Massgrave Style]
.DESCRIPTION
    A lightweight direct bootstrapper designed to be executed via:
    irm https://toolkit.omvihub.in/winre.ps1 | iex   (or irm https://toolkit.omvihub.in/winre | iex)
#>

[CmdletBinding()]
param (
    [string]$DownloadUrl = "https://github.com/IAmHeroForFun/WindowsAdminScript/archive/refs/heads/master.zip",
    [string]$InstallDir = "C:\SysMaster",
    [switch]$ForceOverwriteAll
)

$ErrorActionPreference = "Stop"

# 1. Enforce TLS 1.2 / 1.3
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13 } catch { }

# 2. Check Admin Elevation
function Test-IsAdmin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Host "==========================================================================" -ForegroundColor DarkYellow
    Write-Host "  [ELEVATION REQUIRED] WinRE Recovery Assistant requires Administrator privileges." -ForegroundColor Yellow
    Write-Host "  Requesting UAC Elevation... Please click 'Yes' on the prompt." -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor DarkYellow
    
    $CommandLine = "-NoExit -NoProfile -ExecutionPolicy Bypass -Command `"irm https://toolkit.omvihub.in/winre.ps1 | iex`""
    if ($MyInvocation.MyCommand.Path) { $CommandLine = "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" }
    try { Start-Process -FilePath "powershell.exe" -ArgumentList $CommandLine -Verb RunAs -Wait; exit } catch { exit 1 }
}

# 3. Download and execute master bootstrapper with -Tool winre
Write-Host "[+] Fetching OmviHub WinRE Recovery Assistant engine..." -ForegroundColor Red
$StagingDir = Join-Path $env:TEMP "OmviHub_Boot_$(Get-Random)"
if (Test-Path $StagingDir) { Remove-Item -Path $StagingDir -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $StagingDir -Force | Out-Null

$BootScript = Join-Path $StagingDir "install.ps1"
$InstallScriptUrl = "https://raw.githubusercontent.com/IAmHeroForFun/WindowsAdminScript/master/install.ps1"

try {
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        Invoke-WebRequest -Uri $InstallScriptUrl -OutFile $BootScript -UseBasicParsing
    } else {
        (New-Object System.Net.WebClient).DownloadFile($InstallScriptUrl, $BootScript)
    }
    & $BootScript -DownloadUrl $DownloadUrl -InstallDir $InstallDir -Tool "winre" -ForceOverwriteAll:$ForceOverwriteAll
} catch {
    Write-Host "[ERROR] Failed to boot WinRE Recovery Assistant: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Remove-Item -Path $StagingDir -Recurse -Force -ErrorAction SilentlyContinue
}
