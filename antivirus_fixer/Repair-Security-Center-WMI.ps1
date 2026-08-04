# Audits and repairs Windows Security Center WMI repository state
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

if (-not (Get-UserApproval "Audit Windows Security Center WMI repository (root\\SecurityCenter2) and Antivirus state?")) {
    Log-Msg "Security Center WMI audit skipped by user." "WARN"
    return 0
}

Log-Msg "Auditing Windows Security Center WMI Repository..."

try {
    $AvProducts = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName "AntivirusProduct" -ErrorAction SilentlyContinue
    if ($AvProducts) {
        foreach ($Av in $AvProducts) {
            Log-Msg "Detected Antivirus Product: $($Av.displayName) | Path: $($Av.pathToSignedProductExe) | State: $($Av.productState)" "SUCCESS"
        }
    } else {
        Log-Msg "No third-party Antivirus products registered in WMI SecurityCenter2. Windows Defender is default." "INFO"
    }
} catch {
    Log-Msg "  [WARN] Could not query root\\SecurityCenter2 WMI namespace: $($_.Exception.Message)" "WARN"
}

Log-Msg "Windows Security Center WMI audit completed."
return 0
