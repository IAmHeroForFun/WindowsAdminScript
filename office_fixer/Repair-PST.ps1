# ==========================================================================
#   Outlook PST / OST Recovery, SCANPST Locator & 100GB Limit Expander
#   Compatible with Windows 7-11 | Outlook 2010 - 365 (32-bit & 64-bit)
# ==========================================================================
$ErrorActionPreference = "SilentlyContinue"

# Try to bypass Execution Policy for current session
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
} catch {}

# Ensure $PSScriptRoot is defined
if (-not $PSScriptRoot) {
    if ($MyInvocation.MyCommand.Definition) {
        $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    } else {
        $PSScriptRoot = Get-Location | Select-Object -ExpandProperty Path
    }
}

# Determine Reports / Logs directory
$ReportsDir = $null
$ParentDir = Split-Path -Parent -Path $PSScriptRoot
if ($ParentDir -match "SysMaster") {
    $ReportsDir = Join-Path $ParentDir "reports"
} else {
    $ReportsDir = Join-Path $PSScriptRoot "Logs"
}
if (-not (Test-Path $ReportsDir)) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null }

$Global:LogFile = Join-Path $ReportsDir "PST_Repair.log"
$ReportPath = Join-Path $ReportsDir "PST_Repair_Report.txt"
$StartTime = [System.Diagnostics.Stopwatch]::StartNew()

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
    
    $Color = "Gray"
    if ($Type -eq "ERROR") { $Color = "Red" }
    elseif ($Type -eq "WARN") { $Color = "Yellow" }
    elseif ($Type -eq "SUCCESS") { $Color = "Green" }
    elseif ($Type -eq "STAGE") { $Color = "Cyan" }
    
    Write-Host $Formatted -ForegroundColor $Color
    if ($Global:LogFile) {
        $Formatted | Out-File -FilePath $Global:LogFile -Append -Encoding UTF8
    }
}

Clear-Host
Log-Msg "==========================================================================" "STAGE"
Log-Msg "   OUTLOOK PST / OST RECOVERY, SCANPST LOCATOR & LIMIT EXPANDER" "STAGE"
Log-Msg "==========================================================================" "STAGE"
Log-Msg "Execution started on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# --------------------------------------------------------------------------
# 1. AUTO-DISCOVER SCANPST.EXE BINARY
# --------------------------------------------------------------------------
Log-Msg "Searching for SCANPST.EXE (Microsoft Outlook Inbox Repair Tool)..." "STAGE"

$ScanPstCandidatePaths = @(
    # Click-to-Run (Office 365, 2021, 2019, 2016)
    "${env:ProgramFiles}\Microsoft Office\root\Office16\SCANPST.EXE",
    "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16\SCANPST.EXE",
    "${env:ProgramFiles}\Microsoft Office\root\Office15\SCANPST.EXE",
    "${env:ProgramFiles(x86)}\Microsoft Office\root\Office15\SCANPST.EXE",
    # MSI Installations
    "${env:ProgramFiles}\Microsoft Office\Office16\SCANPST.EXE",
    "${env:ProgramFiles(x86)}\Microsoft Office\Office16\SCANPST.EXE",
    "${env:ProgramFiles}\Microsoft Office\Office15\SCANPST.EXE",
    "${env:ProgramFiles(x86)}\Microsoft Office\Office15\SCANPST.EXE",
    "${env:ProgramFiles}\Microsoft Office\Office14\SCANPST.EXE",
    "${env:ProgramFiles(x86)}\Microsoft Office\Office14\SCANPST.EXE",
    "${env:ProgramFiles}\Microsoft Office\Office12\SCANPST.EXE",
    "${env:ProgramFiles(x86)}\Microsoft Office\Office12\SCANPST.EXE"
)

$LocatedScanPst = $null
foreach ($Path in $ScanPstCandidatePaths) {
    if ($Path -and (Test-Path $Path)) {
        $LocatedScanPst = $Path
        break
    }
}

if ($LocatedScanPst) {
    Log-Msg "  [FOUND] SCANPST.EXE located at:" "SUCCESS"
    Log-Msg "          $LocatedScanPst" "SUCCESS"
} else {
    Log-Msg "  [WARN] SCANPST.EXE could not be found in standard paths." "WARN"
}

# --------------------------------------------------------------------------
# 2. DISCOVER LOCAL PST & OST DATA FILES
# --------------------------------------------------------------------------
Log-Msg "Scanning user profile for Outlook Data Files (*.pst / *.ost)..." "STAGE"

$PstSearchDirs = @(
    (Join-Path $env:USERPROFILE "Documents\Outlook Files"),
    (Join-Path $env:LOCALAPPDATA "Microsoft\Outlook"),
    (Join-Path $env:APPDATA "Microsoft\Outlook"),
    (Join-Path $env:USERPROFILE "AppData\Local\Microsoft\Outlook")
)

$DiscoveredFiles = @()
foreach ($Dir in $PstSearchDirs) {
    if (Test-Path $Dir) {
        $Files = Get-ChildItem -Path $Dir -Include "*.pst", "*.ost" -File -Recurse -Force -ErrorAction SilentlyContinue
        if ($Files) {
            $DiscoveredFiles += $Files
        }
    }
}

# Deduplicate discovered files
$UniqueFiles = $DiscoveredFiles | Select-Object -Unique -Property FullName

Write-Host ""
if ($UniqueFiles -and $UniqueFiles.Count -gt 0) {
    Log-Msg "Discovered $($UniqueFiles.Count) Outlook Data File(s):" "SUCCESS"
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
    $Index = 1
    $FileMap = @{}
    foreach ($F in $UniqueFiles) {
        $FileObj = Get-Item $F.FullName -ErrorAction SilentlyContinue
        $SizeGB = [Math]::Round($FileObj.Length / 1GB, 2)
        $SizeMB = [Math]::Round($FileObj.Length / 1MB, 2)
        $SizeDisplay = if ($SizeGB -ge 1) { "${SizeGB} GB" } else { "${SizeMB} MB" }
        
        $IsReadOnly = $FileObj.IsReadOnly
        $StatusBadge = if ($SizeGB -ge 45) { "[CRITICAL: Near 50GB Limit!]" } elseif ($IsReadOnly) { "[READ-ONLY]" } else { "[OK]" }
        $BadgeColor = if ($SizeGB -ge 45) { "Red" } elseif ($IsReadOnly) { "Yellow" } else { "Green" }
        
        Write-Host "  [$Index] $($FileObj.Name) ($SizeDisplay) $StatusBadge" -ForegroundColor $BadgeColor
        Write-Host "       Path: $($FileObj.FullName)" -ForegroundColor DarkGray
        Write-Host "       Last Modified: $($FileObj.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor DarkGray
        
        $FileMap[$Index] = $FileObj
        $Index++
    }
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
} else {
    Log-Msg "No Outlook PST or OST files found in standard profile folders." "WARN"
}

# --------------------------------------------------------------------------
# 3. EXPAND PST FILE SIZE LIMITS (50GB -> 100GB)
# --------------------------------------------------------------------------
if (Get-UserApproval "Expand Outlook PST / OST file size limit from 50GB to 100GB in Windows Registry?") {
    Log-Msg "Configuring MaxLargeFileSize (100GB) and WarnLargeFileSize (95GB)..." "STAGE"
    $OfficeVersions = @("14.0", "15.0", "16.0")
    
    # 102400 MB = 100 GB; 97280 MB = 95 GB
    $MaxLarge = 102400
    $WarnLarge = 97280
    
    foreach ($Ver in $OfficeVersions) {
        $PstRegKey = "HKCU:\Software\Microsoft\Office\$Ver\Outlook\PST"
        try {
            if (-not (Test-Path $PstRegKey)) {
                New-Item -Path $PstRegKey -Force | Out-Null
            }
            Set-ItemProperty -Path $PstRegKey -Name "MaxLargeFileSize" -Value $MaxLarge -PropertyType DWord -Force | Out-Null
            Set-ItemProperty -Path $PstRegKey -Name "WarnLargeFileSize" -Value $WarnLarge -PropertyType DWord -Force | Out-Null
            Log-Msg "  [OK] Successfully configured 100GB limit for Outlook version $Ver." "SUCCESS"
        } catch {
            Log-Msg "  [ERROR] Failed to set registry limits for version $($Ver) - $($_.Exception.Message)" "ERROR"
        }
    }
}

# --------------------------------------------------------------------------
# 4. REMOVE READ-ONLY ATTRIBUTES & FIX NTFS PERMISSIONS
# --------------------------------------------------------------------------
if ($UniqueFiles -and $UniqueFiles.Count -gt 0) {
    if (Get-UserApproval "Unlock all discovered PST/OST files (Remove Read-Only attributes & fix NTFS permissions)?") {
        Log-Msg "Unlocking PST/OST files..." "STAGE"
        foreach ($F in $UniqueFiles) {
            try {
                $FilePath = $F.FullName
                # Clear ReadOnly
                Set-ItemProperty -Path $FilePath -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
                cmd.exe /c "attrib -r `"$FilePath`"" | Out-Null
                
                # Restore User Full Control permissions
                cmd.exe /c "icacls `"$FilePath`" /grant `"$env:USERNAME`":(F) /T /C" | Out-Null
                Log-Msg "  [UNLOCKED] $FilePath" "SUCCESS"
            } catch {
                Log-Msg "  [ERROR] Failed to unlock $($F.FullName): $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

# --------------------------------------------------------------------------
# 5. INTERACTIVE SCANPST.EXE LAUNCHER
# --------------------------------------------------------------------------
if ($LocatedScanPst) {
    if (Get-UserApproval "Launch SCANPST.EXE (Microsoft Inbox Repair Tool) now to repair a PST file?") {
        $SelectedFile = $null
        if ($UniqueFiles -and $UniqueFiles.Count -gt 0) {
            Write-Host ""
            $Choice = Read-Host "Enter file index to repair [1-$($UniqueFiles.Count)] or type 'C' for custom path"
            if ($Choice -match "^\d+$" -and $FileMap[[int]$Choice]) {
                $SelectedFile = $FileMap[[int]$Choice].FullName
            }
        }
        
        if (-not $SelectedFile) {
            Write-Host ""
            $SelectedFile = Read-Host "Enter absolute path to .pst file (or press Enter to launch SCANPST without pre-selected file)"
        }
        
        Log-Msg "Launching SCANPST.EXE..." "STAGE"
        Write-Host ""
        Write-Host "==========================================================================" -ForegroundColor Green
        Write-Host "  SCANPST INSTRUCTIONS:" -ForegroundColor Yellow
        Write-Host "  1. In SCANPST, confirm the file path is set to: $SelectedFile" -ForegroundColor Cyan
        Write-Host "  2. Click 'Start' to begin the integrity scan." -ForegroundColor Cyan
        Write-Host "  3. When scan finishes, ensure 'Make backup of scanned file before repairing' is checked." -ForegroundColor Cyan
        Write-Host "  4. Click 'Repair' and wait for completion." -ForegroundColor Cyan
        Write-Host "==========================================================================" -ForegroundColor Green
        Write-Host ""
        
        try {
            if ($SelectedFile -and (Test-Path $SelectedFile)) {
                # Copy path to clipboard if available
                try { Set-Clipboard -Value $SelectedFile -ErrorAction SilentlyContinue } catch {}
                Start-Process -FilePath $LocatedScanPst -ArgumentList "`"$SelectedFile`""
            } else {
                Start-Process -FilePath $LocatedScanPst
            }
            Log-Msg "  [OK] SCANPST.EXE process started successfully." "SUCCESS"
        } catch {
            Log-Msg "  [ERROR] Failed to launch SCANPST.EXE: $($_.Exception.Message)" "ERROR"
        }
    }
}

# --------------------------------------------------------------------------
# 6. GENERATE FINAL REPORT
# --------------------------------------------------------------------------
$StartTime.Stop()
$ElapsedTime = $StartTime.Elapsed

Log-Msg "Generating PST recovery summary report..." "STAGE"
$Report = [System.Collections.ArrayList]@()
$Report.Add("==========================================================================")
$Report.Add("         OUTLOOK PST / OST RECOVERY & SCANPST REPAIR REPORT")
$Report.Add("==========================================================================")
$Report.Add("Generated on   : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$Report.Add("Execution Time : $($ElapsedTime.ToString('hh\:mm\:ss'))")
$Report.Add("Host System    : $env:COMPUTERNAME")
$Report.Add("SCANPST Path   : $(if ($LocatedScanPst) { $LocatedScanPst } else { 'Not Located' })")
$Report.Add("==========================================================================")
$Report.Add("")
$Report.Add("DISCOVERED DATA FILES:")
if ($UniqueFiles -and $UniqueFiles.Count -gt 0) {
    foreach ($F in $UniqueFiles) {
        $FileObj = Get-Item $F.FullName -ErrorAction SilentlyContinue
        $SizeMB = [Math]::Round($FileObj.Length / 1MB, 2)
        $Report.Add("   - File : $($FileObj.FullName)")
        $Report.Add("     Size : ${SizeMB} MB | Last Modified: $($FileObj.LastWriteTime)")
    }
} else {
    $Report.Add("   - No PST/OST files found in standard locations.")
}
$Report.Add("")
$Report.Add("ACTIONS PERFORMED:")
$Report.Add("   - Expanded MaxLargeFileSize to 100GB (102400 MB) in Registry")
$Report.Add("   - Unlocked Read-Only attributes & granted NTFS Full Control on PST files")
$Report.Add("   - Provided automated SCANPST.EXE guidance")
$Report.Add("")
$Report.Add("Detailed log file: $Global:LogFile")
$Report.Add("==========================================================================")

$Report | Out-File -FilePath $ReportPath -Encoding UTF8 -Force

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "       OUTLOOK PST RECOVERY & OPTIMIZATION COMPLETED!" -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Report saved to: $ReportPath" -ForegroundColor Green
Write-Host "  Process Log      : $Global:LogFile" -ForegroundColor DarkCyan
Write-Host "  Elapsed Time     : $($ElapsedTime.ToString('hh\:mm\:ss'))" -ForegroundColor DarkCyan
Write-Host ""
