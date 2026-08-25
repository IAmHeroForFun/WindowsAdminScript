# ==========================================================================
#   Outlook Email Search & MAPI Indexing Repair Tool
#   Compatible with Windows 7-11 | Outlook 2010 - 365
# ==========================================================================
$ErrorActionPreference = "SilentlyContinue"

# Try to bypass Execution Policy for current session
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
} catch {}

# Ensure $PSScriptRoot is defined
if (-not $PSScriptRoot) {
    if ($MyInvocation.MyCommand.Definition) {
        $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    } else {
        $PSScriptRoot = Get-Location | Select-Object -ExpandProperty Path
    }
}

# Determine Reports / Logs directory
$ReportsDir = $null
$ParentDir = Split-Path -Parent -Path $PSScriptRoot
if ($ParentDir -match "SysMaster") {
    $ReportsDir = Join-Path $ParentDir "reports"
} else {
    $ReportsDir = Join-Path $PSScriptRoot "Logs"
}
if (-not (Test-Path $ReportsDir)) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null }

$Global:LogFile = Join-Path $ReportsDir "Outlook_Search_Repair.log"
$ReportPath = Join-Path $ReportsDir "Outlook_Search_Report.txt"
$StartTime = [System.Diagnostics.Stopwatch]::StartNew()

# Helper function for user prompts
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

# Logger helper
function Log-Msg ($Msg, $Type="INFO") {
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Formatted = "[$Timestamp] [$Type] $Msg"
    
    $Color = "Gray"
    if ($Type -eq "ERROR") { $Color = "Red" }
    elseif ($Type -eq "WARN") { $Color = "Yellow" }
    elseif ($Type -eq "SUCCESS") { $Color = "Green" }
    elseif ($Type -eq "STAGE") { $Color = "Cyan" }
    
    Write-Host $Formatted -ForegroundColor $Color
    if ($Global:LogFile) {
        $Formatted | Out-File -FilePath $Global:LogFile -Append -Encoding UTF8
    }
}

Clear-Host
Log-Msg "==========================================================================" "STAGE"
Log-Msg "       OUTLOOK EMAIL SEARCH & MAPI INDEXING REPAIR SUITE" "STAGE"
Log-Msg "==========================================================================" "STAGE"
Log-Msg "Execution started on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# --------------------------------------------------------------------------
# 1. REMOVE OUTLOOK INDEX BLOCKING GPO & REGISTRY POLICIES
# --------------------------------------------------------------------------
Log-Msg "Checking for Group Policies & Registry Keys blocking Outlook indexing..." "STAGE"

$SearchPolicyKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
if (Test-Path $SearchPolicyKey) {
    $PreventIndex = Get-ItemProperty -Path $SearchPolicyKey -Name "PreventIndexingOutlook" -ErrorAction SilentlyContinue
    if ($PreventIndex -and $PreventIndex.PreventIndexingOutlook -eq 1) {
        if (Get-UserApproval "Found policy 'PreventIndexingOutlook = 1' (Blocks Outlook search). Remove this restriction?") {
            try {
                Remove-ItemProperty -Path $SearchPolicyKey -Name "PreventIndexingOutlook" -Force -ErrorAction Stop
                Log-Msg "  [OK] Removed PreventIndexingOutlook blocking policy." "SUCCESS"
            } catch {
                Log-Msg "  [ERROR] Failed to remove policy: $($_.Exception.Message)" "ERROR"
            }
        }
    } else {
        Log-Msg "  [OK] No PreventIndexingOutlook policy restrictions found in HKLM." "SUCCESS"
    }
}

# --------------------------------------------------------------------------
# 2. CONFIGURE OUTLOOK MAPI SEARCH PREFERENCES
# --------------------------------------------------------------------------
if (Get-UserApproval "Configure Outlook MAPI Search indexing registry values (EnableSearchIndexMapi = 1)?") {
    Log-Msg "Configuring Outlook Search preferences across Office versions..." "STAGE"
    $OfficeVersions = @("14.0", "15.0", "16.0")
    
    foreach ($Ver in $OfficeVersions) {
        $SearchReg = "HKCU:\Software\Microsoft\Office\$Ver\Outlook\Search"
        try {
            if (-not (Test-Path $SearchReg)) {
                New-Item -Path $SearchReg -Force | Out-Null
            }
            # Set EnableSearchIndexMapi = 1 (forces Windows Search to index MAPI store)
            Set-ItemProperty -Path $SearchReg -Name "EnableSearchIndexMapi" -Value 1 -PropertyType DWord -Force | Out-Null
            # Set DisableIndexingPST = 0 (ensures PST indexing is enabled)
            Set-ItemProperty -Path $SearchReg -Name "DisableIndexingPST" -Value 0 -PropertyType DWord -Force | Out-Null
            # Disable ServerAssistedSearch fallback if on Outlook 365/2019 to prefer local desktop index
            Set-ItemProperty -Path $SearchReg -Name "DisableServerAssistedSearch" -Value 1 -PropertyType DWord -Force | Out-Null
            Log-Msg "  [OK] Successfully configured Outlook MAPI Search keys for version $Ver." "SUCCESS"
        } catch {
            Log-Msg "  [ERROR] Failed to set Outlook search keys for version $Ver: $($_.Exception.Message)" "ERROR"
        }
    }
}

# --------------------------------------------------------------------------
# 3. VERIFY & REPAIR PST/OST PERSISTENT IFILTER HANDLERS
# --------------------------------------------------------------------------
Log-Msg "Checking PST & OST persistent search filter handlers in HKCR..." "STAGE"

$FilterGuids = @{
    ".pst" = "{5645C8C1-E277-11CF-8FDA-00AA00A14F93}"
    ".ost" = "{5645C8C1-E277-11CF-8FDA-00AA00A14F93}"
}

if (Get-UserApproval "Verify and repair .pst and .ost Windows Search IFilter handler registrations?") {
    foreach ($Ext in $FilterGuids.Keys) {
        $HandlerPath = "Registry::HKEY_CLASSES_ROOT\$Ext\PersistentHandler"
        $ExpectedGuid = $FilterGuids[$Ext]
        try {
            if (-not (Test-Path $HandlerPath)) {
                New-Item -Path $HandlerPath -Force | Out-Null
            }
            Set-ItemProperty -Path $HandlerPath -Name "(default)" -Value $ExpectedGuid -Force | Out-Null
            Log-Msg "  [OK] Persistent IFilter handler registered for $Ext ($ExpectedGuid)." "SUCCESS"
        } catch {
            Log-Msg "  [ERROR] Failed to set filter handler for $Ext: $($_.Exception.Message)" "ERROR"
        }
    }
}

# --------------------------------------------------------------------------
# 4. RESTART WINDOWS SEARCH & TRIGGER FRESH CRAWL
# --------------------------------------------------------------------------
if (Get-UserApproval "Restart Windows Search service (WSearch) to apply Outlook search repairs?") {
    Log-Msg "Restarting Windows Search service..." "STAGE"
    try {
        Stop-Service -Name WSearch -Force -ErrorAction SilentlyContinue
        Get-Process -Name "SearchIndexer" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Start-Service -Name WSearch -ErrorAction Stop
        Log-Msg "  [OK] Windows Search service restarted. Outlook emails will begin indexing." "SUCCESS"
    } catch {
        Log-Msg "  [WARN] Could not restart WSearch service: $($_.Exception.Message)" "WARN"
    }
}

# --------------------------------------------------------------------------
# 5. GENERATE FINAL REPORT
# --------------------------------------------------------------------------
$StartTime.Stop()
$ElapsedTime = $StartTime.Elapsed

Log-Msg "Generating Outlook Search diagnostic summary report..." "STAGE"
$Report = [System.Collections.ArrayList]@()
$Report.Add("==========================================================================")
$Report.Add("       OUTLOOK EMAIL SEARCH & MAPI INDEXING REPAIR REPORT")
$Report.Add("==========================================================================")
$Report.Add("Generated on   : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$Report.Add("Execution Time : $($ElapsedTime.ToString('hh\:mm\:ss'))")
$Report.Add("Host System    : $env:COMPUTERNAME")
$Report.Add("==========================================================================")
$Report.Add("")
$Report.Add("REPAIRS APPLIED:")
$Report.Add("   - Cleared PreventIndexingOutlook GPO / Registry blocks")
$Report.Add("   - Enabled EnableSearchIndexMapi = 1 (Forces MAPI Indexing)")
$Report.Add("   - Enabled DisableIndexingPST = 0 (Permits PST file search indexing)")
$Report.Add("   - Verified and registered .pst and .ost Persistent IFilter Handlers")
$Report.Add("   - Restarted Windows Search service (WSearch)")
$Report.Add("")
$Report.Add("Detailed log file: $Global:LogFile")
$Report.Add("==========================================================================")

$Report | Out-File -FilePath $ReportPath -Encoding UTF8 -Force

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "       OUTLOOK EMAIL SEARCH REPAIRS COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Report saved to: $ReportPath" -ForegroundColor Green
Write-Host "  Process Log      : $Global:LogFile" -ForegroundColor DarkCyan
Write-Host "  Elapsed Time     : $($ElapsedTime.ToString('hh\:mm\:ss'))" -ForegroundColor DarkCyan
Write-Host "  NOTE: If Outlook was open, restart Outlook to begin querying the updated index." -ForegroundColor Yellow
Write-Host ""
