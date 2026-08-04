# Inspects and configures custom Remote Desktop listening port (Default 3389)
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

if (-not (Get-UserApproval "Inspect or modify default Remote Desktop (RDP) port?")) {
    Log-Msg "RDP port configuration skipped by user." "WARN"
    return 0
}

Log-Msg "Inspecting Remote Desktop listening port..."

$RdpPortKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
$CurrentPort = 3389

if (Test-Path $RdpPortKey) {
    $PortProp = Get-ItemProperty -Path $RdpPortKey -Name "PortNumber" -ErrorAction SilentlyContinue
    if ($PortProp) { $CurrentPort = $PortProp.PortNumber }
}

Log-Msg "Current RDP Listening Port: $CurrentPort" "SUCCESS"

if (Get-UserApproval "Would you like to change the RDP listening port from $CurrentPort to a custom port?") {
    Write-Host ""
    $NewPortInput = Read-Host "Enter new RDP Port Number (1024-65535, e.g. 3390)"
    $NewPort = 0
    if ([int]::TryParse($NewPortInput, [ref]$NewPort) -and $NewPort -ge 1024 -and $NewPort -le 65535) {
        try {
            Set-ItemProperty -Path $RdpPortKey -Name "PortNumber" -Value $NewPort -PropertyType DWord -Force | Out-Null
            Log-Msg "  [OK] Successfully changed RDP registry PortNumber to $NewPort." "SUCCESS"
            
            # Create firewall rule for new RDP port
            $RuleName = "Remote Desktop Custom Port ($NewPort)"
            New-NetFirewallRule -DisplayName $RuleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $NewPort -Profile Any -ErrorAction SilentlyContinue | Out-Null
            Log-Msg "  [OK] Added Inbound Firewall Rule for TCP Port $NewPort." "SUCCESS"
            
            Restart-Service -Name "TermService" -Force -ErrorAction SilentlyContinue
            Log-Msg "  [OK] TermService restarted. Connect using: COMPUTERNAME:$NewPort" "SUCCESS"
        } catch {
            Log-Msg "  [ERROR] Failed to set custom RDP port: $($_.Exception.Message)" "ERROR"
        }
    } else {
        Log-Msg "Invalid port number entered. RDP port remains: $CurrentPort" "WARN"
    }
}

Log-Msg "RDP port inspection completed."
return 0
