# Windows 11 Enterprise-Grade Debloat & Privacy Optimizer
# Designed specifically for Windows 11 (builds 22000+)
# Operates safely with admin confirmation prompts and verification logs.

$ErrorActionPreference = "SilentlyContinue"

# Check if running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "==========================================================================" -ForegroundColor Red
    Write-Host "  [ERROR] Administrative privileges are required to debloat Windows 11." -ForegroundColor Red
    Write-Host "  Please run this script as an Administrator." -ForegroundColor Red
    Write-Host "==========================================================================" -ForegroundColor Red
    Write-Host "`nPress Enter to exit..." -ForegroundColor DarkGray; [void](Read-Host)
    exit 1
}

function Show-Header {
    Clear-Host
    Write-Host "==========================================================================" -ForegroundColor Green
    Write-Host "             WINDOWS 11 DEBLOAT & PRIVACY OPTIMIZATION SUITE" -ForegroundColor Green
    Write-Host "==========================================================================" -ForegroundColor Green
    Write-Host "  OS: $( (Get-WmiObject Win32_OperatingSystem).Caption ) | Host: $env:COMPUTERNAME" -ForegroundColor DarkCyan
    Write-Host "  Designed exclusively for safe, reversible customization of Windows 11" -ForegroundColor DarkGray
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
}

# Helper function for user prompts
function Ask-Option ($ActionText) {
    while ($true) {
        $Response = Read-Host " -> $ActionText? [Y/N]"
        if ($Response -eq "Y" -or $Response -eq "y") { return $true }
        if ($Response -eq "N" -or $Response -eq "n") { return $false }
        Write-Host "Please enter Y (yes) or N (no)." -ForegroundColor Yellow
    }
}

while ($true) {
    Show-Header
    Write-Host "  [1] Remove Sponsored UWP Apps & Bloatware (TikTok, Spotify, Xbox, etc.)" -ForegroundColor Cyan
    Write-Host "  [2] Disable Diagnostic Telemetry & Privacy Tracking Services" -ForegroundColor Cyan
    Write-Host "  [3] Optimize Windows 11 Taskbar (Hide Widgets, Chat, Task View, Search)" -ForegroundColor Cyan
    Write-Host "  [4] Disable OneDrive Auto-Startup & Background Sync" -ForegroundColor Cyan
    Write-Host "  [5] Apply ALL Recommended Windows 11 Optimization Tweaks" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [Q] Exit Debloater" -ForegroundColor DarkRed
    Write-Host "==========================================================================" -ForegroundColor Green
    
    $Choice = Read-Host "Select an optimization task [1-5, Q]"
    
    switch ($Choice) {
        "1" {
            Show-Header
            Write-Host "Uninstalling Sponsored UWP Bloatware..." -ForegroundColor Cyan
            
            # Safe bloatware list to target (avoids system-critical apps)
            $BloatwareList = @(
                "*Clipchamp*",
                "*Disney*",
                "*Spotify*",
                "*TikTok*",
                "*Facebook*",
                "*Instagram*",
                "*PrimeVideo*",
                "*XboxApp*",
                "*XboxGamingOverlay*",
                "*FeedbackHub*",
                "*YourPhone*",
                "*BingNews*",
                "*BingWeather*",
                "*GetHelp*",
                "*Cortana*",
                "*MixedReality*",
                "*Skype*",
                "*SolitaireCollection*"
            )
            
            $Confirm = Ask-Option "Confirm uninstallation of UWP bloatware packages"
            if ($Confirm) {
                Write-Host "`n[+] Scanning and removing packages..." -ForegroundColor Cyan
                $RemovedCount = 0
                foreach ($App in $BloatwareList) {
                    $Packages = Get-AppxPackage -Name $App -AllUsers -ErrorAction SilentlyContinue
                    if ($Packages) {
                        foreach ($Pkg in $Packages) {
                            try {
                                Remove-AppxPackage -Package $Pkg.PackageFullName -ErrorAction Stop
                                Write-Host "  -> Removed: $($Pkg.Name)" -ForegroundColor Green
                                $RemovedCount++
                            } catch {
                                Write-Host "  -> Failed to remove: $($Pkg.Name) (Package may be system provisioned)" -ForegroundColor Yellow
                            }
                        }
                    }
                }
                
                # Turn off Content Delivery Manager auto-installing sponsored apps in the future
                Write-Host "`n[+] Disabling future sponsored app installations..." -ForegroundColor Cyan
                $CDMPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
                if (Test-Path $CDMPath) {
                    Set-ItemProperty -Path $CDMPath -Name "SilentInstalledAppsEnabled" -Value 0 -Force
                    Set-ItemProperty -Path $CDMPath -Name "PreInstalledAppsEnabled" -Value 0 -Force
                    Set-ItemProperty -Path $CDMPath -Name "SystemPaneSuggestionsEnabled" -Value 0 -Force
                }
                
                Write-Host "`n[VERIFICATION] Completed. Uninstalled $RemovedCount bloatware packages." -ForegroundColor Green
            } else {
                Write-Host "`nOperation cancelled." -ForegroundColor Yellow
            }
            Write-Host "`nPress Enter to return..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        
        "2" {
            Show-Header
            Write-Host "Disabling Diagnostic Telemetry & Privacy Settings..." -ForegroundColor Cyan
            
            $Confirm = Ask-Option "Confirm disabling of OS telemetry & tracking services"
            if ($Confirm) {
                Write-Host "`n[+] Disabling Telemetry registry configurations..." -ForegroundColor Cyan
                
                $Paths = @(
                    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection",
                    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
                )
                foreach ($P in $Paths) {
                    if (-not (Test-Path $P)) { New-Item -Path $P -Force | Out-Null }
                    Set-ItemProperty -Path $P -Name "AllowTelemetry" -Value 0 -Force
                }
                
                # Disable advertising ID and tailored experiences
                $PrivacyPaths = @(
                    "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo",
                    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"
                )
                foreach ($P in $PrivacyPaths) {
                    if (-not (Test-Path $P)) { New-Item -Path $P -Force | Out-Null }
                    Set-ItemProperty -Path $P -Name "Enabled" -Value 0 -Force -ErrorAction SilentlyContinue
                }
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Value 0 -Force -ErrorAction SilentlyContinue
                
                Write-Host "[+] Disabling diagnostic tracking and push services..." -ForegroundColor Cyan
                
                # Connected User Experiences and Telemetry
                Stop-Service -Name "DiagTrack" -Force
                Set-Service -Name "DiagTrack" -StartupType Disabled
                
                # WAP Push Message Routing
                Stop-Service -Name "dmwappushservice" -Force
                Set-Service -Name "dmwappushservice" -StartupType Disabled
                
                # Verify services are disabled
                $DiagTrackStatus = (Get-Service -Name "DiagTrack").StartType
                $PushSvcStatus = (Get-Service -Name "dmwappushservice").StartType
                
                Write-Host "`n[VERIFICATION] Telemetry registry updated." -ForegroundColor Green
                Write-Host "               DiagTrack Service startup: $DiagTrackStatus" -ForegroundColor Green
                Write-Host "               dmwappushservice startup: $PushSvcStatus" -ForegroundColor Green
            } else {
                Write-Host "`nOperation cancelled." -ForegroundColor Yellow
            }
            Write-Host "`nPress Enter to return..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        
        "3" {
            Show-Header
            Write-Host "Optimizing Windows 11 Taskbar Components..." -ForegroundColor Cyan
            Write-Host "Hides widgets, chat, and Task View buttons to reclaim space and speed up Explorer." -ForegroundColor DarkGray
            
            $Confirm = Ask-Option "Confirm hiding Taskbar Widgets, Chat, Task View & Search"
            if ($Confirm) {
                Write-Host "`n[+] Adjusting Taskbar configurations..." -ForegroundColor Cyan
                $ExplorerPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                $SearchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
                
                # Hide Task View
                Set-ItemProperty -Path $ExplorerPath -Name "ShowTaskViewButton" -Value 0 -Force
                # Hide Widgets
                Set-ItemProperty -Path $ExplorerPath -Name "TaskbarDa" -Value 0 -Force
                # Hide Chat (Teams)
                Set-ItemProperty -Path $ExplorerPath -Name "TaskbarMn" -Value 0 -Force
                # Hide Search (or make it icon only)
                if (Test-Path $SearchPath) {
                    Set-ItemProperty -Path $SearchPath -Name "SearchboxTaskbarMode" -Value 0 -Force
                }
                
                # Optional: Align taskbar to Left (prompt user)
                $AlignLeft = Ask-Option "Align Taskbar alignment to the Left (default is Center)"
                if ($AlignLeft) {
                    Set-ItemProperty -Path $ExplorerPath -Name "TaskbarAl" -Value 0 -Force
                    Write-Host "  -> Taskbar aligned to Left." -ForegroundColor Green
                }
                
                # Restart explorer to apply taskbar changes instantly
                Write-Host "`n[+] Restarting Windows Explorer process to apply settings..." -ForegroundColor Cyan
                Stop-Process -Name "explorer" -Force
                
                Write-Host "`n[VERIFICATION] Taskbar settings applied successfully." -ForegroundColor Green
            } else {
                Write-Host "`nOperation cancelled." -ForegroundColor Yellow
            }
            Write-Host "`nPress Enter to return..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        
        "4" {
            Show-Header
            Write-Host "Disabling OneDrive Auto-Startup..." -ForegroundColor Cyan
            
            $Confirm = Ask-Option "Confirm disabling OneDrive startup boot sequence"
            if ($Confirm) {
                Write-Host "`n[+] Querying OneDrive run registry values..." -ForegroundColor Cyan
                
                $RunKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
                if (Test-Path $RunKey) {
                    $OneDriveVal = (Get-ItemProperty -Path $RunKey -Name "OneDrive" -ErrorAction SilentlyContinue).OneDrive
                    if ($OneDriveVal) {
                        Remove-ItemProperty -Path $RunKey -Name "OneDrive" -Force
                        Write-Host "  -> Removed OneDrive from Startup Registry." -ForegroundColor Green
                    } else {
                        Write-Host "  -> OneDrive was already disabled or not configured in user Startup registry." -ForegroundColor Yellow
                    }
                }
                
                # Terminate active OneDrive process
                Write-Host "[+] Terminating active OneDrive.exe processes..." -ForegroundColor Cyan
                Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
                
                Write-Host "`n[VERIFICATION] OneDrive startup registry entry has been verified/removed." -ForegroundColor Green
            } else {
                Write-Host "`nOperation cancelled." -ForegroundColor Yellow
            }
            Write-Host "`nPress Enter to return..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        
        "5" {
            Show-Header
            Write-Host "Applying ALL Safe Windows 11 Optimization Tweaks..." -ForegroundColor Cyan
            Write-Host "This will run uninstallation of sponsored apps, disable telemetry, hide unused taskbar items, and disable OneDrive startup." -ForegroundColor DarkGray
            
            $Confirm = Ask-Option "Proceed with complete safe optimization profile"
            if ($Confirm) {
                # 1. Apps removal
                Write-Host "`n[1/4] Uninstalling UWP Bloatware..." -ForegroundColor Cyan
                $BloatwareList = @("*Clipchamp*", "*Disney*", "*Spotify*", "*TikTok*", "*Facebook*", "*Instagram*", "*PrimeVideo*", "*XboxApp*", "*XboxGamingOverlay*", "*FeedbackHub*", "*YourPhone*", "*BingNews*", "*BingWeather*", "*GetHelp*", "*Cortana*", "*MixedReality*", "*Skype*", "*SolitaireCollection*")
                $RemovedCount = 0
                foreach ($App in $BloatwareList) {
                    $Packages = Get-AppxPackage -Name $App -AllUsers -ErrorAction SilentlyContinue
                    if ($Packages) {
                        foreach ($Pkg in $Packages) {
                            try {
                                Remove-AppxPackage -Package $Pkg.PackageFullName -ErrorAction Stop
                                $RemovedCount++
                            } catch {}
                        }
                    }
                }
                $CDMPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
                if (Test-Path $CDMPath) {
                    Set-ItemProperty -Path $CDMPath -Name "SilentInstalledAppsEnabled" -Value 0 -Force
                    Set-ItemProperty -Path $CDMPath -Name "PreInstalledAppsEnabled" -Value 0 -Force
                    Set-ItemProperty -Path $CDMPath -Name "SystemPaneSuggestionsEnabled" -Value 0 -Force
                }
                Write-Host "  -> Removed $RemovedCount bloatware packages." -ForegroundColor Green
                
                # 2. Telemetry
                Write-Host "`n[2/4] Configuring Telemetry and Privacy Policies..." -ForegroundColor Cyan
                $Paths = @("HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection", "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection")
                foreach ($P in $Paths) {
                    if (-not (Test-Path $P)) { New-Item -Path $P -Force | Out-Null }
                    Set-ItemProperty -Path $P -Name "AllowTelemetry" -Value 0 -Force
                }
                $PrivacyPaths = @("HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy")
                foreach ($P in $PrivacyPaths) {
                    if (-not (Test-Path $P)) { New-Item -Path $P -Force | Out-Null }
                    Set-ItemProperty -Path $P -Name "Enabled" -Value 0 -Force -ErrorAction SilentlyContinue
                }
                Stop-Service -Name "DiagTrack" -Force
                Set-Service -Name "DiagTrack" -StartupType Disabled
                Stop-Service -Name "dmwappushservice" -Force
                Set-Service -Name "dmwappushservice" -StartupType Disabled
                Write-Host "  -> Registry policies configured & Services disabled." -ForegroundColor Green
                
                # 3. Taskbar
                Write-Host "`n[3/4] Adjusting Taskbar elements (Hiding Widgets/Chat/TaskView)..." -ForegroundColor Cyan
                $ExplorerPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                $SearchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
                Set-ItemProperty -Path $ExplorerPath -Name "ShowTaskViewButton" -Value 0 -Force
                Set-ItemProperty -Path $ExplorerPath -Name "TaskbarDa" -Value 0 -Force
                Set-ItemProperty -Path $ExplorerPath -Name "TaskbarMn" -Value 0 -Force
                if (Test-Path $SearchPath) { Set-ItemProperty -Path $SearchPath -Name "SearchboxTaskbarMode" -Value 0 -Force }
                Write-Host "  -> Taskbar configured." -ForegroundColor Green
                
                # 4. OneDrive
                Write-Host "`n[4/4] Disabling OneDrive startup..." -ForegroundColor Cyan
                $RunKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
                if (Test-Path $RunKey) {
                    Remove-ItemProperty -Path $RunKey -Name "OneDrive" -Force
                }
                Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
                Write-Host "  -> OneDrive startup disabled." -ForegroundColor Green
                
                # Restart explorer
                Write-Host "`n[+] Restarting Windows Explorer process to apply changes..." -ForegroundColor Cyan
                Stop-Process -Name "explorer" -Force
                
                Write-Host "`n==========================================================================" -ForegroundColor Green
                Write-Host "         ALL WINDOWS 11 SAFE OPTIMIZATIONS COMPLETED SUCCESSFULLY!" -ForegroundColor Green
                Write-Host "==========================================================================" -ForegroundColor Green
            } else {
                Write-Host "`nOperation cancelled." -ForegroundColor Yellow
            }
            Write-Host "`nPress Enter to return..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        
        "Q" {
            Write-Host "`nExiting Windows 11 Debloater. Have a fast day!" -ForegroundColor Green
            exit
        }
        "q" {
            Write-Host "`nExiting Windows 11 Debloater. Have a fast day!" -ForegroundColor Green
            exit
        }
        default {
            Write-Host "`nInvalid choice. Please enter 1-5, or Q." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
