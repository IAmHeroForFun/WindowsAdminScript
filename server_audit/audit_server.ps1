# Main Server Infrastructure & Forensic Audit Suite
# Compatible with Windows Server 2008 R2 (PS 2.0) through Windows Server 2022/2025 (PS 5.1 & 7+)
# Extracts User Accounts, Group Policy settings, Network Shares, and Custom Tasks into Excel-ready CSV reports!

$ErrorActionPreference = "SilentlyContinue"

# 0. Ensure $PSScriptRoot is defined for PowerShell 2.0 compatibility
if (-not $PSScriptRoot) {
    if ($MyInvocation.MyCommand.Definition) {
        $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    } else {
        $PSScriptRoot = Get-Location | Select-Object -ExpandProperty Path
    }
}

# Ensure reports directory exists
$ReportsDir = Join-Path -Path $PSScriptRoot -ChildPath "reports"
if (-not (Test-Path $ReportsDir)) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null }

Clear-Host
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "         MAIN SERVER FORENSIC AUDIT & CONFIGURATION EXTRACTION" -ForegroundColor Magenta
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "Target Server: $env:COMPUTERNAME | Execution Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "Extracting configuration left behind by previous IT administration..." -ForegroundColor DarkCyan
Write-Host ""

# ---------------------------------------------------------
# PHASE 1: USER ACCOUNTS & PRIVILEGED ADMINS AUDIT
# ---------------------------------------------------------
Write-Host "[Audit 1/5] Extracting User Accounts & Admin Group Memberships into CSV..." -ForegroundColor Yellow
$UsersCsvPath = Join-Path -Path $ReportsDir -ChildPath "users_and_admins_audit_$($env:COMPUTERNAME).csv"
$UserList = New-Object System.Collections.ArrayList

# Check if Active Directory module is available (Domain Controller)
$IsAD = $false
if (Get-Command Get-ADUser -ErrorAction SilentlyContinue) {
    $IsAD = $true
    Write-Host "   -> Active Directory detected. Extracting domain user database..." -ForegroundColor Green
    $ADUsers = Get-ADUser -Filter * -Properties DisplayName, Enabled, LastLogonDate, PasswordLastSet, PasswordNeverExpires -ErrorAction SilentlyContinue
    foreach ($U in $ADUsers) {
        $Groups = (Get-ADPrincipalGroupMembership -Identity $U.SamAccountName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name) -join "; "
        $UserObj = New-Object PSObject -Property @{
            AccountName = $U.SamAccountName
            FullName = $U.DisplayName
            AccountType = "Active Directory Domain User"
            Status = if ($U.Enabled) { "Enabled" } else { "Disabled" }
            PasswordNeverExpires = $U.PasswordNeverExpires
            LastLogonDate = $U.LastLogonDate
            PasswordLastSet = $U.PasswordLastSet
            GroupMemberships = $Groups
        }
        [void]$UserList.Add($UserObj)
    }
} else {
    Write-Host "   -> Standalone/Local Server detected. Extracting local user database..." -ForegroundColor DarkCyan
    $LocalUsers = Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount=True" -ErrorAction SilentlyContinue
    foreach ($U in $LocalUsers) {
        $Status = if ($U.Disabled) { "Disabled" } else { "Enabled" }
        $UserObj = New-Object PSObject -Property @{
            AccountName = $U.Name
            FullName = $U.FullName
            AccountType = "Local Server User"
            Status = $Status
            PasswordNeverExpires = $U.PasswordExpires -eq $false
            LastLogonDate = "N/A"
            PasswordLastSet = "N/A"
            GroupMemberships = $U.Description
        }
        [void]$UserList.Add($UserObj)
    }
}

# Ensure uniform schema export
$UserList | Select-Object AccountName, FullName, AccountType, Status, PasswordNeverExpires, LastLogonDate, PasswordLastSet, GroupMemberships | Export-Csv -Path $UsersCsvPath -NoTypeInformation -Encoding UTF8
Write-Host "   [DONE] User audit spreadsheet generated: reports\users_and_admins_audit_$($env:COMPUTERNAME).csv" -ForegroundColor Green
Write-Host ""

# ---------------------------------------------------------
# PHASE 2: GROUP POLICY OBJECTS (GPO) READABLE HTML REPORT
# ---------------------------------------------------------
Write-Host "[Audit 2/5] Generating Readable Group Policy (GPO) HTML & Text Reports..." -ForegroundColor Yellow
$GpoHtmlPath = Join-Path -Path $ReportsDir -ChildPath "GPO_Readable_Report_$($env:COMPUTERNAME).html"
$GpoTxtPath = Join-Path -Path $ReportsDir -ChildPath "GPO_Summary_$($env:COMPUTERNAME).txt"

# Generate comprehensive HTML report detailing all applied group policies and custom registry rules
Write-Host "   -> Running comprehensive Group Policy result extraction..." -ForegroundColor DarkCyan
cmd.exe /c "gpresult /h `"$GpoHtmlPath`" /f" 2>&1 | Out-Null
cmd.exe /c "gpresult /r > `"$GpoTxtPath`"" 2>&1 | Out-Null

if (Test-Path $GpoHtmlPath) {
    Write-Host "   [DONE] Readable HTML GPO web report generated: reports\GPO_Readable_Report_$($env:COMPUTERNAME).html" -ForegroundColor Green
    Write-Host "          (Open this HTML file in Edge or Chrome to view all custom settings & security policies!)" -ForegroundColor DarkGray
} else {
    Write-Host "   [WARN] Could not generate HTML report (may require elevated administrator permissions)." -ForegroundColor Yellow
}
Write-Host ""

# ---------------------------------------------------------
# PHASE 3: NETWORK SHARES & OPEN FOLDER PERMISSIONS AUDIT
# ---------------------------------------------------------
Write-Host "[Audit 3/5] Auditing Shared Folders & Network Exposure into CSV..." -ForegroundColor Yellow
$SharesCsvPath = Join-Path -Path $ReportsDir -ChildPath "network_shares_audit_$($env:COMPUTERNAME).csv"
$ShareList = New-Object System.Collections.ArrayList

$Shares = Get-WmiObject -Class Win32_Share -ErrorAction SilentlyContinue
foreach ($S in $Shares) {
    $ShareTypeStr = switch ($S.Type) { 0 {"Disk Drive Share"} 1 {"Print Queue Share"} 2147483648 {"Admin Disk Drive Share"} 2147483651 {"IPC Admin Share"} default {"Other Share"} }
    $ShareObj = New-Object PSObject -Property @{
        ShareName = $S.Name
        FolderPath = $S.Path
        ShareType = $ShareTypeStr
        Description = $S.Description
    }
    [void]$ShareList.Add($ShareObj)
}
$ShareList | Select-Object ShareName, FolderPath, ShareType, Description | Export-Csv -Path $SharesCsvPath -NoTypeInformation -Encoding UTF8
Write-Host "   [DONE] Network shares spreadsheet generated: reports\network_shares_audit_$($env:COMPUTERNAME).csv" -ForegroundColor Green
Write-Host ""

# ---------------------------------------------------------
# PHASE 4: SERVER ROLES & AUTO-STARTING SERVICES AUDIT
# ---------------------------------------------------------
Write-Host "[Audit 4/5] Extracting Server Roles & Custom Services into CSV..." -ForegroundColor Yellow
$ServicesCsvPath = Join-Path -Path $ReportsDir -ChildPath "auto_starting_services_$($env:COMPUTERNAME).csv"
$SvcList = New-Object System.Collections.ArrayList

$Services = Get-WmiObject -Class Win32_Service -Filter "StartMode='Auto'" -ErrorAction SilentlyContinue
foreach ($S in $Services) {
    if ($S.PathName -notlike "*C:\Windows\system32*" -or $S.Name -like "*AD*" -or $S.Name -like "*DNS*" -or $S.Name -like "*SQL*") {
        $SvcObj = New-Object PSObject -Property @{
            ServiceName = $S.Name
            DisplayName = $S.DisplayName
            State = $S.State
            StartMode = $S.StartMode
            ExecutablePath = $S.PathName
            LogonAsAccount = $S.StartName
        }
        [void]$SvcList.Add($SvcObj)
    }
}
$SvcList | Select-Object ServiceName, DisplayName, State, StartMode, ExecutablePath, LogonAsAccount | Export-Csv -Path $ServicesCsvPath -NoTypeInformation -Encoding UTF8
Write-Host "   [DONE] Custom/Critical services spreadsheet generated: reports\auto_starting_services_$($env:COMPUTERNAME).csv" -ForegroundColor Green
Write-Host ""

# ---------------------------------------------------------
# PHASE 5: CUSTOM SCHEDULED TASKS FORENSIC AUDIT
# ---------------------------------------------------------
Write-Host "[Audit 5/5] Checking Task Scheduler for Custom Automated Scripts left by previous IT..." -ForegroundColor Yellow
$TasksCsvPath = Join-Path -Path $ReportsDir -ChildPath "custom_scheduled_tasks_$($env:COMPUTERNAME).csv"
cmd.exe /c "schtasks.exe /query /fo CSV > `"$TasksCsvPath`"" 2>&1 | Out-Null
if (Test-Path $TasksCsvPath) {
    Write-Host "   [DONE] Scheduled tasks spreadsheet generated: reports\custom_scheduled_tasks_$($env:COMPUTERNAME).csv" -ForegroundColor Green
} else {
    Write-Host "   [WARN] Could not query scheduled tasks." -ForegroundColor Yellow
}

Write-Host "`n==========================================================================" -ForegroundColor Green
Write-Host "         MAIN SERVER AUDIT COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "All forensic spreadsheets and readable GPO HTML files have been saved to:" -ForegroundColor Cyan
Write-Host " -> $ReportsDir" -ForegroundColor Yellow
