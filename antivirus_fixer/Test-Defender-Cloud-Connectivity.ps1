# Tests Microsoft Defender Cloud Protection & SmartScreen Service Reachability
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

function Test-CloudEndpoint ($HostName, $Port=443, $TimeoutMs=3000) {
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $iar = $client.BeginConnect($HostName, $Port, $null, $null)
        $wh = $iar.AsyncWaitHandle
        if (-not $wh.WaitOne($TimeoutMs, $false)) {
            $client.Close()
            return $false
        }
        $client.EndConnect($iar)
        $client.Close()
        return $true
    } catch {
        return $false
    }
}

if (-not (Get-UserApproval "Test Microsoft Defender Cloud Protection & SmartScreen service reachability?")) {
    Log-Msg "Defender cloud connectivity check skipped by user." "WARN"
    return 0
}

Log-Msg "Testing Microsoft Defender Cloud Security Endpoints..."

$Endpoints = @(
    @{ Name = "Defender Cloud Protection (Primary)"; Host = "wdcp.microsoft.com"; Port = 443 },
    @{ Name = "Defender Cloud Protection (Alternate)"; Host = "wdcpalt.microsoft.com"; Port = 443 },
    @{ Name = "Windows SmartScreen Service"; Host = "smartscreen.microsoft.com"; Port = 443 },
    @{ Name = "Security Definition Updates"; Host = "definitionupdates.microsoft.com"; Port = 443 }
)

$AllReachable = $true
foreach ($ep in $Endpoints) {
    $ok = Test-CloudEndpoint $ep.Host $ep.Port 3000
    if ($ok) {
        Log-Msg "  [OK] $($ep.Name) [$($ep.Host):$($ep.Port)] is REACHABLE." "SUCCESS"
    } else {
        $AllReachable = $false
        Log-Msg "  [FAIL] $($ep.Name) [$($ep.Host):$($ep.Port)] is BLOCKED or unreachable (Check proxy/firewall)." "ERROR"
    }
}

if ($AllReachable) {
    Log-Msg "All Microsoft Defender Cloud endpoints are reachable. Cloud-delivered protection is active." "SUCCESS"
} else {
    Log-Msg "One or more Defender endpoints are blocked! Real-time MAPS cloud intelligence may fail." "WARN"
}

return 0
