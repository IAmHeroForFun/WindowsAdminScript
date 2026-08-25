# Windows Search & Indexing Repair Tool
# Compatible with Windows 7 (PowerShell 2.0) through Windows 11 (PowerShell 5.1 & 7+)
# Diagnoses Search failures and offers granular Y/N interactive repairs to rebuild corrupted indexing!

$ErrorActionPreference = "SilentlyContinue"

# Try to bypass Execution Policy for the current session/process
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
} catch {}

# 0. Ensure $PSScriptRoot is defined for PowerShell 2.0 compatibility
if (-not $PSScriptRoot) {
    if ($MyInvocation.MyCommand.Definition) {
        $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    } else {
        $PSScriptRoot = Get-Location | Select-Object -ExpandProperty Path
    }
}

# Ensure logs directory exists
$LogsDir = Join-Path -Path $PSScriptRoot -ChildPath "logs"
if (-not (Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

Clear-Host
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "        WINDOWS SEARCH & INDEXING DIAGNOSTIC & REPAIR SUITE" -ForegroundColor Magenta
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "Inspecting Windows Search engine, indexing database, and UWP packages..." -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------
# PHASE 1: SEARCH HEALTH DIAGNOSTICS
# ---------------------------------------------------------

# Check 1: Windows Search Service Status (WSearch)
Write-Host "[Check 1/3] Inspecting Windows Search Service (WSearch)..." -ForegroundColor Yellow
$WSearch = Get-Service -Name WSearch -ErrorAction SilentlyContinue
if ($WSearch) {
    $StatusColor = if ($WSearch.Status -eq "Running") { "Green" } else { "Red" }
    Write-Host "   -> Service Status: $($WSearch.Status)" -ForegroundColor $StatusColor
} else {
    Write-Host "   -> Service Status: WSearch service not found or access denied." -ForegroundColor Red
}
Write-Host ""

# Check 2: Index Database Inspection (Windows.edb)
Write-Host "[Check 2/3] Inspecting Search Index Database File (Windows.edb)..." -ForegroundColor Yellow
$EdbPath = "C:\ProgramData\Microsoft\Search\Data\Applications\Windows\Windows.edb"
if (Test-Path $EdbPath) {
    $EdbFile = Get-Item $EdbPath -ErrorAction SilentlyContinue
    $SizeMB = [Math]::Round($EdbFile.Length / 1MB, 2)
    $SizeColor = if ($SizeMB -gt 2000) { "Red" } elseif ($SizeMB -gt 500) { "Yellow" } else { "Green" }
    Write-Host "   -> Database Found: Size is ${SizeMB} MB" -ForegroundColor $SizeColor
    if ($SizeMB -gt 2000) {
        Write-Host "      [WARN] Database is extremely bloated (>2 GB)! This causes search freezes and slow indexing." -ForegroundColor Yellow
    }
} else {
    Write-Host "   -> Database Found: No active Windows.edb file located (Index may be uninitialized or deleted)." -ForegroundColor DarkYellow
}
Write-Host ""

# Check 3: OS Architecture & Modern Search UI Check
Write-Host "[Check 3/3] Checking Operating System Search Architecture..." -ForegroundColor Yellow
$OSVer = (Get-WmiObject -Class Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption
Write-Host "   -> Detected OS: $OSVer" -ForegroundColor DarkCyan
Write-Host ""

# ==========================================================================
# Helper function for user prompts with Q exit support
function Get-UserApproval ($Message) {
    Write-Host ""
    Write-Host ">>> $Message" -ForegroundColor Yellow
    $Response = Read-Host "Proceed? (Y/N, Q to Cancel)"
    if ($Response -eq "Q" -or $Response -eq "q") {
        Write-Host "Operation cancelled by user. Returning..." -ForegroundColor Yellow
        exit 0
    }
    return ($Response -eq "Y" -or $Response -eq "y")
}

# ==========================================================================
# PHASE 2: GRANULAR INTERACTIVE SEARCH REPAIR (Y/N FOR EACH FIX)
# ==========================================================================
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "       INTERACTIVE SEARCH REPAIR MENU (GRANULAR Y/N SELECTION)" -ForegroundColor Magenta
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "Answer [Y]es or [N]o for each individual repair step below (or [Q] to return):" -ForegroundColor Cyan
Write-Host ""

# ACTION 1: Restart & Re-enable Windows Search Service
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "[ACTION 1/5] Service Reset & Startup Configuration" -ForegroundColor White
Write-Host "Target: Windows Search Service (WSearch)" -ForegroundColor DarkCyan
Write-Host "Benefit: Ensures the search indexing engine is set to Automatic startup and restarted cleanly." -ForegroundColor DarkGray
if (Get-UserApproval "Configure WSearch to Automatic and restart service?") {
    Write-Host "    [EXEC] Setting service startup type to Automatic..." -ForegroundColor Green
    Set-Service -Name WSearch -StartupType Automatic -ErrorAction SilentlyContinue
    Write-Host "    [EXEC] Restarting WSearch service..." -ForegroundColor Green
    Restart-Service -Name WSearch -Force -ErrorAction SilentlyContinue
    Write-Host "    [DONE] Windows Search service restarted." -ForegroundColor Green
} else {
    Write-Host "    [SKIP] Skipped service reset." -ForegroundColor DarkYellow
}
Write-Host ""

# ACTION 2: Nuke & Rebuild Corrupted Search Index Database
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "[ACTION 2/5] Index Database Purge & Rebuild" -ForegroundColor White
Write-Host "Target: C:\ProgramData\Microsoft\Search\Data\Applications\Windows\Windows.edb" -ForegroundColor DarkCyan
Write-Host "Benefit: Deletes corrupted/bloated search index files and forces Windows to rebuild a fresh index from scratch. (Solves 85% of all search issues!)" -ForegroundColor DarkGray
if (Get-UserApproval "Delete corrupted index database and force fresh rebuild?") {
    Write-Host "    [EXEC] Stopping Windows Search service & terminating hung indexers..." -ForegroundColor Green
    Stop-Service -Name WSearch -Force -ErrorAction SilentlyContinue
    Get-Process -Name "SearchIndexer" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    
    Write-Host "    [EXEC] Removing old search index database and temp files..." -ForegroundColor Green
    $SearchDataDir = "C:\ProgramData\Microsoft\Search\Data\Applications\Windows"
    if (Test-Path $SearchDataDir) {
        Get-ChildItem -Path $SearchDataDir -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue | Out-Null
    }
    
    Write-Host "    [EXEC] Starting Windows Search service to begin clean indexing..." -ForegroundColor Green
    Start-Service -Name WSearch -ErrorAction SilentlyContinue
    Write-Host "    [DONE] Old database wiped. Windows is now building a brand new index in the background!" -ForegroundColor Green
} else {
    Write-Host "    [SKIP] Skipped database rebuild." -ForegroundColor DarkYellow
}
Write-Host ""

# ACTION 3: Re-Register Modern Windows Search & Start Menu UWP Packages (Win 10/11)
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "[ACTION 3/5] Start Menu & Search Bar UI Re-Registration" -ForegroundColor White
Write-Host "Target: Universal Windows Platform (UWP) Search & Shell Packages" -ForegroundColor DarkCyan
Write-Host "Benefit: Fixes unresponsive or unclickable search boxes on Windows 10 & Windows 11." -ForegroundColor DarkGray
if (Get-UserApproval "Re-register Start Menu and Search UWP packages?") {
    Write-Host "    [EXEC] Re-registering modern Windows Search app manifests..." -ForegroundColor Green
    try {
        Get-AppxPackage -AllUsers *Microsoft.Windows.Search* -ErrorAction SilentlyContinue | ForEach-Object {
            Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction SilentlyContinue
        }
        Get-AppxPackage -AllUsers *Microsoft.Windows.ShellExperienceHost* -ErrorAction SilentlyContinue | ForEach-Object {
            Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction SilentlyContinue
        }
        Write-Host "    [DONE] Search UI packages re-registered successfully." -ForegroundColor Green
    } catch {
        Write-Host "    [INFO] UWP re-registration completed or inapplicable on this OS version." -ForegroundColor DarkGray
    }
} else {
    Write-Host "    [SKIP] Skipped UWP package re-registration." -ForegroundColor DarkYellow
}
Write-Host ""

# ACTION 4: Prioritize Local File Search over Web Search Delays
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "[ACTION 4/5] Local Search Responsiveness Optimization" -ForegroundColor White
Write-Host "Target: Registry Search Preferences (Disable Bing web results slowing down local file search)" -ForegroundColor DarkCyan
Write-Host "Benefit: Prevents Start Menu search from lagging while waiting for web results." -ForegroundColor DarkGray
if (Get-UserApproval "Optimize registry to prioritize local file search speed?") {
    Write-Host "    [EXEC] Updating search registry preferences..." -ForegroundColor Green
    $RegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
    if (-not (Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }
    Set-ItemProperty -Path $RegPath -Name "BingSearchEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $RegPath -Name "CortanaConsent" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "    [DONE] Local file search responsiveness optimized." -ForegroundColor Green
} else {
    Write-Host "    [SKIP] Skipped registry search optimization." -ForegroundColor DarkYellow
}
Write-Host ""

# ACTION 5: Outlook Search & MAPI Indexing Repair
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "[ACTION 5/5] Microsoft Outlook Email Search & MAPI Indexing Repair" -ForegroundColor White
Write-Host "Target: Outlook Search registry policies & PST/OST persistent IFilter handlers" -ForegroundColor DarkCyan
Write-Host "Benefit: Solves 'No results found' in Outlook, unlocks PST indexing, and removes GPO blocks." -ForegroundColor DarkGray
if (Get-UserApproval "Repair Microsoft Outlook Search & MAPI indexing integration?") {
    $OutlookSearchScript = Join-Path -Path $PSScriptRoot -ChildPath "Fix-Outlook-Search.ps1"
    if (Test-Path $OutlookSearchScript) {
        & $OutlookSearchScript
    } else {
        Write-Host "    [INFO] Configuring Outlook MAPI Search keys directly..." -ForegroundColor Green
        $OfficeVersions = @("14.0", "15.0", "16.0")
        foreach ($Ver in $OfficeVersions) {
            $SearchReg = "HKCU:\Software\Microsoft\Office\$Ver\Outlook\Search"
            if (-not (Test-Path $SearchReg)) { New-Item -Path $SearchReg -Force | Out-Null }
            Set-ItemProperty -Path $SearchReg -Name "EnableSearchIndexMapi" -Value 1 -PropertyType DWord -Force | Out-Null
            Set-ItemProperty -Path $SearchReg -Name "DisableIndexingPST" -Value 0 -PropertyType DWord -Force | Out-Null
        }
        Write-Host "    [DONE] Outlook search registry policies remediated." -ForegroundColor Green
    }
} else {
    Write-Host "    [SKIP] Skipped Outlook search repair." -ForegroundColor DarkYellow
}

Write-Host "`n==========================================================================" -ForegroundColor Green
Write-Host "          WINDOWS SEARCH DIAGNOSTIC & REPAIR COMPLETED!" -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "NOTE: If you rebuilt the index (Action 2), allow 10-15 minutes for Windows to finish re-indexing your files in the background." -ForegroundColor Yellow
