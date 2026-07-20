# Main Server Infrastructure, Configuration Drift & Forensic Audit Suite
# Compatible with Windows Server 2008 R2 (PS 2.0) through Windows Server 2022/2025 (PS 5.1 & 7+)
# Extracts OS metadata, GPOs, user privileges, network settings, backup states, and software configurations.

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

# Centralized report directory handling
$ReportsDir = $null
$ParentDir = Split-Path -Parent -Path $PSScriptRoot
if ($ParentDir -match "SysMaster") {
    $ReportsDir = Join-Path $ParentDir "reports"
} else {
    $ReportsDir = Join-Path $PSScriptRoot "reports"
}
if (-not (Test-Path $ReportsDir)) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null }

Clear-Host
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "         MAIN SERVER FORENSIC AUDIT & CONFIGURATION EXTRACTION" -ForegroundColor Magenta
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "Target Server: $env:COMPUTERNAME | Execution Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "Extracting configuration profiles and audit data..." -ForegroundColor DarkCyan
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray

# Helper function for interactive Y/N prompts
function Ask-AuditSection ($SectionName) {
    while ($true) {
        $Response = Read-Host "Audit $SectionName? [Y/N]"
        if ($Response -eq "Y" -or $Response -eq "y") { return $true }
        if ($Response -eq "N" -or $Response -eq "n") { return $false }
        Write-Host "Please enter Y (yes) or N (no)." -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------
# PHASE 1: OS INSTALLATION & WINDOWS UPDATE POLICIES AUDIT
# ---------------------------------------------------------
if (Ask-AuditSection "OS Installation History, Hotfixes & Windows Update Policies") {
    Write-Host "`n[+] Executing OS Install & Patch Policy Audit..." -ForegroundColor Yellow
    
    $OS = Get-WmiObject Win32_OperatingSystem
    $InstallDate = $OS.ConvertToDateTime($OS.InstallDate)
    $LastBoot = $OS.ConvertToDateTime($OS.LastBootUpTime)
    
    # Read Windows Update Reboot Policy
    $WUPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    $NoAutoReboot = "Not Configured"
    if (Test-Path $WUPath) {
        $NoAutoRebootVal = (Get-ItemProperty -Path $WUPath -Name "NoAutoRebootWithLoggedOnUsers" -ErrorAction SilentlyContinue).NoAutoRebootWithLoggedOnUsers
        if ($NoAutoRebootVal -ne $null) {
            $NoAutoReboot = if ($NoAutoRebootVal -eq 1) { "Enabled (Prevent auto-restart when users logged on)" } else { "Disabled" }
        }
    }
    
    $SystemInfo = [PSCustomObject]@{
        OSName = $OS.Caption
        Version = $OS.Version
        BuildNumber = $OS.BuildNumber
        InstallDate = $InstallDate
        LastBootUpTime = $LastBoot
        AutoRebootPolicy = $NoAutoReboot
        ComputerName = $env:COMPUTERNAME
    }
    
    # Export System Info
    $SysCsvPath = Join-Path -Path $ReportsDir -ChildPath "server_system_info_$($env:COMPUTERNAME).csv"
    @($SystemInfo) | Export-Csv -Path $SysCsvPath -NoTypeInformation -Encoding UTF8
    
    # Export Hotfixes
    $HotfixCsvPath = Join-Path -Path $ReportsDir -ChildPath "installed_hotfixes_$($env:COMPUTERNAME).csv"
    $Hotfixes = Get-HotFix
    if ($Hotfixes) {
        $Hotfixes | Select-Object Source, Description, HotFixID, InstalledBy, InstalledOn | Export-Csv -Path $HotfixCsvPath -NoTypeInformation -Encoding UTF8
        Write-Host "   -> Found $($Hotfixes.Count) installed system updates." -ForegroundColor Green
    } else {
        Write-Host "   -> No updates/hotfixes retrieved." -ForegroundColor Yellow
    }
    
    Write-Host "   [DONE] Reports generated:" -ForegroundColor Green
    Write-Host "          - reports\server_system_info_$($env:COMPUTERNAME).csv" -ForegroundColor DarkGray
    Write-Host "          - reports\installed_hotfixes_$($env:COMPUTERNAME).csv" -ForegroundColor DarkGray
} else {
    Write-Host "   Skipped OS Installation & Update Policies Audit." -ForegroundColor DarkGray
}
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray

# ---------------------------------------------------------
# PHASE 2: INSTALLED APPLICATIONS & SERVER ROLES AUDIT
# ---------------------------------------------------------
if (Ask-AuditSection "Installed Software Applications & Enabled Server Roles") {
    Write-Host "`n[+] Executing Installed Applications & Server Roles Audit..." -ForegroundColor Yellow
    
    # 1. Traditional applications list
    $RegPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    $InstalledApps = Get-ItemProperty -Path $RegPaths -ErrorAction SilentlyContinue | 
                     Where-Object { $_.DisplayName -and $_.SystemComponent -ne 1 } | 
                     Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
                     Sort-Object DisplayName
                     
    $AppsCsvPath = Join-Path -Path $ReportsDir -ChildPath "installed_software_$($env:COMPUTERNAME).csv"
    if ($InstalledApps) {
        $InstalledApps | Export-Csv -Path $AppsCsvPath -NoTypeInformation -Encoding UTF8
        Write-Host "   -> Found $($InstalledApps.Count) installed applications." -ForegroundColor Green
    } else {
        Write-Host "   -> No installed software detected in registry." -ForegroundColor Yellow
    }
    
    # 2. Server Roles and Features list
    $FeaturesCsvPath = Join-Path -Path $ReportsDir -ChildPath "installed_features_$($env:COMPUTERNAME).csv"
    $IsServer = (Get-WmiObject Win32_OperatingSystem).ProductType -ne 1 # 1 = Workstation, 2/3 = Domain Controller/Server
    
    if ($IsServer) {
        $ServerFeatures = Get-Command Get-WindowsFeature -ErrorAction SilentlyContinue
        if ($ServerFeatures) {
            Get-WindowsFeature | Where-Object { $_.Installed } | Select-Object Name, DisplayName, FeatureType | Export-Csv -Path $FeaturesCsvPath -NoTypeInformation -Encoding UTF8
            Write-Host "   -> Server Roles & Features extracted." -ForegroundColor Green
        } else {
            # Fallback using DISM or WMI on older Server OS
            Get-WmiObject -Class Win32_OptionalFeature | Where-Object { $_.InstallState -eq 1 } | Select-Object Name, Caption | Export-Csv -Path $FeaturesCsvPath -NoTypeInformation -Encoding UTF8
            Write-Host "   -> Optional Features extracted via WMI." -ForegroundColor Green
        }
    } else {
        # Desktop Windows Client
        Get-WmiObject -Class Win32_OptionalFeature | Where-Object { $_.InstallState -eq 1 } | Select-Object Name, Caption | Export-Csv -Path $FeaturesCsvPath -NoTypeInformation -Encoding UTF8
        Write-Host "   -> Client optional features extracted." -ForegroundColor Green
    }
    
    Write-Host "   [DONE] Reports generated:" -ForegroundColor Green
    Write-Host "          - reports\installed_software_$($env:COMPUTERNAME).csv" -ForegroundColor DarkGray
    Write-Host "          - reports\installed_features_$($env:COMPUTERNAME).csv" -ForegroundColor DarkGray
} else {
    Write-Host "   Skipped Installed Applications & Roles Audit." -ForegroundColor DarkGray
}
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray

# ---------------------------------------------------------
# PHASE 3: GPO RESULTS, RDP SECURITY & LOGIN DISCLAIMERS
# ---------------------------------------------------------
if (Ask-AuditSection "Group Policy (GPO), RDP Port Security & Legal Disclaimers") {
    Write-Host "`n[+] Executing Group Policy & RDP Security Policies Audit..." -ForegroundColor Yellow
    
    $GpoHtmlPath = Join-Path -Path $ReportsDir -ChildPath "GPO_Readable_Report_$($env:COMPUTERNAME).html"
    $GpoTxtPath = Join-Path -Path $ReportsDir -ChildPath "GPO_Summary_$($env:COMPUTERNAME).txt"
    $SecCsvPath = Join-Path -Path $ReportsDir -ChildPath "rdp_and_logon_policies_$($env:COMPUTERNAME).csv"
    
    # 1. Gpresult extraction
    cmd.exe /c "gpresult /h `"$GpoHtmlPath`" /f" 2>&1 | Out-Null
    cmd.exe /c "gpresult /r > `"$GpoTxtPath`"" 2>&1 | Out-Null
    
    # 2. Query RDP Security settings and Legal Notices
    $RdpPath = "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
    $LogonPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    
    $RdpPort = "3389"
    $RdpNla = "Unknown"
    if (Test-Path $RdpPath) {
        $RdpPortVal = (Get-ItemProperty -Path $RdpPath -Name "PortNumber" -ErrorAction SilentlyContinue).PortNumber
        if ($RdpPortVal -ne $null) { $RdpPort = $RdpPortVal.ToString() }
        
        $RdpNlaVal = (Get-ItemProperty -Path $RdpPath -Name "UserAuthentication" -ErrorAction SilentlyContinue).UserAuthentication
        if ($RdpNlaVal -ne $null) {
            $RdpNla = if ($RdpNlaVal -eq 1) { "Enabled (Network Level Authentication Required)" } else { "Disabled" }
        }
    }
    
    $LegalCaption = "None"
    $LegalText = "None"
    if (Test-Path $LogonPath) {
        $CapVal = (Get-ItemProperty -Path $LogonPath -Name "legalnoticecaption" -ErrorAction SilentlyContinue).legalnoticecaption
        if ($CapVal) { $LegalCaption = $CapVal }
        
        $TextVal = (Get-ItemProperty -Path $LogonPath -Name "legalnoticetext" -ErrorAction SilentlyContinue).legalnoticetext
        if ($TextVal) { $LegalText = $TextVal }
    }
    
    $SecPolicy = [PSCustomObject]@{
        RdpPort = $RdpPort
        RdpNlaStatus = $RdpNla
        LegalNoticeCaption = $LegalCaption
        LegalNoticeText = $LegalText
    }
    @($SecPolicy) | Export-Csv -Path $SecCsvPath -NoTypeInformation -Encoding UTF8
    
    Write-Host "   [DONE] Reports generated:" -ForegroundColor Green
    if (Test-Path $GpoHtmlPath) { Write-Host "          - reports\GPO_Readable_Report_$($env:COMPUTERNAME).html" -ForegroundColor DarkGray }
    Write-Host "          - reports\rdp_and_logon_policies_$($env:COMPUTERNAME).csv" -ForegroundColor DarkGray
} else {
    Write-Host "   Skipped GPO & Security Policies Audit." -ForegroundColor DarkGray
}
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray

# ---------------------------------------------------------
# PHASE 4: USER ACCOUNTS & PRIVILEGED ADMINS AUDIT
# ---------------------------------------------------------
if (Ask-AuditSection "User Accounts & Privilege Group Memberships") {
    Write-Host "`n[+] Executing User Accounts & Privilege Group Audit..." -ForegroundColor Yellow
    $UsersCsvPath = Join-Path -Path $ReportsDir -ChildPath "users_and_admins_audit_$($env:COMPUTERNAME).csv"
    $UserList = New-Object System.Collections.ArrayList
    
    $IsAD = $false
    if (Get-Command Get-ADUser -ErrorAction SilentlyContinue) {
        $IsAD = $true
        Write-Host "   -> Active Directory detected. Querying domain user accounts..." -ForegroundColor Green
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
        Write-Host "   -> Standalone/Local Server. Querying local user accounts..." -ForegroundColor DarkCyan
        $LocalUsers = Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount=True" -ErrorAction SilentlyContinue
        foreach ($U in $LocalUsers) {
            $Status = if ($U.Disabled) { "Disabled" } else { "Enabled" }
            
            # Find groups
            $GroupNames = @()
            $WmiUser = [ADSI]"WinNT://$env:COMPUTERNAME/$($U.Name),user"
            $Groups = $WmiUser.Groups()
            foreach ($G in $Groups) { $GroupNames += $G.GetType().InvokeMember("Name", 'GetProperty', $null, $G, $null) }
            
            $UserObj = New-Object PSObject -Property @{
                AccountName = $U.Name
                FullName = $U.FullName
                AccountType = "Local Server User"
                Status = $Status
                PasswordNeverExpires = $U.PasswordExpires -eq $false
                LastLogonDate = "N/A"
                PasswordLastSet = "N/A"
                GroupMemberships = ($GroupNames -join "; ")
            }
            [void]$UserList.Add($UserObj)
        }
    }
    
    $UserList | Select-Object AccountName, FullName, AccountType, Status, PasswordNeverExpires, LastLogonDate, PasswordLastSet, GroupMemberships | Export-Csv -Path $UsersCsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "   [DONE] Report generated: reports\users_and_admins_audit_$($env:COMPUTERNAME).csv" -ForegroundColor Green
} else {
    Write-Host "   Skipped User Accounts & Group Audit." -ForegroundColor DarkGray
}
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray

# ---------------------------------------------------------
# PHASE 5: NETWORK CONFIGURATIONS & CUSTOM DNS AUDIT
# ---------------------------------------------------------
if (Ask-AuditSection "Network Interfaces, IP Configuration & NTP Time Sync Setup") {
    Write-Host "`n[+] Executing Network IP & NTP Configuration Audit..." -ForegroundColor Yellow
    $NetCsvPath = Join-Path -Path $ReportsDir -ChildPath "network_config_$($env:COMPUTERNAME).csv"
    $NetList = @()
    
    # Check powershell command availability
    if (Get-Command Get-NetIPConfiguration -ErrorAction SilentlyContinue) {
        $Config = Get-NetIPConfiguration
        foreach ($Adapter in $Config) {
            # DNS Servers
            $Dns = ($Adapter.DNSServer | Select-Object -ExpandProperty ServerAddress) -join "; "
            $IPv4 = ($Adapter.IPv4Address | Select-Object -ExpandProperty IPAddress) -join "; "
            
            # Gateway
            $Gateway = ($Adapter.IPv4DefaultGateway | Select-Object -ExpandProperty NextHop) -join "; "
            
            $NetList += [PSCustomObject]@{
                InterfaceName = $Adapter.InterfaceAlias
                InterfaceDescription = $Adapter.InterfaceDescription
                Status = $Adapter.NetAdapter.Status
                IPv4Address = $IPv4
                DefaultGateway = $Gateway
                DNSServers = $Dns
            }
        }
    } else {
        # Fallback to WMI
        $Config = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True"
        foreach ($Adapter in $Config) {
            $IPv4 = ($Adapter.IPAddress | Where-Object { $_ -match "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$" }) -join "; "
            $Dns = ($Adapter.DNSServerSearchOrder) -join "; "
            $Gateway = ($Adapter.DefaultIPGateway) -join "; "
            
            $NetList += [PSCustomObject]@{
                InterfaceName = $Adapter.Description
                InterfaceDescription = $Adapter.Description
                Status = "Active/IPEnabled"
                IPv4Address = $IPv4
                DefaultGateway = $Gateway
                DNSServers = $Dns
            }
        }
    }
    
    $NetList | Export-Csv -Path $NetCsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "   [DONE] Network report generated: reports\network_config_$($env:COMPUTERNAME).csv" -ForegroundColor Green
    
    # NTP / Time Sync Audit
    Write-Host "   -> Querying NTP Time Sync Status..." -ForegroundColor DarkCyan
    $TimeSvc = Get-Service -Name "w32time" -ErrorAction SilentlyContinue
    $NtpSource = "N/A"
    $NtpStatus = "Service Stopped/Disabled"
    
    if ($TimeSvc -and $TimeSvc.Status -eq "Running") {
        # Query Source
        $SrcOutput = cmd.exe /c "w32tm /query /source 2>&1"
        if ($SrcOutput) { $NtpSource = ($SrcOutput -join " | ").Trim() }
        
        # Query Status
        $StatOutput = cmd.exe /c "w32tm /query /status 2>&1"
        if ($StatOutput) { $NtpStatus = ($StatOutput -join " | ").Trim() }
    }
    
    $TimeSyncObj = [PSCustomObject]@{
        W32TimeStatus = if ($TimeSvc) { $TimeSvc.Status } else { "Not Installed" }
        NTPServerSource = $NtpSource
        NTPSyncStatus = $NtpStatus
    }
    $TimeCsvPath = Join-Path -Path $ReportsDir -ChildPath "time_sync_config_$($env:COMPUTERNAME).csv"
    @($TimeSyncObj) | Export-Csv -Path $TimeCsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "   [DONE] Time Sync report generated: reports\time_sync_config_$($env:COMPUTERNAME).csv" -ForegroundColor Green
} else {
    Write-Host "   Skipped Network, IP & NTP Audit." -ForegroundColor DarkGray
}
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray

# ---------------------------------------------------------
# PHASE 6: SERVICES, SCHEDULED TASKS & IIS WEB SITES
# ---------------------------------------------------------
if (Ask-AuditSection "Active Services, Scheduled Tasks & IIS Web Site Configurations") {
    Write-Host "`n[+] Executing Services, Scheduled Tasks & IIS Audit..." -ForegroundColor Yellow
    
    $ServicesCsvPath = Join-Path -Path $ReportsDir -ChildPath "auto_starting_services_$($env:COMPUTERNAME).csv"
    $TasksCsvPath = Join-Path -Path $ReportsDir -ChildPath "custom_scheduled_tasks_$($env:COMPUTERNAME).csv"
    $IisCsvPath = Join-Path -Path $ReportsDir -ChildPath "iis_sites_config_$($env:COMPUTERNAME).csv"
    
    # 1. Custom/Critical Auto Services
    $SvcList = New-Object System.Collections.ArrayList
    $Services = Get-WmiObject -Class Win32_Service -Filter "StartMode='Auto'" -ErrorAction SilentlyContinue
    foreach ($S in $Services) {
        # Filter for non-standard services or key roles
        if ($S.PathName -notlike "*C:\Windows\system32*" -or $S.Name -like "*AD*" -or $S.Name -like "*DNS*" -or $S.Name -like "*SQL*" -or $S.PathName -notlike "*C:\Windows\System32*") {
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
    
    # 2. Scheduled Tasks list
    cmd.exe /c "schtasks.exe /query /fo CSV > `"$TasksCsvPath`"" 2>&1 | Out-Null
    
    # 3. IIS Web Sites bindings audit (if IIS active)
    $IisService = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
    if ($IisService -and $IisService.Status -eq "Running") {
        Write-Host "   -> IIS Web Server detected. Extracting hosted website configurations..." -ForegroundColor Green
        # Import WebAdministration Module
        Import-Module WebAdministration -ErrorAction SilentlyContinue
        if (Get-Command Get-Website -ErrorAction SilentlyContinue) {
            $Websites = Get-Website
            $WebsitesList = @()
            foreach ($Site in $Websites) {
                $Bindings = ($Site.Bindings.Collection | ForEach-Object { $_.BindingInformation }) -join "; "
                $WebsitesList += [PSCustomObject]@{
                    SiteName = $Site.Name
                    State = $Site.State
                    PhysicalPath = $Site.PhysicalPath
                    Bindings = $Bindings
                }
            }
            $WebsitesList | Export-Csv -Path $IisCsvPath -NoTypeInformation -Encoding UTF8
            Write-Host "   -> IIS report written successfully." -ForegroundColor Green
        }
    } else {
         Write-Host "   -> IIS service is not active/installed. Skipping web server bindings audit." -ForegroundColor DarkGray
    }
    
    Write-Host "   [DONE] Reports generated:" -ForegroundColor Green
    Write-Host "          - reports\auto_starting_services_$($env:COMPUTERNAME).csv" -ForegroundColor DarkGray
    Write-Host "          - reports\custom_scheduled_tasks_$($env:COMPUTERNAME).csv" -ForegroundColor DarkGray
    if (Test-Path $IisCsvPath) { Write-Host "          - reports\iis_sites_config_$($env:COMPUTERNAME).csv" -ForegroundColor DarkGray }
} else {
    Write-Host "   Skipped Services, Scheduled Tasks & IIS Audit." -ForegroundColor DarkGray
}
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray

# ---------------------------------------------------------
# PHASE 7: NETWORK SHARES AUDIT
# ---------------------------------------------------------
if (Ask-AuditSection "Shared Folders & Access Paths") {
    Write-Host "`n[+] Executing Shared Folders & Directory Exposure Audit..." -ForegroundColor Yellow
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
    Write-Host "   [DONE] Report generated: reports\network_shares_audit_$($env:COMPUTERNAME).csv" -ForegroundColor Green
} else {
    Write-Host "   Skipped Network Shares Audit." -ForegroundColor DarkGray
}
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray

# ---------------------------------------------------------
# PHASE 8: BACKUP SYSTEMS & VSS HEALTH AUDIT
# ---------------------------------------------------------
if (Ask-AuditSection "Windows Backup, VSS Writers & Third-party Backup Agents") {
    Write-Host "`n[+] Executing Backup Infrastructure & VSS Diagnostic Audit..." -ForegroundColor Yellow
    $BackupCsvPath = Join-Path -Path $ReportsDir -ChildPath "backup_and_vss_status_$($env:COMPUTERNAME).csv"
    
    # 1. Query local Windows Server Backup (wbadmin) status
    $LocalBackupStatus = "Not Active / Not Running"
    $BackupOutput = cmd.exe /c "wbadmin get status 2>&1"
    if ($BackupOutput -and $BackupOutput -notmatch "is not recognized" -and $BackupOutput -notmatch "error") {
        $LocalBackupStatus = ($BackupOutput -join " | ").Trim()
    }
    
    # 2. Check for third-party backup agent services
    $AgentServices = @()
    $Agents = @("Veeam*", "Acronis*", "BackupExec*", "ShadowProtect*", "Commvault*", "Datto*", "Backup*", "Cobian*", "Macrium*")
    $FoundServices = Get-Service -Name $Agents -ErrorAction SilentlyContinue
    if ($FoundServices) {
        foreach ($Svc in $FoundServices) {
            $AgentServices += "$($Svc.Name) (Status: $($Svc.Status), StartType: $($Svc.StartType))"
        }
    }
    $AgentServicesStr = if ($AgentServices) { $AgentServices -join "; " } else { "None Detected" }
    
    # 3. Check VSS Writers Health status
    $VssOutput = cmd.exe /c "vssadmin list writers"
    $FailingWriters = @()
    $TotalWriters = 0
    if ($VssOutput) {
        $CurrentWriter = ""
        foreach ($Line in $VssOutput) {
            if ($Line -match "Writer name:") {
                $CurrentWriter = $Line.Split("'")[1]
                $TotalWriters++
            }
            if ($Line -match "State:" -and $Line -notmatch "Stable") {
                $FailingWriters += "$CurrentWriter ($($Line.Trim()))"
            }
        }
    }
    $VssSummary = "Total Writers: $TotalWriters | Errors: $($FailingWriters.Count)"
    $VssErrorsStr = if ($FailingWriters) { $FailingWriters -join "; " } else { "None (All Writers Stable)" }
    
    $BackupAuditObj = [PSCustomObject]@{
        WindowsBackupStatus = $LocalBackupStatus
        ThirdPartyBackupAgents = $AgentServicesStr
        VssWritersSummary = $VssSummary
        FailingVssWriters = $VssErrorsStr
    }
    @($BackupAuditObj) | Export-Csv -Path $BackupCsvPath -NoTypeInformation -Encoding UTF8
    
    Write-Host "   -> Windows Backup status successfully checked." -ForegroundColor Green
    Write-Host "   -> Checked for third-party backup processes (Found: $($FoundServices.Count) agent services)." -ForegroundColor Green
    Write-Host "   -> Audited $TotalWriters VSS writers (Failing: $($FailingWriters.Count) writers)." -ForegroundColor Green
    
    Write-Host "   [DONE] Report generated: reports\backup_and_vss_status_$($env:COMPUTERNAME).csv" -ForegroundColor Green
} else {
    Write-Host "   Skipped Backup & VSS Health Audit." -ForegroundColor DarkGray
}

Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "         SERVER FORENSIC AUDIT SUMMARY REPORT COMPLETED" -ForegroundColor Magenta
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "All generated CSV spreadsheets and HTML reports are located in:" -ForegroundColor Cyan
Write-Host " -> $ReportsDir" -ForegroundColor Yellow
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "`nPress Enter to exit..." -ForegroundColor DarkGray; [void](Read-Host)
