# Diagnostics: Repairs file system and registry ACL permissions for Microsoft Office
$ErrorActionPreference = "SilentlyContinue"

# Try to bypass Execution Policy for the current session/process
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
} catch {}

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
    Write-Host $Formatted -ForegroundColor (if ($Type -eq "ERROR") { "Red" } elseif ($Type -eq "WARN") { "Yellow" } else { "Gray" })
    if ($Global:LogFile) {
        $Formatted | Out-File -FilePath $Global:LogFile -Append -Encoding UTF8
    }
}

if (-not (Get-UserApproval "Repair file system and registry permissions for Microsoft Office?")) {
    Log-Msg "Permissions repair skipped by user." "WARN"
    return 0
}

Log-Msg "Starting permissions repair..."
$ReportErrors = @()

# 1. File system path permission repair using icacls
$FoldersToFix = @()

# Program Files directories
if (Test-Path "${env:ProgramFiles}\Microsoft Office") {
    $FoldersToFix += "${env:ProgramFiles}\Microsoft Office"
}
if (Test-Path "${env:ProgramFiles(x86)}\Microsoft Office") {
    $FoldersToFix += "${env:ProgramFiles(x86)}\Microsoft Office"
}
# Common Files
if (Test-Path "${env:CommonProgramFiles}\Microsoft Shared\Office15") {
    $FoldersToFix += "${env:CommonProgramFiles}\Microsoft Shared\Office15"
}
if (Test-Path "${env:CommonProgramFiles(x86)}\Microsoft Shared\Office15") {
    $FoldersToFix += "${env:CommonProgramFiles(x86)}\Microsoft Shared\Office15"
}
# ProgramData Office licensing
if (Test-Path "C:\ProgramData\Microsoft\OfficeSoftwareProtectionPlatform") {
    $FoldersToFix += "C:\ProgramData\Microsoft\OfficeSoftwareProtectionPlatform"
}
# User AppData folders
$LocalOffice = Join-Path $env:LOCALAPPDATA "Microsoft\Office"
$RoamingOffice = Join-Path $env:APPDATA "Microsoft\Office"
if (Test-Path $LocalOffice) { $FoldersToFix += $LocalOffice }
if (Test-Path $RoamingOffice) { $FoldersToFix += $RoamingOffice }

foreach ($Folder in $FoldersToFix) {
    if (Get-UserApproval "Reset permissions (grant Administrators/System Full Control, Users Read/Execute) on folder: '$Folder'?") {
        Log-Msg "Applying icacls on '$Folder'..."
        
        # System: Full Control (S-1-5-18)
        # Administrators: Full Control (S-1-5-32-544)
        # Users: Read/Execute (S-1-5-32-545)
        $CmdAdmin = "icacls `"$Folder`" /grant:r *S-1-5-32-544:(OI)(CI)F /grant:r *S-1-5-18:(OI)(CI)F /grant *S-1-5-32-545:(OI)(CI)RX /t /c /q"
        
        $Result = cmd.exe /c $CmdAdmin 2>&1
        if ($LASTEXITCODE -eq 0) {
            Log-Msg "  [OK] Successfully reset folder permissions on '$Folder'."
        } else {
            Log-Msg "  [ERROR] icacls failed on '$Folder'. Output: $Result" "ERROR"
            $ReportErrors += "FileSystem: $Folder (icacls exit code $LASTEXITCODE)"
        }
    }
}

# 2. Registry hive permission repair
$RegistryHives = @(
    "HKLM:\SOFTWARE\Microsoft\Office"
    "HKCU:\Software\Microsoft\Office"
)

foreach ($RegPath in $RegistryHives) {
    if (Get-UserApproval "Reset permissions (grant Administrators/System Full Control) on Registry path: '$RegPath'?") {
        Log-Msg "Resetting registry permissions on '$RegPath'..."
        try {
            $Key = Get-Item -Path $RegPath -ErrorAction Stop
            $Acl = $Key.GetAccessControl()
            
            $SystemSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18")
            $AdminSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
            
            $SystemRule = New-Object System.Security.AccessControl.RegistryAccessRule(
                $SystemSid,
                [System.Security.AccessControl.RegistryRights]::FullControl,
                [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit,
                [System.Security.AccessControl.PropagationFlags]::None,
                [System.Security.AccessControl.AccessControlType]::Allow
            )
            
            $AdminRule = New-Object System.Security.AccessControl.RegistryAccessRule(
                $AdminSid,
                [System.Security.AccessControl.RegistryRights]::FullControl,
                [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit,
                [System.Security.AccessControl.PropagationFlags]::None,
                [System.Security.AccessControl.AccessControlType]::Allow
            )
            
            $Acl.SetAccessRule($SystemRule)
            $Acl.SetAccessRule($AdminRule)
            
            $Key.SetAccessControl($Acl)
            Log-Msg "  [OK] Successfully set Registry Access Control Rules on '$RegPath'."
        } catch {
            Log-Msg "  [ERROR] Registry permissions failed on '$RegPath': $($_.Exception.Message)" "ERROR"
            $ReportErrors += "Registry: $RegPath ($($_.Exception.Message))"
        }
    }
}

$Global:PermissionErrors = $ReportErrors
Log-Msg "Permissions repair completed."
return 0
