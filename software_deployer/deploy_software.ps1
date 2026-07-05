# ==============================================================================
# SCRIPT: deploy_software.ps1
# PURPOSE: Entry point for OmviHub Cloud Software Deployer (WPF Engine).
#          Enforces PowerShell 7+ runtime, ensures Administrator privileges,
#          loads WPF presentation assemblies, and boots MainWindow.ps1.
# ==============================================================================

# Ensure script is running from its own directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptDir

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "  Booting OmviHub Cloud Software Deployer (WPF & Winget Engine)..." -ForegroundColor White
Write-Host "==========================================================================" -ForegroundColor Cyan

# 1. Enforce PowerShell 7+ Runtime
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "[WARN] You are running Windows PowerShell $($PSVersionTable.PSVersion). This application is optimized for PowerShell 7+." -ForegroundColor Yellow
    
    # Check if pwsh.exe (PowerShell 7) is installed and relaunch if available
    $pwsh = Get-Command -Name "pwsh.exe" -ErrorAction SilentlyContinue
    if ($pwsh) {
        Write-Host "[+] Relaunching deployer under PowerShell 7 (pwsh.exe)..." -ForegroundColor Green
        Start-Process -FilePath "pwsh.exe" -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$($MyInvocation.MyCommand.Definition)`"" -Verb RunAs
        exit
    } else {
        Write-Host "[!] PowerShell 7 (pwsh.exe) not found. Continuing under PowerShell 5.1 (some features may behave differently)..." -ForegroundColor Yellow
    }
}

# 2. Ensure Administrator Privileges (Required for machine-wide Winget software installations)
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[!] Administrator privileges required for software deployment. Relaunching as Administrator..." -ForegroundColor Yellow
    try {
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            Start-Process -FilePath "pwsh.exe" -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$($MyInvocation.MyCommand.Definition)`"" -Verb RunAs
        } else {
            Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$($MyInvocation.MyCommand.Definition)`"" -Verb RunAs
        }
        exit
    } catch {
        Write-Host "[ERROR] Failed to elevate privileges: $_" -ForegroundColor Red
        exit 1
    }
}

# 3. Load WPF / XAML Presentation Assemblies
try {
    Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
    Add-Type -AssemblyName PresentationCore -ErrorAction Stop
    Add-Type -AssemblyName WindowsBase -ErrorAction Stop
    Write-Host "[+] Loaded Windows Presentation Foundation (WPF) assemblies." -ForegroundColor Green
} catch {
    Write-Host "[CRITICAL] Failed to load WPF assemblies: $_" -ForegroundColor Red
    exit 1
}

# 4. Launch Main Application Window
$mainWindowScript = Join-Path $scriptDir "MainWindow.ps1"
if (Test-Path $mainWindowScript) {
    Write-Host "[+] Starting application interface..." -ForegroundColor Green
    & $mainWindowScript
} else {
    Write-Host "[CRITICAL] MainWindow.ps1 not found at $mainWindowScript" -ForegroundColor Red
    exit 1
}
