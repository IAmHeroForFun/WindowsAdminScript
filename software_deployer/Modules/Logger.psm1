# ==============================================================================
# MODULE: Logger.psm1
# PURPOSE: Provides centralized file logging and real-time GUI log streaming
# ==============================================================================

# Script-level variables to hold log file path and GUI callback
$script:LogFilePath = $null
$script:GuiLogCallback = $null

<#
.SYNOPSIS
    Initializes the logging system, creates the log directory, and starts a session log.
.PARAMETER LogDir
    The absolute path to the directory where log files should be stored.
.PARAMETER GuiCallback
    An optional ScriptBlock that accepts a formatted log string to update the WPF GUI in real-time.
#>
function Initialize-Logger {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogDir,
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$GuiCallback = $null
    )

    if (-not (Test-Path -Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }

    $timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
    $script:LogFilePath = Join-Path -Path $LogDir -ChildPath "DeployerSession_$timestamp.log"
    $script:GuiLogCallback = $GuiCallback

    Write-Log -Message "==========================================================================" -Level "INFO"
    Write-Log -Message "  OmviHub Cloud Software Deployer (WPF & Winget Engine) Initialized" -Level "INFO"
    Write-Log -Message "  Session Log: $script:LogFilePath" -Level "INFO"
    Write-Log -Message "==========================================================================" -Level "INFO"
}

<#
.SYNOPSIS
    Writes a log entry to the log file and streams it to the GUI log panel.
.PARAMETER Message
    The log text to record.
.PARAMETER Level
    The severity level: INFO, WARN, ERROR, SUCCESS, START, DONE, SKIP.
#>
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "START", "DONE", "SKIP")]
        [string]$Level = "INFO"
    )

    $timeStr = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $formattedLine = "[$timeStr] [$Level] $Message"

    # 1. Write to file if initialized
    if ($script:LogFilePath -and (Test-Path -Path (Split-Path $script:LogFilePath -Parent))) {
        try {
            Add-Content -Path $script:LogFilePath -Value $formattedLine -Encoding UTF8 -ErrorAction SilentlyContinue
        } catch {
            # Fallback to console if file write fails
            Write-Host "Log write error: $_" -ForegroundColor Red
        }
    }

    # 2. Output to console
    switch ($Level) {
        "ERROR"   { Write-Host $formattedLine -ForegroundColor Red }
        "WARN"    { Write-Host $formattedLine -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $formattedLine -ForegroundColor Green }
        "DONE"    { Write-Host $formattedLine -ForegroundColor Cyan }
        "SKIP"    { Write-Host $formattedLine -ForegroundColor DarkGray }
        default   { Write-Host $formattedLine -ForegroundColor White }
    }

    # 3. Stream to GUI if callback is registered
    if ($script:GuiLogCallback) {
        try {
            & $script:GuiLogCallback $formattedLine
        } catch {
            # Ignore GUI callback errors during shutdown or thread contention
        }
    }
}

Export-ModuleMember -Function Initialize-Logger, Write-Log
