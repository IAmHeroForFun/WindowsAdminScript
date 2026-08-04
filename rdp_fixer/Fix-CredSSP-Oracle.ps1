# Configures CredSSP Encryption Oracle Remediation settings for Remote Desktop
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

if (-not (Get-UserApproval "Mitigate CredSSP Encryption Oracle Remediation errors (Fixes RDP error 0x800706BA / 0x80090308)?")) {
    Log-Msg "CredSSP repair skipped by user." "WARN"
    return 0
}

Log-Msg "Configuring CredSSP Encryption Oracle Policy..."

$CredSspKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters"

try {
    if (-not (Test-Path $CredSspKey)) {
        New-Item -Path $CredSspKey -Force | Out-Null
    }
    
    # Value 2 = Vulnerable / Mitigated (Allows RDP connection to unpatched/legacy servers)
    Set-ItemProperty -Path $CredSspKey -Name "AllowEncryptionOracle" -Value 2 -PropertyType DWord -Force | Out-Null
    Log-Msg "  [OK] Successfully set AllowEncryptionOracle = 2 (Vulnerable/Mitigated mode)." "SUCCESS"
} catch {
    Log-Msg "  [ERROR] Failed to configure CredSSP registry key: $($_.Exception.Message)" "ERROR"
}

Log-Msg "CredSSP policy configuration completed."
return 0
