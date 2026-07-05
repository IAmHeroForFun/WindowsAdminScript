# ==============================================================================
# SCRIPT: Launcher.ps1
# PURPOSE: Entry point alias for deploy_software.ps1.
# ==============================================================================

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$mainLauncher = Join-Path $scriptDir "deploy_software.ps1"
if (Test-Path $mainLauncher) {
    & $mainLauncher
} else {
    Write-Host "Error: Cannot locate deploy_software.ps1" -ForegroundColor Red
}
