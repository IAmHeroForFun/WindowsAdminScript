# ==============================================================================
# Windows Server & Client Shared Folder & NTFS Permission Auditor
# Compatible with Windows Server 2008 R2 through Windows Server 2025
# and Windows 7, 8, 8.1, 10, 11 (PowerShell 2.0 to 7.5+)
# ==============================================================================
# Dual-Layer Auditing:
#   Layer 1: SMB Share-Level Permissions (Who can connect over the network)
#   Layer 2: NTFS Folder-Level Permissions (Who has access on the disk)
# Exports comprehensive telemetry to CSV with ComputerName and LoggedOnUser.
# ==============================================================================

$ErrorActionPreference = "SilentlyContinue"

# Attempt to bypass Execution Policy in current process
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
if (-not (Test-Path $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null
}

# Identity Metadata
$TargetComputer = $env:COMPUTERNAME
$CurrentLoggedOnUser = $null
try {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    if ($identity -and $identity.Name) {
        $CurrentLoggedOnUser = $identity.Name
    }
} catch {}
if (-not $CurrentLoggedOnUser) {
    if ($env:USERDOMAIN -and $env:USERNAME) {
        $CurrentLoggedOnUser = "$($env:USERDOMAIN)\$($env:USERNAME)"
    } else {
        $CurrentLoggedOnUser = $env:USERNAME
    }
}

# Cross-version WMI/CIM Helper (compatible with PS 2.0 up to PS 7+)
function Get-UniversalWmiData {
    param(
        [string]$Class,
        [string]$Namespace = "root\cimv2",
        [string]$Filter = ""
    )
    # Prefer Get-CimInstance (PS 3.0+) if available
    if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue) {
        try {
            if ($Filter) {
                return @(Get-CimInstance -Namespace $Namespace -ClassName $Class -Filter $Filter -ErrorAction Stop)
            } else {
                return @(Get-CimInstance -Namespace $Namespace -ClassName $Class -ErrorAction Stop)
            }
        } catch {}
    }
    # Fallback to Get-WmiObject (PS 2.0 / legacy Windows Server)
    if (Get-Command Get-WmiObject -ErrorAction SilentlyContinue) {
        try {
            if ($Filter) {
                return @(Get-WmiObject -Namespace $Namespace -Class $Class -Filter $Filter -ErrorAction Stop)
            } else {
                return @(Get-WmiObject -Namespace $Namespace -Class $Class -ErrorAction Stop)
            }
        } catch {}
    }
    return @()
}

# Helper to sanitize strings for CSV export (prevents Excel newline corruption)
function Sanitize-String ($Val) {
    if ($null -eq $Val) { return "" }
    return ([string]$Val -replace '[\r\n\t]+', ' ').Trim()
}

# Evaluates security risk for access rule
function Get-AccessSecurityRisk ($Identity, $Rights, $AccessType) {
    $id = ([string]$Identity).ToUpperInvariant()
    $r = ([string]$Rights).ToUpperInvariant()
    $act = ([string]$AccessType).ToUpperInvariant()

    if ($act -eq "DENY") {
        return "[EXPLICIT DENY]"
    }

    if ($id -eq "EVERYONE" -or $id -eq "ANONYMOUS LOGON" -or $id -eq "GUEST" -or $id -like "*\GUEST") {
        if ($r -match "FULLCONTROL|MODIFY|WRITE") {
            return "[CRITICAL RISK]"
        }
        return "[WARN: EVERYONE]"
    }

    if ($id -match "AUTHENTICATED USERS|DOMAIN USERS") {
        if ($r -match "FULLCONTROL|MODIFY") {
            return "[WARN: BROAD WRITE]"
        }
    }

    return "[NORMAL]"
}

# Translate SID defensively to prevent crashes on deleted / orphaned accounts
function Resolve-AclIdentity ($IdentityRef) {
    if ($null -eq $IdentityRef) { return "Unknown Account" }
    try {
        return [string]$IdentityRef.Value
    } catch {
        return [string]$IdentityRef
    }
}

function Show-Header {
    Clear-Host
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "     WINDOWS SERVER SHARED FOLDER & NTFS PERMISSIONS AUDITOR" -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "  Server: $TargetComputer | Logged-in User: $CurrentLoggedOnUser" -ForegroundColor DarkCyan
    Write-Host "  Reports: $ReportsDir" -ForegroundColor DarkGray
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
}

Show-Header
Write-Host "Select Folder Audit Scope:" -ForegroundColor Yellow
Write-Host "  [1] Auto-Discover All SMB File Shares (Share + NTFS permissions) [Recommended]" -ForegroundColor White
Write-Host "  [2] Audit Specific Folder Path (e.g. D:\Shares or C:\Data)" -ForegroundColor White
Write-Host "  [3] Full Drive Root Audit (Top-level folders across all fixed drives)" -ForegroundColor White
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  [Q] Cancel & Exit" -ForegroundColor DarkRed
Write-Host ""

$Choice = (Read-Host "Select option [1, 2, 3, Q]").Trim().ToUpperInvariant()
if ($Choice -eq "Q") {
    Write-Host "Operation cancelled by user." -ForegroundColor Yellow
    exit 0
}

# Recursion Depth Selection
$MaxDepth = 2
if ($Choice -eq "1" -or $Choice -eq "2") {
    Write-Host ""
    Write-Host "Select subfolder recursion depth:" -ForegroundColor Yellow
    Write-Host "  [1] Share root folder only (Fastest)" -ForegroundColor DarkCyan
    Write-Host "  [2] Share root + 1 level of subfolders [Recommended]" -ForegroundColor DarkCyan
    Write-Host "  [3] Share root + 2 levels of subfolders" -ForegroundColor DarkCyan
    Write-Host "  [4] Deep recursion (up to 5 levels)" -ForegroundColor DarkCyan
    Write-Host "  [5] Unlimited recursion (May take long on multi-terabyte drives)" -ForegroundColor DarkCyan
    $DepthInput = Read-Host "Choose depth [1-5, Default: 2]"
    if ($DepthInput -match "^[1-5]$") {
        if ($DepthInput -eq "5") { $MaxDepth = 999 } else { $MaxDepth = [int]$DepthInput }
    }
}

$AuditRecords = New-Object System.Collections.ArrayList
$ScanTimestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
$FoldersToScan = @() # Array of hashtables: @{ Path = '...'; ShareName = '...' }

# ------------------------------------------------------------------------------
# STEP 1: DISCOVER TARGET FOLDERS & AUDIT SHARE PERMISSIONS (LAYER 1)
# ------------------------------------------------------------------------------
Show-Header
Write-Host "[1/3] Discovering Target Shares and Folder Hierarchy..." -ForegroundColor Yellow

if ($Choice -eq "1") {
    Write-Host "  -> Querying local SMB file shares via Win32_Share..." -ForegroundColor Cyan
    $Shares = Get-UniversalWmiData -Class "Win32_Share" -Filter "Type=0" # Type 0 = Disk Drive shares
    
    if (-not $Shares -or $Shares.Count -eq 0) {
        Write-Host "  [!] No standard SMB disk file shares discovered on this server." -ForegroundColor Yellow
        Write-Host "      Default administrative shares (C$, ADMIN$) are excluded." -ForegroundColor DarkGray
        Write-Host ""
        $FallbackPath = Read-Host "Enter a local directory path to audit instead (e.g. C:\Users or D:\Data)"
        if ($FallbackPath -and (Test-Path $FallbackPath)) {
            $FoldersToScan += @{ Path = (Resolve-Path $FallbackPath).Path; ShareName = "N/A (Local Folder)" }
        } else {
            Write-Host "No valid path provided. Exiting..." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "  [OK] Found $($Shares.Count) active SMB file share(s):" -ForegroundColor Green
        
        foreach ($sh in $Shares) {
            $sName = $sh.Name
            $sPath = $sh.Path
            
            # Skip admin shares unless explicit
            if ($sName -match '^[A-Za-z]\$$|^ADMIN\$$|^IPC\$$|^PRINT\$$') { continue }
            if (-not $sPath -or -not (Test-Path $sPath)) { continue }
            
            Write-Host "       * Share: \\$TargetComputer\$sName -> $sPath" -ForegroundColor DarkCyan
            $FoldersToScan += @{ Path = $sPath; ShareName = $sName }
            
            # Extract Share Permissions (SMB Layer)
            # Method A: Get-SmbShareAccess (modern Windows 8/2012+)
            $ShareAclSuccess = $false
            if (Get-Command Get-SmbShareAccess -ErrorAction SilentlyContinue) {
                try {
                    $smbAcls = Get-SmbShareAccess -Name $sName -ErrorAction SilentlyContinue
                    if ($smbAcls) {
                        $ShareAclSuccess = $true
                        foreach ($sa in $smbAcls) {
                            $risk = Get-AccessSecurityRisk $sa.AccountName $sa.AccessRight $sa.AccessControlType
                            [void]$AuditRecords.Add([PSCustomObject]@{
                                ComputerName       = $TargetComputer
                                LoggedOnUser       = $CurrentLoggedOnUser
                                ShareName          = $sName
                                FolderPath         = $sPath
                                PermissionLayer    = "Share Permission"
                                IdentityReference  = (Sanitize-String $sa.AccountName)
                                AccessControlType  = (Sanitize-String $sa.AccessControlType)
                                Permissions        = (Sanitize-String $sa.AccessRight)
                                IsInherited        = "False"
                                InheritanceFlags   = "None"
                                PropagationFlags   = "None"
                                SecurityRisk       = $risk
                                ScanTimestamp      = $ScanTimestamp
                            })
                        }
                    }
                } catch {}
            }
            
            # Method B: Fallback via WMI Win32_LogicalShareSecuritySetting (legacy Server 2008 R2 / Win 7)
            if (-not $ShareAclSuccess) {
                try {
                    $shareSec = Get-UniversalWmiData -Class "Win32_LogicalShareSecuritySetting" -Filter "Name='$sName'"
                    if ($shareSec) {
                        $secDesc = @($shareSec)[0].GetSecurityDescriptor()
                        if ($secDesc -and $secDesc.Descriptor -and $secDesc.Descriptor.DACL) {
                            foreach ($ace in $secDesc.Descriptor.DACL) {
                                $trustee = $ace.Trustee
                                $accName = if ($trustee.Domain) { "$($trustee.Domain)\$($trustee.Name)" } else { $trustee.Name }
                                if (-not $accName) { $accName = "SID:$($trustee.SIDString)" }
                                
                                $mask = $ace.AccessMask
                                $rightsStr = "Read"
                                if (($mask -band 2032127) -eq 2032127) { $rightsStr = "FullControl" }
                                elseif (($mask -band 1245631) -eq 1245631) { $rightsStr = "Change" }
                                
                                $aceType = if ($ace.AceType -eq 0) { "Allow" } else { "Deny" }
                                $risk = Get-AccessSecurityRisk $accName $rightsStr $aceType
                                
                                [void]$AuditRecords.Add([PSCustomObject]@{
                                    ComputerName       = $TargetComputer
                                    LoggedOnUser       = $CurrentLoggedOnUser
                                    ShareName          = $sName
                                    FolderPath         = $sPath
                                    PermissionLayer    = "Share Permission"
                                    IdentityReference  = (Sanitize-String $accName)
                                    AccessControlType  = $aceType
                                    Permissions        = $rightsStr
                                    IsInherited        = "False"
                                    InheritanceFlags   = "None"
                                    PropagationFlags   = "None"
                                    SecurityRisk       = $risk
                                    ScanTimestamp      = $ScanTimestamp
                                })
                            }
                        }
                    }
                } catch {}
            }
        }
    }
} elseif ($Choice -eq "2") {
    $CustomPath = (Read-Host "Enter full folder path to audit (e.g. D:\Shares or C:\Data)").Trim()
    if ($CustomPath -and (Test-Path -LiteralPath $CustomPath)) {
        $Resolved = (Resolve-Path -LiteralPath $CustomPath).Path
        $FoldersToScan += @{ Path = $Resolved; ShareName = "N/A (Custom Path)" }
        Write-Host "  [OK] Target folder validated: $Resolved" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] Folder path not found or invalid. Exiting..." -ForegroundColor Red
        exit 1
    }
} elseif ($Choice -eq "3") {
    Write-Host "  -> Querying fixed hard drive volumes..." -ForegroundColor Cyan
    $Drives = [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq "Fixed" -and $_.IsReady }
    foreach ($d in $Drives) {
        $RootPath = $d.RootDirectory.FullName
        Write-Host "       * Drive: $RootPath" -ForegroundColor DarkCyan
        $FoldersToScan += @{ Path = $RootPath; ShareName = "Drive Root ($($d.Name))" }
    }
}

# ------------------------------------------------------------------------------
# STEP 2: AUDIT NTFS FOLDER-LEVEL PERMISSIONS (LAYER 2)
# ------------------------------------------------------------------------------
Write-Host ""
Write-Host "[2/3] Extracting NTFS Access Control Lists (ACLs)..." -ForegroundColor Yellow

$TotalFoldersAudited = 0
$ProcessedPaths = New-Object System.Collections.Generic.HashSet[string]

function Audit-DirectoryAcl ($FolderPath, $ShareName, $CurrentDepth, $TargetMaxDepth) {
    if (-not (Test-Path -LiteralPath $FolderPath)) { return }
    $norm = $FolderPath.ToLowerInvariant().TrimEnd('\')
    if ($ProcessedPaths.Contains($norm)) { return }
    $ProcessedPaths.Add($norm) | Out-Null
    
    $script:TotalFoldersAudited++
    Write-Host "  -> Auditing: $FolderPath" -ForegroundColor DarkGray

    try {
        $acl = Get-Acl -LiteralPath $FolderPath -ErrorAction Stop
        if ($acl -and $acl.Access) {
            foreach ($rule in $acl.Access) {
                $idName = Resolve-AclIdentity $rule.IdentityReference
                $fsRights = [string]$rule.FileSystemRights
                $actType = [string]$rule.AccessControlType
                $isInherited = [string]$rule.IsInherited
                $inheritFlags = [string]$rule.InheritanceFlags
                $propFlags = [string]$rule.PropagationFlags
                $risk = Get-AccessSecurityRisk $idName $fsRights $actType

                [void]$AuditRecords.Add([PSCustomObject]@{
                    ComputerName       = $TargetComputer
                    LoggedOnUser       = $CurrentLoggedOnUser
                    ShareName          = $ShareName
                    FolderPath         = $FolderPath
                    PermissionLayer    = "NTFS Permission"
                    IdentityReference  = (Sanitize-String $idName)
                    AccessControlType  = (Sanitize-String $actType)
                    Permissions        = (Sanitize-String $fsRights)
                    IsInherited        = $isInherited
                    InheritanceFlags   = (Sanitize-String $inheritFlags)
                    PropagationFlags   = (Sanitize-String $propFlags)
                    SecurityRisk       = $risk
                    ScanTimestamp      = $ScanTimestamp
                })
            }
        }
    } catch {
        Write-Host "     [ACCESS DENIED / SKIP] Cannot read ACL: $FolderPath ($($_.Exception.Message))" -ForegroundColor DarkYellow
        [void]$AuditRecords.Add([PSCustomObject]@{
            ComputerName       = $TargetComputer
            LoggedOnUser       = $CurrentLoggedOnUser
            ShareName          = $ShareName
            FolderPath         = $FolderPath
            PermissionLayer    = "NTFS Permission"
            IdentityReference  = "SYSTEM / LOCKED"
            AccessControlType  = "Denied"
            Permissions        = "Read-Protected: $($_.Exception.Message)"
            IsInherited        = "Unknown"
            InheritanceFlags   = "None"
            PropagationFlags   = "None"
            SecurityRisk       = "[ACCESS DENIED]"
            ScanTimestamp      = $ScanTimestamp
        })
    }

    # Recurse subdirectories if within depth limit
    if ($CurrentDepth -lt $TargetMaxDepth) {
        try {
            $subdirs = Get-ChildItem -LiteralPath $FolderPath -Directory -Force -ErrorAction SilentlyContinue
            if ($subdirs) {
                foreach ($sd in $subdirs) {
                    Audit-DirectoryAcl $sd.FullName $ShareName ($CurrentDepth + 1) $TargetMaxDepth
                }
            }
        } catch {}
    }
}

foreach ($target in $FoldersToScan) {
    Audit-DirectoryAcl $target.Path $target.ShareName 1 $MaxDepth
}

# ------------------------------------------------------------------------------
# STEP 3: EXPORT TO CSV & DISPLAY CONSOLE DASHBOARD
# ------------------------------------------------------------------------------
Write-Host ""
Write-Host "[3/3] Exporting Permissions Matrix to CSV..." -ForegroundColor Yellow

$TimestampFile = Get-Date -Format "yyyyMMdd_HHmmss"
$TimestampedCsv = Join-Path $ReportsDir "folder_permissions_${TargetComputer}_${TimestampFile}.csv"
$MasterCsv = Join-Path $ReportsDir "folder_permissions.csv"

# Export data cleanly
if ($AuditRecords.Count -gt 0) {
    # 1. Export timestamped copy
    $AuditRecords | Export-Csv -Path $TimestampedCsv -NoTypeInformation -Force -Encoding UTF8
    # 2. Update/create standard copy
    $AuditRecords | Export-Csv -Path $MasterCsv -NoTypeInformation -Force -Encoding UTF8

    Write-Host "  [OK] Exported $($AuditRecords.Count) access rules to:" -ForegroundColor Green
    Write-Host "       $TimestampedCsv" -ForegroundColor Cyan
} else {
    Write-Host "  [WARN] No permission records captured." -ForegroundColor Yellow
}

# Metrics calculation
$CriticalRisks = @($AuditRecords | Where-Object { $_.SecurityRisk -eq "[CRITICAL RISK]" }).Count
$Warnings = @($AuditRecords | Where-Object { $_.SecurityRisk -like "*WARN*" }).Count
$UniqueIdentities = @($AuditRecords | Select-Object -ExpandProperty IdentityReference -Unique).Count

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "           FOLDER PERMISSIONS AUDIT COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "  Host Server          : $TargetComputer" -ForegroundColor White
Write-Host "  Logged-in Auditor    : $CurrentLoggedOnUser" -ForegroundColor White
Write-Host "  Folders Scanned      : $TotalFoldersAudited" -ForegroundColor White
Write-Host "  Total Access Rules   : $($AuditRecords.Count)" -ForegroundColor White
Write-Host "  Unique Users/Groups  : $UniqueIdentities" -ForegroundColor White
Write-Host "  Critical Risks       : $CriticalRisks (e.g. Everyone/Guest with FullControl/Modify)" -ForegroundColor (if ($CriticalRisks -gt 0) { "Red" } else { "Green" })
Write-Host "  Security Warnings    : $Warnings" -ForegroundColor (if ($Warnings -gt 0) { "Yellow" } else { "Green" })
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  CSV Report Location  : [folder_permissions.csv](file://$($TimestampedCsv.Replace('\','/')))" -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Press Enter to return..." -ForegroundColor DarkGray
[void](Read-Host)
