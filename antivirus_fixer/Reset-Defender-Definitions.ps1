# Flushes corrupt Windows Defender engine signatures and forces definition update
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

if (-not (Get-UserApproval "Flush corrupt Windows Defender signature cache and force definition update?")) {
    Log-Msg "Defender definition reset skipped by user." "WARN"
    return 0
}

Log-Msg "Starting Windows Defender signature definition reset..."

$MpCmdRunPath = "${env:ProgramFiles}\Windows Defender\MpCmdRun.exe"

if (Test-Path $MpCmdRunPath) {
    # 1. Flush signatures
    if (Get-UserApproval "Remove all current Windows Defender definitions (MpCmdRun.exe -RemoveDefinitions -All)?") {
        try {
            $Result = & $MpCmdRunPath -RemoveDefinitions -All 2>&1
            Log-Msg "  [OK] Successfully removed Windows Defender definitions." "SUCCESS"
        } catch {
            Log-Msg "  [ERROR] Failed to remove definitions: $($_.Exception.Message)" "ERROR"
        }
    }
    
    # 2. Update signatures
    if (Get-UserApproval "Force download of fresh Windows Defender definitions from Microsoft Update?") {
        try {
            if (Get-Command Update-MpSignature -ErrorAction SilentlyContinue) {
                Update-MpSignature -UpdateSource MicrosoftUpdateServer -ErrorAction Stop
                Log-Msg "  [OK] Successfully updated Windows Defender signatures via PowerShell." "SUCCESS"
            } else {
                $Result = & $MpCmdRunPath -SignatureUpdate 2>&1
                Log-Msg "  [OK] Successfully updated signatures via MpCmdRun." "SUCCESS"
            }
        } catch {
            Log-Msg "  [ERROR] Failed to update signatures: $($_.Exception.Message)" "ERROR"
        }
    }
} else {
    Log-Msg "MpCmdRun.exe not found at '$MpCmdRunPath'. Windows Defender might not be installed." "WARN"
}

Log-Msg "Windows Defender signature reset completed."
return 0
