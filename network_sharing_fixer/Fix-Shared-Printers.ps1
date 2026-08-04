# Repairs USB Shared Printers, Point & Print restrictions, and RPC 0x0000011b errors
$ErrorActionPreference = "SilentlyContinue"

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

if (-not (Get-UserApproval "Repair USB Shared Printers & Point-and-Print connection restrictions (0x0000011b / 0x00000709)?")) {
    Log-Msg "Shared Printer repairs skipped by user." "WARN"
    return 0
}

Log-Msg "Starting USB Shared Printer repairs..."

# 1. Fix 0x0000011b Print Spooler RPC Privacy Constraint
$PrintControlKey = "HKLM:\System\CurrentControlSet\Control\Print"
if (Test-Path $PrintControlKey) {
    if (Get-UserApproval "Disable Print Spooler RPC Authentication Privacy (RpcAuthnLevelPrivacyEnabled = 0) to fix error 0x0000011b?") {
        try {
            Set-ItemProperty -Path $PrintControlKey -Name "RpcAuthnLevelPrivacyEnabled" -Value 0 -PropertyType DWord -Force | Out-Null
            Log-Msg "  [OK] Successfully set RpcAuthnLevelPrivacyEnabled = 0."
        } catch {
            Log-Msg "  [ERROR] Failed to set RpcAuthnLevelPrivacyEnabled: $($_.Exception.Message)" "ERROR"
        }
    }
}

# 2. Fix Point and Print Restrictions (Bypasses Non-Admin Driver Blocking)
$PointAndPrintKey = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
if (Get-UserApproval "Allow Non-Admin Users to install USB Shared Printer drivers (Bypass Point & Print Restrictions)?") {
    try {
        if (-not (Test-Path $PointAndPrintKey)) { New-Item -Path $PointAndPrintKey -Force | Out-Null }
        Set-ItemProperty -Path $PointAndPrintKey -Name "Restricted" -Value 0 -PropertyType DWord -Force | Out-Null
        Set-ItemProperty -Path $PointAndPrintKey -Name "TrustedServers" -Value 0 -PropertyType DWord -Force | Out-Null
        Set-ItemProperty -Path $PointAndPrintKey -Name "NoWarningNoElevationOnInstall" -Value 1 -PropertyType DWord -Force | Out-Null
        Set-ItemProperty -Path $PointAndPrintKey -Name "UpdatePromptSettings" -Value 1 -PropertyType DWord -Force | Out-Null
        Log-Msg "  [OK] Successfully configured Point & Print policy bypass keys."
    } catch {
        Log-Msg "  [ERROR] Failed to set Point & Print keys: $($_.Exception.Message)" "ERROR"
    }
}

# 3. Configure RPC Connection Protocol Types (Named Pipes & TCP)
$RpcPrinterKey = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC"
if (Get-UserApproval "Enable RPC over Named Pipes and TCP for network printer connections?") {
    try {
        if (-not (Test-Path $RpcPrinterKey)) { New-Item -Path $RpcPrinterKey -Force | Out-Null }
        Set-ItemProperty -Path $RpcPrinterKey -Name "RpcOverNamedPipes" -Value 1 -PropertyType DWord -Force | Out-Null
        Set-ItemProperty -Path $RpcPrinterKey -Name "RpcOverTcp" -Value 1 -PropertyType DWord -Force | Out-Null
        Log-Msg "  [OK] Successfully configured RPC over Named Pipes & TCP."
    } catch {
        Log-Msg "  [ERROR] Failed to set RPC protocol keys: $($_.Exception.Message)" "ERROR"
    }
}

# 4. Configure CopyFiles Policy Fix (Error 0x0000007c)
$PrintersPolicyKey = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers"
if (Get-UserApproval "Enable Legacy CopyFiles Spooler Policy (Fixes Error 0x0000007c)?") {
    try {
        if (-not (Test-Path $PrintersPolicyKey)) { New-Item -Path $PrintersPolicyKey -Force | Out-Null }
        Set-ItemProperty -Path $PrintersPolicyKey -Name "CopyFilesPolicy" -Value 1 -PropertyType DWord -Force | Out-Null
        Log-Msg "  [OK] Successfully configured CopyFilesPolicy = 1."
    } catch {
        Log-Msg "  [ERROR] Failed to set CopyFilesPolicy: $($_.Exception.Message)" "ERROR"
    }
}

# 5. Restart Print Spooler Service to apply changes
if (Get-UserApproval "Restart the Print Spooler service to apply printer registry changes?") {
    try {
        Restart-Service -Name "spooler" -Force -ErrorAction Stop
        Log-Msg "  [OK] Print Spooler service restarted successfully."
    } catch {
        Log-Msg "  [ERROR] Failed to restart Print Spooler: $($_.Exception.Message)" "ERROR"
    }
}

Log-Msg "USB Shared Printer repairs completed."
return 0
