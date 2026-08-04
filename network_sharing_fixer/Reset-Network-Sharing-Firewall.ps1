# Configures Windows Firewall and Network Profile settings for File & Printer Sharing
$ErrorActionPreference = "SilentlyContinue"

try {
    Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
} catch {}

# Helper function for user prompts
function Get-UserApproval ($Message) {
    Write-Host ""
    Write-Host ">>> $Message" -ForegroundColor Yellow
    $Response = Read-Host "Proceed? (Y/N)"
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

if (-not (Get-UserApproval "Enable File/Printer Sharing and Network Discovery in Windows Firewall?")) {
    Log-Msg "Firewall sharing configurations skipped by user." "WARN"
    return 0
}

Log-Msg "Configuring Windows Firewall rules for network sharing..."

# 1. Enable Firewall Rule Groups
if (Get-UserApproval "Enable Firewall rules for 'File and Printer Sharing'?") {
    try {
        Enable-NetFirewallRule -DisplayGroup "File and Printer Sharing" -ErrorAction Stop
        Log-Msg "  [OK] Successfully enabled Firewall group: File and Printer Sharing."
    } catch {
        Log-Msg "  [WARN] Could not enable File and Printer Sharing firewall rule: $($_.Exception.Message)" "WARN"
    }
}

if (Get-UserApproval "Enable Firewall rules for 'Network Discovery'?") {
    try {
        Enable-NetFirewallRule -DisplayGroup "Network Discovery" -ErrorAction Stop
        Log-Msg "  [OK] Successfully enabled Firewall group: Network Discovery."
    } catch {
        Log-Msg "  [WARN] Could not enable Network Discovery firewall rule: $($_.Exception.Message)" "WARN"
    }
}

# 2. Inspect and Option to set Network Category to Private
try {
    $Profiles = Get-NetConnectionProfile -ErrorAction SilentlyContinue
    foreach ($Profile in $Profiles) {
        Log-Msg "Network Adapter '$($Profile.InterfaceAlias)' | Current Category: $($Profile.NetworkCategory)"
        if ($Profile.NetworkCategory -eq "Public") {
            if (Get-UserApproval "Network connection '$($Profile.InterfaceAlias)' is set to Public (Blocks Sharing). Change network category to Private?") {
                Set-NetConnectionProfile -InterfaceAlias $Profile.InterfaceAlias -NetworkCategory Private -ErrorAction Stop
                Log-Msg "  [OK] Changed network category of '$($Profile.InterfaceAlias)' to Private."
            }
        }
    }
} catch {
    Log-Msg "  [WARN] Could not query network profiles: $($_.Exception.Message)" "WARN"
}

Log-Msg "Firewall network sharing configurations completed."
return 0
