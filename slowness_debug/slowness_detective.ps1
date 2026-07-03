# Sherlock Slow: Advanced PC Slowness Detective & Granular Turbo Fixer
# Compatible with Windows 7 (PowerShell 2.0) through Windows 11 (PowerShell 5.1 & 7+)
# Deep-dive performance profiling with interactive Y/N prompts for each individual tune-up action!

$ErrorActionPreference = "SilentlyContinue"

# 0. Ensure $PSScriptRoot is defined for PowerShell 2.0 compatibility
if (-not $PSScriptRoot) {
    if ($MyInvocation.MyCommand.Definition) {
        $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    } else {
        $PSScriptRoot = Get-Location | Select-Object -ExpandProperty Path
    }
}

# Ensure reports directory exists
$ReportsDir = Join-Path -Path $PSScriptRoot -ChildPath "reports"
if (-not (Test-Path $ReportsDir)) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null }

# Helper function to query WMI/CIM across all PowerShell versions
function Get-WmiHelper($Class, $Namespace = "root\cimv2", $Filter = $null) {
    $Params = @{ Namespace = $Namespace; ErrorAction = "SilentlyContinue" }
    if (Get-Command Get-WmiObject -ErrorAction SilentlyContinue) {
        $Params.Add("Class", $Class)
        if ($Filter) { $Params.Add("Filter", $Filter) }
        Get-WmiObject @Params
    } elseif (Get-Command Get-CimInstance -ErrorAction SilentlyContinue) {
        $Params.Add("ClassName", $Class)
        if ($Filter) { $Params.Add("Filter", $Filter) }
        Get-CimInstance @Params
    }
}

Clear-Host
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "     SHERLOCK SLOW: ADVANCED PC SLOWNESS DETECTIVE & TURBO FIXER" -ForegroundColor Magenta
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "Running comprehensive multi-layer system diagnostic profile..." -ForegroundColor Cyan
Write-Host ""

$Score = 100
$IssuesFound = New-Object System.Collections.ArrayList
$ReportLines = New-Object System.Collections.ArrayList

[void]$ReportLines.Add("==========================================================================")
[void]$ReportLines.Add("SHERLOCK SLOW ADVANCED DIAGNOSTIC CASE FILE")
[void]$ReportLines.Add("Computer: $env:COMPUTERNAME | Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$ReportLines.Add("==========================================================================")
[void]$ReportLines.Add("")

# ---------------------------------------------------------
# PHASE 1: DEEP DIAGNOSTIC AUDIT
# ---------------------------------------------------------

# 1. CPU & THERMAL BOTTLENECK AUDIT
Write-Host "[Check 1/7] Deep Processor & Resource Hog Audit..." -ForegroundColor Yellow
$CPUProc = Get-WmiHelper -Class "Win32_Processor"
$CPUName = if ($CPUProc) { (@($CPUProc)[0].Name) -replace '\s+', ' ' } else { "Unknown CPU" }
$MaxClock = if ($CPUProc) { @($CPUProc)[0].MaxClockSpeed } else { "N/A" }
$Cores = if ($CPUProc) { @($CPUProc)[0].NumberOfCores } else { "N/A" }

$CpuSamples = @()
for ($i = 0; $i -lt 3; $i++) {
    $Load = @(Get-WmiHelper -Class "Win32_Processor")[0].LoadPercentage
    if ($null -ne $Load) { $CpuSamples += $Load }
    Start-Sleep -Milliseconds 500
}
$AvgCpu = if ($CpuSamples.Count -gt 0) { [Math]::Round(($CpuSamples | Measure-Object -Average).Average) } else { 15 }

Write-Host "   -> CPU Specs: $CPUName ($Cores Cores | ${MaxClock} MHz)" -ForegroundColor DarkCyan
[void]$ReportLines.Add("CPU Model: $CPUName ($Cores Cores)")

if ($AvgCpu -lt 50) {
    $Msg = "[OK] CPU PULSE: Healthy ($AvgCpu% total utilization). No CPU bottlenecks detected."
    Write-Host "   $Msg" -ForegroundColor Green
} elseif ($AvgCpu -lt 80) {
    $Score -= 15
    $Msg = "[WARN] CPU PULSE: Elevated ($AvgCpu% total utilization). Processor is under heavy workload."
    Write-Host "   $Msg" -ForegroundColor Yellow
    [void]$IssuesFound.Add("Elevated CPU utilization ($AvgCpu%)")
} else {
    $Score -= 35
    $Msg = "[CRITICAL] CPU PULSE: SEVERE OVERLOAD ($AvgCpu% total utilization)! System responsiveness is choked."
    Write-Host "   $Msg" -ForegroundColor Red
    [void]$IssuesFound.Add("CRITICAL CPU OVERLOAD ($AvgCpu%)")
}
[void]$ReportLines.Add($Msg)

# Top 5 CPU Processes
$TopCpu = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
Write-Host "   -> Top 5 Active CPU Consumers:" -ForegroundColor DarkGray
[void]$ReportLines.Add("Top 5 CPU Processes:")
foreach ($P in $TopCpu) {
    $PLine = "      * $($P.ProcessName.PadRight(25)) | CPU Time: $([Math]::Round($P.CPU, 1))s | RAM: $([Math]::Round($P.WorkingSet/1MB)) MB"
    Write-Host $PLine -ForegroundColor DarkGray
    [void]$ReportLines.Add($PLine)
}
Write-Host ""

# 2. RAM & VIRTUAL MEMORY (PAGEFILE) AUDIT
Write-Host "[Check 2/7] Memory & Virtual Pagefile Capacity Audit..." -ForegroundColor Yellow
$CS = @(Get-WmiHelper -Class "Win32_ComputerSystem")[0]
$OS = @(Get-WmiHelper -Class "Win32_OperatingSystem")[0]

$TotalRamGB = if ($CS) { [Math]::Round($CS.TotalPhysicalMemory / 1GB, 2) } else { 8 }
$FreeRamGB = if ($OS) { [Math]::Round($OS.FreePhysicalMemory / 1024 / 1024, 2) } else { 2 }
$UsedRamGB = [Math]::Round($TotalRamGB - $FreeRamGB, 2)
$RamPct = [Math]::Round(($UsedRamGB / $TotalRamGB) * 100)

Write-Host "   -> Physical RAM: ${UsedRamGB} GB used out of ${TotalRamGB} GB (${RamPct}% capacity)" -ForegroundColor DarkCyan
if ($RamPct -lt 70) {
    $Msg = "[OK] MEMORY: Sufficient headroom available (${FreeRamGB} GB free)."
    Write-Host "   $Msg" -ForegroundColor Green
} elseif ($RamPct -lt 88) {
    $Score -= 20
    $Msg = "[WARN] MEMORY: High memory consumption (${RamPct}% capacity). Multitasking speed may slow down."
    Write-Host "   $Msg" -ForegroundColor Yellow
    [void]$IssuesFound.Add("High physical memory usage (${RamPct}%)")
} else {
    $Score -= 40
    $Msg = "[CRITICAL] MEMORY EXHAUSTED (${RamPct}% capacity)! Windows is aggressively paging memory to disk causing severe lag."
    Write-Host "   $Msg" -ForegroundColor Red
    [void]$IssuesFound.Add("CRITICAL MEMORY EXHAUSTION (${RamPct}%)")
}
[void]$ReportLines.Add($Msg)

# Top 5 RAM Processes
$TopRam = Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 5
Write-Host "   -> Top 5 Memory Guzzlers:" -ForegroundColor DarkGray
[void]$ReportLines.Add("Top 5 RAM Consumers:")
foreach ($P in $TopRam) {
    $RLine = "      * $($P.ProcessName.PadRight(25)) | RAM WorkingSet: $([Math]::Round($P.WorkingSet/1MB)) MB"
    Write-Host $RLine -ForegroundColor DarkGray
    [void]$ReportLines.Add($RLine)
}
Write-Host ""

# 3. DRIVE ARCHITECTURE, SPACE & TEMP CLUTTER AUDIT
Write-Host "[Check 3/7] Hard Drive Engine & Digital Waste Audit..." -ForegroundColor Yellow
$Disk = @(Get-WmiHelper -Class "Win32_LogicalDisk" -Filter "DeviceID='C:'")[0]
$DiskSizeGB = [Math]::Round($Disk.Size / 1GB, 1)
$DiskFreeGB = [Math]::Round($Disk.FreeSpace / 1GB, 1)
$DiskFreePct = [Math]::Round(($DiskFreeGB / $DiskSizeGB) * 100)

$DriveTypeStr = "Unknown Storage Type"
try {
    $MSFTDisk = @(Get-WmiHelper -Namespace "root\Microsoft\Windows\Storage" -Class "MSFT_PhysicalDisk")[0]
    if ($MSFTDisk) {
        $DriveTypeStr = switch ($MSFTDisk.MediaType) { 3 {"HDD (Mechanical Spinning Drive)"} 4 {"SSD (Solid State High-Speed Drive)"} default {"Storage Drive"} }
    }
} catch { }

Write-Host "   -> Storage Type: $DriveTypeStr | Drive C: Size: ${DiskSizeGB} GB" -ForegroundColor DarkCyan
[void]$ReportLines.Add("Drive C: Architecture: $DriveTypeStr")

if ($DriveTypeStr -like "*HDD*") {
    $Score -= 25
    $Msg = "[TURTLE ENGINE] Drive C: is a Mechanical HDD. Spinning disks are the primary physical bottleneck in older PCs!"
    Write-Host "   $Msg" -ForegroundColor Yellow
    [void]$IssuesFound.Add("Mechanical HDD detected on primary OS drive C:")
} else {
    $Msg = "[ROCKET ENGINE] SSD high-speed storage verified."
    Write-Host "   $Msg" -ForegroundColor Green
}
[void]$ReportLines.Add($Msg)

if ($DiskFreePct -gt 15) {
    $Msg = "[OK] STORAGE CAPACITY: Healthy (${DiskFreeGB} GB free / ${DiskFreePct}% free space)."
    Write-Host "   $Msg" -ForegroundColor Green
} else {
    $Score -= 30
    $Msg = "[CRITICAL] STORAGE CHOKED: Only ${DiskFreeGB} GB left (${DiskFreePct}% free)! Windows requires >15% free space for pagefiles and temp operations."
    Write-Host "   $Msg" -ForegroundColor Red
    [void]$IssuesFound.Add("Low Drive C: Free Space (${DiskFreeGB} GB left)")
}
[void]$ReportLines.Add($Msg)

# Audit Temp Junk Files & Recycle Bin
$UserTempFiles = @(Get-ChildItem -Path $env:TEMP -File -Recurse -ErrorAction SilentlyContinue)
$SysTempFiles = @(Get-ChildItem -Path "C:\Windows\Temp" -File -Recurse -ErrorAction SilentlyContinue)
$TotalTempCount = $UserTempFiles.Count + $SysTempFiles.Count
$TotalTempMB = [Math]::Round((($UserTempFiles + $SysTempFiles | Measure-Object -Property Length -Sum).Sum) / 1MB, 1)

Write-Host "   -> Digital Waste Found: $TotalTempCount temporary junk files taking up ${TotalTempMB} MB of disk space." -ForegroundColor DarkGray
[void]$ReportLines.Add("Temp Clutter: $TotalTempCount files (${TotalTempMB} MB)")
Write-Host ""

# 4. SYSTEM UPTIME & PENDING RESTART AUDIT
Write-Host "[Check 4/7] System Uptime & Pending Windows Update Reboot Audit..." -ForegroundColor Yellow
$LastBoot = $OS.ConvertToDateTime($OS.LastBootUpTime)
$UptimeSpan = (Get-Date) - $LastBoot
$DaysUp = [Math]::Round($UptimeSpan.TotalDays, 1)

# Check if Windows is waiting for a reboot
$PendingReboot = $false
if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") { $PendingReboot = $true }
if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") { $PendingReboot = $true }

Write-Host "   -> Current System Uptime: ${DaysUp} continuous days without shutdown/restart" -ForegroundColor DarkCyan
if ($PendingReboot) {
    $Score -= 20
    $Msg = "[CRITICAL] PENDING RESTART: Windows Update has finished installing modules and is waiting for a reboot! Background maintenance services cause severe slowness until restarted."
    Write-Host "   $Msg" -ForegroundColor Red
    [void]$IssuesFound.Add("Pending Windows Update reboot required")
} elseif ($DaysUp -gt 14) {
    $Score -= 20
    $Msg = "[ZOMBIE UPTIME] PC has been running for ${DaysUp} days! Ghost handles and fragmented memory accumulate over time."
    Write-Host "   $Msg" -ForegroundColor Yellow
    [void]$IssuesFound.Add("High system uptime (${DaysUp} days without reboot)")
} else {
    $Msg = "[OK] UPTIME: Healthy (${DaysUp} days since last clean boot)."
    Write-Host "   $Msg" -ForegroundColor Green
}
[void]$ReportLines.Add($Msg)
Write-Host ""

# 5. ACTIVE POWER PLAN PROFILE AUDIT
Write-Host "[Check 5/7] Power Scheme Performance Audit..." -ForegroundColor Yellow
$ActivePower = "Unknown Scheme"
try {
    $PowerOut = powercfg /getactivescheme 2>&1
    if ($PowerOut -match '\((.*)\)') { $ActivePower = $matches[1] }
} catch { }

Write-Host "   -> Active Power Scheme: $ActivePower" -ForegroundColor DarkCyan
[void]$ReportLines.Add("Active Power Plan: $ActivePower")
if ($ActivePower -like "*Saver*" -or $ActivePower -like "*Eco*") {
    $Score -= 15
    $Msg = "[WARN] THROTTLE ALERT: Power Plan is set to '$ActivePower'. Windows actively throttles CPU clock frequency below maximum capability!"
    Write-Host "   $Msg" -ForegroundColor Yellow
    [void]$IssuesFound.Add("CPU throttled by '$ActivePower' power scheme")
} else {
    $Msg = "[OK] POWER SCHEME: Operating at standard performance levels ($ActivePower)."
    Write-Host "   $Msg" -ForegroundColor Green
}
[void]$ReportLines.Add($Msg)
Write-Host ""

# 6. NETWORK SOCKET & DNS CACHE AUDIT
Write-Host "[Check 6/7] Network Socket & DNS Cache Inspection..." -ForegroundColor Yellow
$NetConnCount = 0
try {
    if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
        $NetConnCount = @(Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue).Count
    } else {
        $NetConnCount = @(netstat -an | Select-String "ESTABLISHED").Count
    }
} catch { }

Write-Host "   -> Active Established Network Connections: $NetConnCount sockets open" -ForegroundColor DarkCyan
[void]$ReportLines.Add("Active Established Network Sockets: $NetConnCount")
if ($NetConnCount -gt 250) {
    $Msg = "[WARN] NETWORK OVERLOAD: High number of open network connections ($NetConnCount). Cloud apps or browser tabs may experience delays."
    Write-Host "   $Msg" -ForegroundColor Yellow
} else {
    $Msg = "[OK] NETWORK SOCKETS: Healthy connection queue ($NetConnCount)."
    Write-Host "   $Msg" -ForegroundColor Green
}
[void]$ReportLines.Add($Msg)
Write-Host ""

# 7. BACKSEAT DRIVERS (STARTUP APPLICATIONS AUDIT)
Write-Host "[Check 7/7] Startup Application Impact Audit..." -ForegroundColor Yellow
$RunKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
)
$StartupApps = New-Object System.Collections.ArrayList
foreach ($Key in $RunKeys) {
    if (Test-Path $Key) {
        $Props = Get-ItemProperty $Key -ErrorAction SilentlyContinue
        foreach ($Name in $Props.PSObject.Properties.Name) {
            if ($Name -notlike "PSPath*" -and $Name -notlike "PSParentPath*" -and $Name -notlike "PSChildName*" -and $Name -notlike "PSDrive*") {
                [void]$StartupApps.Add("$Name : $($Props.$Name)")
            }
        }
    }
}

Write-Host "   -> Auto-Launching Boot Applications: $($StartupApps.Count) items found" -ForegroundColor DarkCyan
[void]$ReportLines.Add("Startup Applications Count: $($StartupApps.Count)")
if ($StartupApps.Count -le 5) {
    $Msg = "[OK] STARTUP IMPACT: Low boot clutter ($($StartupApps.Count) auto-launch items)."
    Write-Host "   $Msg" -ForegroundColor Green
} elseif ($StartupApps.Count -le 12) {
    $Score -= 10
    $Msg = "[WARN] STARTUP IMPACT: Moderate boot clutter ($($StartupApps.Count) auto-launch items)."
    Write-Host "   $Msg" -ForegroundColor Yellow
} else {
    $Score -= 20
    $Msg = "[TRAFFIC JAM] STARTUP IMPACT: Severe boot congestion ($($StartupApps.Count) applications fighting to start simultaneously)!"
    Write-Host "   $Msg" -ForegroundColor Red
    [void]$IssuesFound.Add("Excessive startup applications ($($StartupApps.Count) items)")
}
[void]$ReportLines.Add($Msg)
Write-Host ""

# ---------------------------------------------------------
# FINAL DIAGNOSTIC SCORE CARD
# ---------------------------------------------------------
if ($Score -lt 0) { $Score = 10 }
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "               SHERLOCK SLOW DIAGNOSTIC SCORECARD" -ForegroundColor Magenta
Write-Host "==========================================================================" -ForegroundColor Magenta

Write-Host "SYSTEM SPEED HEALTH SCORE: " -NoNewline
if ($Score -ge 85) {
    Write-Host "${Score} / 100 (EXCELLENT SPEED!)" -ForegroundColor Green
} elseif ($Score -ge 65) {
    Write-Host "${Score} / 100 (MODERATE SLUGGISHNESS)" -ForegroundColor Yellow
} else {
    Write-Host "${Score} / 100 (TRAFFIC JAM / TUNE-UP REQUIRED)" -ForegroundColor Red
}

[void]$ReportLines.Add("")
[void]$ReportLines.Add("FINAL SPEED SCORE: $Score / 100")

if ($IssuesFound.Count -gt 0) {
    Write-Host "`nKey Bottlenecks Identified:" -ForegroundColor Yellow
    [void]$ReportLines.Add("Identified Bottlenecks:")
    foreach ($Issue in $IssuesFound) {
        Write-Host "  [!] $Issue" -ForegroundColor Yellow
        [void]$ReportLines.Add("  - $Issue")
    }
} else {
    Write-Host "`nNo significant slowness bottlenecks detected!" -ForegroundColor Green
}

# Save diagnostic file
$ReportPath = Join-Path -Path $ReportsDir -ChildPath "slowness_report_$($env:COMPUTERNAME)_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$ReportLines | Out-File -FilePath $ReportPath -Encoding utf8 -Force
Write-Host "`nDiagnostic case report saved to: reports\$(Split-Path $ReportPath -Leaf)" -ForegroundColor Cyan

# ==========================================================================
# PHASE 2: GRANULAR INTERACTIVE TUNE-UP (Y/N FOR EACH FIX)
# ==========================================================================
Write-Host "`n==========================================================================" -ForegroundColor Magenta
Write-Host "       INTERACTIVE TURBO TUNE-UP MENU (GRANULAR Y/N SELECTION)" -ForegroundColor Magenta
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "Answer [Y]es or [N]o for each individual cleanup action below:" -ForegroundColor Cyan
Write-Host ""

# ACTION 1: Clean User & System Temp Files
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "[ACTION 1/5] Temporary Digital Clutter Cleanup" -ForegroundColor White
Write-Host "Target: User Temp (%TEMP%) and System Temp (C:\Windows\Temp)" -ForegroundColor DarkCyan
Write-Host "Benefit: Reclaims disk space and removes corrupted application caches." -ForegroundColor DarkGray
$Ans1 = Read-Host " -> Execute Temp File Cleanup? (Y/N)"
if ($Ans1 -eq "Y" -or $Ans1 -eq "y") {
    Write-Host "    [EXEC] Sweeping user & system temporary files..." -ForegroundColor Green
    Get-ChildItem -Path $env:TEMP -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
    Get-ChildItem -Path "C:\Windows\Temp" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
    Write-Host "    [DONE] Temporary cache swept cleanly." -ForegroundColor Green
} else {
    Write-Host "    [SKIP] Skipped temporary file cleanup." -ForegroundColor DarkYellow
}
Write-Host ""

# ACTION 2: Empty Recycle Bin
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "[ACTION 2/5] Recycle Bin Purge" -ForegroundColor White
Write-Host "Target: Local Recycle Bin across all drives" -ForegroundColor DarkCyan
Write-Host "Benefit: Permanently frees hard drive storage space." -ForegroundColor DarkGray
$Ans2 = Read-Host " -> Empty Recycle Bin? (Y/N)"
if ($Ans2 -eq "Y" -or $Ans2 -eq "y") {
    Write-Host "    [EXEC] Purging deleted items from Recycle Bin..." -ForegroundColor Green
    try {
        $Shell = New-Object -ComObject Shell.Application
        $Bin = $Shell.Namespace(10)
        $Bin.Items() | ForEach-Object { Remove-Item $_.Path -Force -Recurse -ErrorAction SilentlyContinue }
        Write-Host "    [DONE] Recycle Bin emptied successfully." -ForegroundColor Green
    } catch {
        Write-Host "    [INFO] Recycle Bin is already clean or locked." -ForegroundColor DarkGray
    }
} else {
    Write-Host "    [SKIP] Skipped Recycle Bin purge." -ForegroundColor DarkYellow
}
Write-Host ""

# ACTION 3: Flush DNS & Reset Network Buffer
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "[ACTION 3/5] Network Pipe & DNS Cache Refresh" -ForegroundColor White
Write-Host "Target: Windows Resolver Cache (ipconfig /flushdns)" -ForegroundColor DarkCyan
Write-Host "Benefit: Fixes sluggish web browsing, outdated DNS lookups, and socket lag." -ForegroundColor DarkGray
$Ans3 = Read-Host " -> Flush DNS and reset network resolver cache? (Y/N)"
if ($Ans3 -eq "Y" -or $Ans3 -eq "y") {
    Write-Host "    [EXEC] Flushing DNS resolver cache..." -ForegroundColor Green
    ipconfig /flushdns | Out-Null
    Write-Host "    [DONE] DNS resolver cache refreshed." -ForegroundColor Green
} else {
    Write-Host "    [SKIP] Skipped network cache flush." -ForegroundColor DarkYellow
}
Write-Host ""

# ACTION 4: Power Plan Optimization
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "[ACTION 4/5] Power Scheme Performance Boost" -ForegroundColor White
Write-Host "Target: Active Windows Power Plan" -ForegroundColor DarkCyan
Write-Host "Benefit: Ensures CPU operates at full clock speed without ECO throttling." -ForegroundColor DarkGray
$Ans4 = Read-Host " -> Switch active Power Plan to 'High Performance'? (Y/N)"
if ($Ans4 -eq "Y" -or $Ans4 -eq "y") {
    Write-Host "    [EXEC] Locating High Performance power scheme GUID..." -ForegroundColor Green
    try {
        $HighPerfGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
        powercfg /setactive $HighPerfGuid 2>&1 | Out-Null
        $NewPlan = powercfg /getactivescheme 2>&1
        Write-Host "    [DONE] Updated power plan: $NewPlan" -ForegroundColor Green
    } catch {
        Write-Host "    [WARN] Could not modify power scheme (may require local administrator rights)." -ForegroundColor Yellow
    }
} else {
    Write-Host "    [SKIP] Retained current power scheme." -ForegroundColor DarkYellow
}
Write-Host ""

# ACTION 5: Export Startup Report & Cleanup Advice
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "[ACTION 5/5] Startup Application Audit Export" -ForegroundColor White
Write-Host "Target: Auto-launch registry keys (Run entries)" -ForegroundColor DarkCyan
Write-Host "Benefit: Exports a detailed list of boot items into a clean text file so you can review what to disable." -ForegroundColor DarkGray
$Ans5 = Read-Host " -> Export detailed Startup Applications audit file? (Y/N)"
if ($Ans5 -eq "Y" -or $Ans5 -eq "y") {
    $StartupReportPath = Join-Path -Path $ReportsDir -ChildPath "startup_audit_$($env:COMPUTERNAME).txt"
    $StartLines = New-Object System.Collections.ArrayList
    [void]$StartLines.Add("DETAILED STARTUP APPLICATIONS AUDIT FOR: $env:COMPUTERNAME")
    [void]$StartLines.Add("==========================================================================")
    foreach ($Item in $StartupApps) { [void]$StartLines.Add(" * $Item") }
    [void]$StartLines.Add("==========================================================================")
    [void]$StartLines.Add("TIP: To disable unwanted startup apps in Windows 10/11, press Ctrl+Shift+Esc to open Task Manager -> Startup tab.")
    $StartLines | Out-File -FilePath $StartupReportPath -Encoding utf8 -Force
    Write-Host "    [DONE] Startup audit exported to: reports\startup_audit_$($env:COMPUTERNAME).txt" -ForegroundColor Green
} else {
    Write-Host "    [SKIP] Skipped startup audit export." -ForegroundColor DarkYellow
}

Write-Host "`n==========================================================================" -ForegroundColor Green
Write-Host "        SHERLOCK SLOW INVESTIGATION & TUNE-UP COMPLETED!" -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
if ($PendingReboot -or $DaysUp -gt 14) {
    Write-Host "SHERLOCK PRO TIP: Please restart your computer soon to complete pending Windows maintenance!" -ForegroundColor Yellow
}
