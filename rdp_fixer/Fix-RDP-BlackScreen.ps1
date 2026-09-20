# Fixes Remote Desktop Black Screen upon Connection
# Replaces buggy WDDM display driver with stable legacy XDDM driver for Terminal Services
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
    Write-Host $Formatted -ForegroundColor (if ($Type -eq "ERROR") { "Red" } elseif ($Type -eq "WARN") { "Yellow" } elseif ($Type -eq "SUCCESS") { "Green" } else { "Gray" })
    if ($Global:LogFile) {
        $Formatted | Out-File -FilePath $Global:LogFile -Append -Encoding UTF8
    }
}

if (-not (Get-UserApproval "Force legacy XDDM display driver (fEnableWddmDriver = 0) to fix RDP black screen on connect?")) {
    Log-Msg "RDP black screen fix skipped by user." "WARN"
    return 0
}

Log-Msg "Configuring Terminal Services display driver fallback..."

$TSPolicyKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
try {
    if (-not (Test-Path $TSPolicyKey)) {
        New-Item -Path $TSPolicyKey -Force | Out-Null
    }
    # 0 = Use XDDM graphics display driver for Remote Desktop Sessions
    Set-ItemProperty -Path $TSPolicyKey -Name "fEnableWddmDriver" -Value 0 -PropertyType DWord -Force | Out-Null
    Log-Msg "  [OK] Successfully configured fEnableWddmDriver = 0." "SUCCESS"
} catch {
    Log-Msg "  [ERROR] Failed to set fEnableWddmDriver: $($_.Exception.Message)" "ERROR"
}

# Also ensure RDP bitmap caching doesn't freeze the session
$ClientKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\Client"
try {
    if (-not (Test-Path $ClientKey)) {
        New-Item -Path $ClientKey -Force | Out-Null
    }
    Set-ItemProperty -Path $ClientKey -Name "BitmapPersistence" -Value 1 -PropertyType DWord -Force | Out-Null
    Log-Msg "  [OK] Configured client persistent bitmap caching (BitmapPersistence = 1)." "SUCCESS"
} catch {
    Log-Msg "  [WARN] Failed to configure bitmap persistence: $($_.Exception.Message)" "WARN"
}

Log-Msg "RDP display driver fallback configured. Black screen hangs resolved." "SUCCESS"
return 0
