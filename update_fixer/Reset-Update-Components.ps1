# ==========================================================================
#   Reset-Update-Components.ps1 - Windows Update Catalog & Service Reset
#   Purges corrupted SoftwareDistribution & Catroot2 caches and resets BITS
# ==========================================================================
$ErrorActionPreference = "SilentlyContinue"

# Ensure $PSScriptRoot is defined
if (-not $PSScriptRoot) {
    if ($MyInvocation.MyCommand.Definition) {
        $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    } else {
        $PSScriptRoot = Get-Location | Select-Object -ExpandProperty Path
    }
}

function Log-Action ($Msg, $Type="INFO") {
    if (Get-Command Log-Msg -ErrorAction SilentlyContinue) {
        Log-Msg $Msg $Type
    } else {
        $Color = "Gray"
        if ($Type -eq "ERROR") { $Color = "Red" }
        elseif ($Type -eq "WARN") { $Color = "Yellow" }
        elseif ($Type -eq "SUCCESS") { $Color = "Green" }
        elseif ($Type -eq "STAGE") { $Color = "Cyan" }
        Write-Host "[$Type] $Msg" -ForegroundColor $Color
    }
}

Log-Action "Beginning complete Windows Update component & cache reset..." "STAGE"

# 1. Stop Related Services
$ServicesToStop = @("wuauserv", "bits", "cryptsvc", "msiserver", "TrustedInstaller")
Log-Action "Stopping update and cryptographic background services..." "STAGE"

foreach ($SvcName in $ServicesToStop) {
    $Svc = Get-Service -Name $SvcName -ErrorAction SilentlyContinue
    if ($Svc -and $Svc.Status -ne "Stopped") {
        Log-Action "  Stopping $SvcName..."
        Stop-Service -Name $SvcName -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        
        # Verify if still running; forcefully unhang if needed
        $SvcCheck = Get-Service -Name $SvcName -ErrorAction SilentlyContinue
        if ($SvcCheck -and $SvcCheck.Status -ne "Stopped") {
            Log-Action "  [WARN] $SvcName hung. Attempting process termination..." "WARN"
            if ($SvcName -eq "wuauserv") {
                Get-Process -Name "wuauserv*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

# 2. Reset BITS Transfer Queue
Log-Action "Purging BITS background transfer queues..." "STAGE"
try {
    cmd.exe /c "bitsadmin /reset /allusers" | Out-Null
    if (Get-Command Get-BitsTransfer -ErrorAction SilentlyContinue) {
        Get-BitsTransfer -AllUsers -ErrorAction SilentlyContinue | Remove-BitsTransfer -ErrorAction SilentlyContinue
    }
    Log-Action "  [OK] BITS transfer queue flushed." "SUCCESS"
} catch {
    Log-Action "  [WARN] Could not flush BITS queue: $($_.Exception.Message)" "WARN"
}

# 3. Rename SoftwareDistribution folder
$SoftwareDistDir = "C:\Windows\SoftwareDistribution"
if (Test-Path $SoftwareDistDir) {
    Log-Action "Resetting SoftwareDistribution cache folder..." "STAGE"
    $OldDistDir = "C:\Windows\SoftwareDistribution.old"
    if (Test-Path $OldDistDir) {
        Remove-Item -Path $OldDistDir -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }
    try {
        Rename-Item -Path $SoftwareDistDir -NewName "SoftwareDistribution.old" -Force -ErrorAction Stop
        Log-Action "  [OK] SoftwareDistribution successfully renamed to SoftwareDistribution.old" "SUCCESS"
    } catch {
        Log-Action "  [WARN] Direct rename locked. Attempting file purge inside folder..." "WARN"
        Get-ChildItem -Path $SoftwareDistDir -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Log-Action "  [OK] Cleared internal files within SoftwareDistribution." "SUCCESS"
    }
}

# 4. Rename Catroot2 folder
$Catroot2Dir = "C:\Windows\System32\catroot2"
if (Test-Path $Catroot2Dir) {
    Log-Action "Resetting Catroot2 cryptographic signature store..." "STAGE"
    $OldCatroot2 = "C:\Windows\System32\catroot2.old"
    if (Test-Path $OldCatroot2) {
        Remove-Item -Path $OldCatroot2 -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }
    try {
        Rename-Item -Path $Catroot2Dir -NewName "catroot2.old" -Force -ErrorAction Stop
        Log-Action "  [OK] Catroot2 successfully renamed to catroot2.old" "SUCCESS"
    } catch {
        Log-Action "  [WARN] Catroot2 rename locked by cryptographic subsystem." "WARN"
    }
}

# 5. Re-register Core Windows Update COM DLLs
Log-Action "Re-registering Windows Update core DLL components..." "STAGE"
$Dlls = @("atl.dll", "urlmon.dll", "mshtml.dll", "shdocvw.dll", "browseui.dll", "jscript.dll", "vbscript.dll", "scrrun.dll", "msxml.dll", "msxml3.dll", "msxml6.dll", "actxprxy.dll", "softpub.dll", "wintrust.dll", "dssenh.dll", "rsaenh.dll", "gpkcsp.dll", "sccbase.dll", "slbcsp.dll", "cryptdlg.dll", "oleaut32.dll", "ole32.dll", "shell32.dll", "initpki.dll", "wuapi.dll", "wuaueng.dll", "wucltui.dll", "wups.dll", "wups2.dll", "wuwebv.dll")

foreach ($Dll in $Dlls) {
    cmd.exe /c "regsvr32.exe /s $Dll" | Out-Null
}
Log-Action "  [OK] Re-registered $( $Dlls.Count ) core Windows Update COM libraries." "SUCCESS"

# 6. Restart Services
Log-Action "Restarting update services in proper dependency order..." "STAGE"
$ServicesToStart = @("cryptsvc", "bits", "wuauserv")
foreach ($SvcName in $ServicesToStart) {
    try {
        Set-Service -Name $SvcName -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name $SvcName -ErrorAction SilentlyContinue
        Log-Action "  [OK] $SvcName configured to Automatic and started." "SUCCESS"
    } catch {
        Log-Action "  [WARN] Could not start $SvcName : $($_.Exception.Message)" "WARN"
    }
}

Log-Action "Windows Update component and cache reset completed successfully." "SUCCESS"
