# Audits and manages Windows Defender folder and process exclusions
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

if (-not (Get-UserApproval "Audit and manage Windows Defender Antivirus exclusions (Folder & Process)?")) {
    Log-Msg "Defender exclusion management skipped by user." "WARN"
    return 0
}

Log-Msg "Auditing active Windows Defender exclusions..."

if (Get-Command Get-MpPreference -ErrorAction SilentlyContinue) {
    $Prefs = Get-MpPreference -ErrorAction SilentlyContinue
    
    Log-Msg "CURRENT FOLDER EXCLUSIONS:" "STAGE"
    if ($Prefs.ExclusionPath) {
        foreach ($Path in $Prefs.ExclusionPath) { Log-Msg "  - Folder: $Path" }
    } else {
        Log-Msg "  (No folder exclusions configured)"
    }
    
    Log-Msg "CURRENT PROCESS EXCLUSIONS:" "STAGE"
    if ($Prefs.ExclusionProcess) {
        foreach ($Proc in $Prefs.ExclusionProcess) { Log-Msg "  - Process: $Proc" }
    } else {
        Log-Msg "  (No process exclusions configured)"
    }
    
    # Add new Folder Exclusion
    if (Get-UserApproval "Add a new Folder Exclusion to Windows Defender?") {
        Write-Host ""
        $FolderPath = Read-Host "Enter absolute Folder Path (e.g. C:\MyLOBApp)"
        if (Test-Path $FolderPath) {
            try {
                Add-MpPreference -ExclusionPath $FolderPath -ErrorAction Stop
                Log-Msg "  [OK] Successfully added folder exclusion: '$FolderPath'." "SUCCESS"
            } catch {
                Log-Msg "  [ERROR] Failed to add folder exclusion: $($_.Exception.Message)" "ERROR"
            }
        } else {
            Log-Msg "Folder path '$FolderPath' does not exist." "WARN"
        }
    }

    # Add new Process Exclusion
    if (Get-UserApproval "Add a new Process Exclusion to Windows Defender?") {
        Write-Host ""
        $ProcName = Read-Host "Enter Process Name or Executable (e.g. myapp.exe)"
        if ($ProcName) {
            try {
                Add-MpPreference -ExclusionProcess $ProcName -ErrorAction Stop
                Log-Msg "  [OK] Successfully added process exclusion: '$ProcName'." "SUCCESS"
            } catch {
                Log-Msg "  [ERROR] Failed to add process exclusion: $($_.Exception.Message)" "ERROR"
            }
        }
    }
} else {
    Log-Msg "Get-MpPreference Cmdlet not available on this OS build." "WARN"
}

Log-Msg "Windows Defender exclusion management completed."
return 0
