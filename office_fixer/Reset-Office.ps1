# Diagnostics: Safely resets Office settings, clears cache, and configures bypass values
$ErrorActionPreference = "SilentlyContinue"

# Try to bypass Execution Policy for the current session/process
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

if (-not (Get-UserApproval "Reset Microsoft Office configuration settings, clear caches, and backup/reset profiles?")) {
    Log-Msg "Office settings reset skipped by user." "WARN"
    return 0
}

Log-Msg "Starting configuration reset..."
$RollbackLog = [System.Collections.ArrayList]@()
$OfficeVersions = @("14.0", "15.0", "16.0")

foreach ($Ver in $OfficeVersions) {
    $RegKey = "HKCU:\Software\Microsoft\Office\$Ver"
    
    if (-not (Test-Path $RegKey)) { continue }
    
    Log-Msg "Processing settings for Office version $Ver..."

    # 1. Backup Registry Key
    if (Get-UserApproval "Backup registry hive: '$RegKey' before making changes?") {
        $BackupFile = Join-Path $PSScriptRoot "Logs\HKCU_Office_$Ver`_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
        try {
            $RegPathRaw = $RegKey -replace "HKCU:", "HKCU"
            cmd.exe /c "reg export `"$RegPathRaw`" `"$BackupFile`" /y" | Out-Null
            Log-Msg "  [OK] Successfully backed up '$RegKey' to: $BackupFile"
            $RollbackLog.Add("RegistryImport: $BackupFile") | Out-Null
        } catch {
            Log-Msg "  [ERROR] Failed to backup '$RegKey': $($_.Exception.Message)" "ERROR"
        }
    }

    # 2. Reset First-Run & Disable Graphics Hardware Acceleration
    if (Get-UserApproval "Bypass First-Run Opt-in screen & Disable Hardware Graphics Acceleration for version $Ver?") {
        try {
            $CommonPath = Join-Path $RegKey "Common\General"
            if (-not (Test-Path $CommonPath)) { New-Item -Path $CommonPath -Force | Out-Null }
            
            Set-ItemProperty -Path $CommonPath -Name "ShownFirstRunOptin" -Value 1 -PropertyType DWord -Force | Out-Null
            Set-ItemProperty -Path $CommonPath -Name "FirstRun" -Value 0 -PropertyType DWord -Force | Out-Null
            Set-ItemProperty -Path $CommonPath -Name "BootedRTM" -Value 1 -PropertyType DWord -Force | Out-Null
            
            $GraphicsPath = Join-Path $RegKey "Common\Graphics"
            if (-not (Test-Path $GraphicsPath)) { New-Item -Path $GraphicsPath -Force | Out-Null }
            Set-ItemProperty -Path $GraphicsPath -Name "DisableHardwareAcceleration" -Value 1 -PropertyType DWord -Force | Out-Null
            
            Log-Msg "  [OK] Bypassed First-Run screen and disabled Hardware Graphics Acceleration for version $Ver."
        } catch {
            Log-Msg "  [ERROR] Failed to set bypass keys: $($_.Exception.Message)" "ERROR"
        }
    }

    # 3. Reset Normal.dotm
    $TemplatesDir = Join-Path $env:APPDATA "Microsoft\Templates"
    $NormalDot = Join-Path $TemplatesDir "Normal.dotm"
    if (Test-Path $NormalDot) {
        if (Get-UserApproval "Rename Word template Normal.dotm to Normal.dotm.old?") {
            try {
                Rename-Item -Path $NormalDot -NewName "Normal.dotm.old" -Force -ErrorAction Stop
                Log-Msg "  [OK] Renamed Normal.dotm to Normal.dotm.old."
                $RollbackLog.Add("FileRename: $NormalDot.old -> $NormalDot") | Out-Null
            } catch { Log-Msg "  [ERROR] Failed to rename Normal.dotm: $($_.Exception.Message)" "ERROR" }
        }
    }

    # 4. Rename Office User Profile directories
    $ProfilePaths = @(
        Join-Path $env:APPDATA "Microsoft\Office"
        Join-Path $env:LOCALAPPDATA "Microsoft\Office"
    )

    foreach ($Prof in $ProfilePaths) {
        if (Test-Path $Prof) {
            if (Get-UserApproval "Backup and rename profile folder '$Prof'?") {
                $NewName = "$Prof`_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                try {
                    Rename-Item -Path $Prof -NewName $NewName -Force -ErrorAction Stop
                    Log-Msg "  [OK] Successfully renamed profile folder to: $NewName"
                    $RollbackLog.Add("DirectoryRename: $NewName -> $Prof") | Out-Null
                } catch { Log-Msg "  [ERROR] Failed to rename profile folder: $($_.Exception.Message)" "ERROR" }
            }
        }
    }

    # 5. Outlook Specific Repairs
    # Autodiscover registry values
    if (Get-UserApproval "Apply Autodiscover connection bypass registry keys for Outlook version $Ver?") {
        try {
            $AutoPath = Join-Path $RegKey "Outlook\AutoDiscover"
            if (-not (Test-Path $AutoPath)) { New-Item -Path $AutoPath -Force | Out-Null }
            Set-ItemProperty -Path $AutoPath -Name "ExcludeHttpsRootDomain" -Value 1 -PropertyType DWord -Force | Out-Null
            Set-ItemProperty -Path $AutoPath -Name "ExcludeSrvRecord" -Value 1 -PropertyType DWord -Force | Out-Null
            Set-ItemProperty -Path $AutoPath -Name "PreferLocalXML" -Value 1 -PropertyType DWord -Force | Out-Null
            Log-Msg "  [OK] Configured Autodiscover bypass values."
        } catch { Log-Msg "  [ERROR] Failed to configure Autodiscover values: $($_.Exception.Message)" "ERROR" }
    }

    # Registry Profile reset
    $OutlookProf = Join-Path $RegKey "Outlook\Profiles"
    if (Test-Path $OutlookProf) {
        if (Get-UserApproval "Backup and rename Outlook Profile registry keys under '$Ver'?") {
            $RegOutlookRaw = $OutlookProf -replace "HKCU:", "HKCU"
            $BackupFileOut = Join-Path $PSScriptRoot "Logs\HKCU_Outlook_Profiles_$Ver`_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
            try {
                cmd.exe /c "reg export `"$RegOutlookRaw`" `"$BackupFileOut`" /y" | Out-Null
                Remove-Item -Path $OutlookProf -Recurse -Force -ErrorAction Stop
                Log-Msg "  [OK] Backed up and deleted Outlook registry profiles. Outlook will prompt for profile creation."
                $RollbackLog.Add("RegistryImport: $BackupFileOut") | Out-Null
            } catch { Log-Msg "  [ERROR] Failed to reset Outlook profiles: $($_.Exception.Message)" "ERROR" }
        }
    }
}

# 6. Wiping Outlook OST Cache files (across all versions)
$OutlookDir = Join-Path $env:LOCALAPPDATA "Microsoft\Outlook"
if (Test-Path $OutlookDir) {
    if (Get-UserApproval "Rename offline Outlook Exchange cache files (*.ost) to *.ost.old to force synchronization rebuild?") {
        try {
            $OstFiles = Get-ChildItem -Path $OutlookDir -Filter "*.ost" -File -Force -ErrorAction SilentlyContinue
            if ($OstFiles.Count -gt 0) {
                foreach ($File in $OstFiles) {
                    $OldPath = $File.FullName
                    $NewName = "$($File.Name).old"
                    Rename-Item -Path $OldPath -NewName $NewName -Force -ErrorAction Stop
                    Log-Msg "  [OK] Renamed OST file '$OldPath' to '$NewName'."
                    $RollbackLog.Add("FileRename: $OldPath.old -> $OldPath") | Out-Null
                }
            } else {
                Log-Msg "No active *.ost cache files found."
            }
        } catch { Log-Msg "  [ERROR] Failed to rename OST files: $($_.Exception.Message)" "ERROR" }
    }
    
    # Rename send/receive files (.srs)
    if (Get-UserApproval "Rename Outlook Send/Receive config files (*.srs) to resolve connection freezing?") {
        try {
            $SrsFiles = Get-ChildItem -Path $OutlookDir -Filter "*.srs" -File -Force -ErrorAction SilentlyContinue
            foreach ($File in $SrsFiles) {
                $OldPath = $File.FullName
                Rename-Item -Path $OldPath -NewName "$($File.Name).old" -Force | Out-Null
                Log-Msg "  [OK] Renamed SRS file '$OldPath'."
            }
        } catch { Log-Msg "  [ERROR] Failed to reset SRS config." "ERROR" }
    }
}

# 7. Credential Manager Purge (Interactive)
if (Get-UserApproval "Purge Microsoft Office & Outlook saved login credentials from Windows Credential Manager?") {
    try {
        $Creds = cmdkey.exe /list
        $TargetLines = $Creds | Select-String "Target:"
        $DeletedCount = 0
        foreach ($Line in $TargetLines) {
            if ($Line -match "Target:\s*(.*Office.*|.*Outlook.*|.*MicrosoftPlatform.*)") {
                $Target = $Matches[1].Trim()
                cmdkey.exe /delete:$target | Out-Null
                Log-Msg "  [OK] Deleted cached credential: $Target"
                $DeletedCount++
            }
        }
        Log-Msg "Deleted $DeletedCount Office/Outlook cached credentials."
    } catch {
        Log-Msg "  [ERROR] Failed to purge credentials: $($_.Exception.Message)" "ERROR"
    }
}

# Save rollback data to file
if ($RollbackLog.Count -gt 0) {
    $RollbackFile = Join-Path $PSScriptRoot "Logs\Rollback_Instructions_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $RollbackLog | Out-File -FilePath $RollbackFile -Encoding UTF8 -Force
    Log-Msg "Rollback logs saved to: $RollbackFile"
}

Log-Msg "Configuration reset completed."
return 0
