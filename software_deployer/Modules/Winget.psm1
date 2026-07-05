# ==============================================================================
# MODULE: Winget.psm1
# PURPOSE: Handles Winget availability checks, fast bulk list caching, silent
#          package installations, and automated upgrades without UI hanging.
# ==============================================================================

<#
.SYNOPSIS
    Checks whether Microsoft Winget package manager is installed and accessible.
.OUTPUTS
    Boolean: $true if Winget is found, $false otherwise.
#>
function Test-WingetAvailable {
    $wingetCmd = Get-Command -Name "winget.exe", "winget" -ErrorAction SilentlyContinue
    if ($wingetCmd) {
        Write-Log -Message "Winget package manager detected at: $($wingetCmd[0].Source)" -Level "INFO"
        return $true
    } else {
        Write-Log -Message "Winget package manager (winget.exe) was not found on this system." -Level "ERROR"
        return $false
    }
}

<#
.SYNOPSIS
    Performs a single bulk query of all installed Winget packages to build a fast
    in-memory lookup cache, avoiding slow per-app SQLite database queries.
.OUTPUTS
    Hashtable where keys are Package IDs or lowercase application names, and values are $true.
#>
function Get-InstalledWingetPackages {
    Write-Log -Message "Scanning system for installed software packages via Winget..." -Level "INFO"
    $cache = @{}

    try {
        # Run winget list once in background without interactive prompts
        $proc = Start-Process -FilePath "winget.exe" -ArgumentList @("list", "--accept-source-agreements", "--disable-interactivity") -WindowStyle Minimized -PassThru -NoNewWindow -RedirectStandardOutput (Join-Path $env:TEMP "winget_list.txt") -ErrorAction SilentlyContinue
        if ($proc) {
            $proc | Wait-Process -Timeout 30 -ErrorAction SilentlyContinue
        }

        $listFile = Join-Path $env:TEMP "winget_list.txt"
        if (Test-Path $listFile) {
            $lines = Get-Content -Path $listFile -ErrorAction SilentlyContinue
            foreach ($line in $lines) {
                # Match typical winget list output where ID contains a dot (e.g. Google.Chrome, 7zip.7zip)
                if ($line -match "([a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+)") {
                    $pkgId = $matches[1].Trim()
                    $cache[$pkgId.ToLower()] = $true
                }
                # Also index the lowercase line text for fuzzy display name matching
                $cleanName = $line.Split(" ")[0].Trim().ToLower()
                if ($cleanName.Length -gt 2) {
                    $cache[$cleanName] = $true
                }
            }
            Remove-Item -Path $listFile -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Log -Message "Warning during Winget list query: $_" -Level "WARN"
    }

    # Fallback/Enhancement: Check Windows Registry Uninstall hives for bulletproof detection
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach ($path in $regPaths) {
        if (Test-Path $path) {
            Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_.DisplayName) {
                    $cache[$_.DisplayName.ToLower()] = $true
                    # Also extract simple brand name
                    $shortName = $_.DisplayName.Split(" ")[0].ToLower()
                    if ($shortName.Length -gt 2) { $cache[$shortName] = $true }
                }
            }
        }
    }

    Write-Log -Message "Built installed package cache with $($cache.Count) unique software identifiers." -Level "INFO"
    return $cache
}

<#
.SYNOPSIS
    Checks whether a specific application ID or name is present in the installed cache.
#>
function Test-WingetPackageInstalled {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][hashtable]$InstalledCache
    )

    $idLower = $Id.ToLower()
    $nameLower = $Name.ToLower()
    $shortName = $Name.Split(" ")[0].ToLower()

    if ($InstalledCache.ContainsKey($idLower)) { return $true }
    if ($InstalledCache.ContainsKey($nameLower)) { return $true }
    
    # Check if any cached registry display name contains the target name
    foreach ($key in $InstalledCache.Keys) {
        if ($key -like "*$nameLower*" -or ($shortName.Length -gt 3 -and $key -like "*$shortName*")) {
            return $true
        }
    }

    return $false
}

<#
.SYNOPSIS
    Executes a silent installation for a specific Winget package ID.
    Uses non-interactive flags and direct process invocation to prevent hangs.
.OUTPUTS
    PSCustomObject with properties: Success (bool), ExitCode (int), ErrorMessage (string).
#>
function Install-WingetPackage {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $false)][scriptblock]$GuiProgressCallback = $null
    )

    Write-Log -Message "Starting silent installation for: $Name ($Id)" -Level "START"

    # Ensure no lingering package manager locks from previous runs
    Stop-Process -Name "winget", "WindowsPackageManagerServer" -Force -ErrorAction SilentlyContinue

    $argsList = @(
        "install",
        "--id", $Id,
        "--exact",
        "--silent",
        "--accept-package-agreements",
        "--accept-source-agreements",
        "--scope", "machine",
        "--disable-interactivity",
        "--no-upgrade",
        "--ignore-security-hash",
        "--ignore-warnings",
        "--authentication-mode", "silent"
    )

    $startTime = Get-Date
    try {
        # Directly invoke winget.exe (no cmd.exe wrapper) with Minimized window to prevent console buffer deadlocks
        $proc = Start-Process -FilePath "winget.exe" -ArgumentList $argsList -WindowStyle Minimized -PassThru -ErrorAction SilentlyContinue
        
        if ($proc) {
            [int]$timeoutSec = 300
            [double]$elapsed = 0
            while (-not $proc.HasExited -and $elapsed -lt $timeoutSec) {
                Start-Sleep -Milliseconds 500
                $elapsed += 0.5
                
                # Keep WPF UI responsive during installation loop
                if ($GuiProgressCallback) { & $GuiProgressCallback }
            }

            if (-not $proc.HasExited) {
                $proc | Stop-Process -Force -ErrorAction SilentlyContinue
                Stop-Process -Name "winget", "WindowsPackageManagerServer" -Force -ErrorAction SilentlyContinue
                Write-Log -Message "Installation of $Name timed out after 300 seconds." -Level "ERROR"
                return [PSCustomObject]@{ Success = $false; ExitCode = -1; ErrorMessage = "Timed out after 300s" }
            }

            $code = $proc.ExitCode
            # Standard Winget & Windows installer success codes:
            # 0: Success | 1641 / 3010: Reboot initiated/required | -1978335189 / -1978335212 / 2316632075: Winget OK
            if ($code -eq 0 -or $code -eq 1641 -or $code -eq 3010 -or $code -eq -1978335189 -or $code -eq -1978335212 -or $code -eq 2316632075) {
                $duration = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
                Write-Log -Message "Successfully installed $Name in ${duration}s (Exit Code: $code)" -Level "SUCCESS"
                return [PSCustomObject]@{ Success = $true; ExitCode = $code; ErrorMessage = "" }
            } else {
                Write-Log -Message "Failed to install $Name. Winget exit code: $code" -Level "ERROR"
                return [PSCustomObject]@{ Success = $false; ExitCode = $code; ErrorMessage = "Exit code $code" }
            }
        } else {
            Write-Log -Message "Failed to spawn winget.exe process for $Name." -Level "ERROR"
            return [PSCustomObject]@{ Success = $false; ExitCode = -2; ErrorMessage = "Failed to launch process" }
        }
    } catch {
        Write-Log -Message "Exception during installation of ${Name}: $_" -Level "ERROR"
        return [PSCustomObject]@{ Success = $false; ExitCode = -3; ErrorMessage = $_.Exception.Message }
    }
}

<#
.SYNOPSIS
    Executes a bulk upgrade of all installed applications using Winget upgrade --all.
#>
function Update-WingetPackages {
    param(
        [Parameter(Mandatory = $false)][scriptblock]$GuiProgressCallback = $null
    )

    Write-Log -Message "Starting system-wide upgrade for all installed applications..." -Level "START"
    Stop-Process -Name "winget", "WindowsPackageManagerServer" -Force -ErrorAction SilentlyContinue

    $argsList = @(
        "upgrade",
        "--all",
        "--silent",
        "--accept-package-agreements",
        "--accept-source-agreements",
        "--disable-interactivity",
        "--ignore-security-hash",
        "--ignore-warnings",
        "--authentication-mode", "silent"
    )

    $startTime = Get-Date
    try {
        $proc = Start-Process -FilePath "winget.exe" -ArgumentList $argsList -WindowStyle Minimized -PassThru -ErrorAction SilentlyContinue
        if ($proc) {
            [int]$timeoutSec = 600
            [double]$elapsed = 0
            while (-not $proc.HasExited -and $elapsed -lt $timeoutSec) {
                Start-Sleep -Milliseconds 500
                $elapsed += 0.5
                if ($GuiProgressCallback) { & $GuiProgressCallback }
            }

            if (-not $proc.HasExited) {
                $proc | Stop-Process -Force -ErrorAction SilentlyContinue
                Stop-Process -Name "winget", "WindowsPackageManagerServer" -Force -ErrorAction SilentlyContinue
                Write-Log -Message "Upgrade operation timed out after 10 minutes." -Level "ERROR"
                return $false
            }

            $duration = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
            Write-Log -Message "System-wide upgrade completed in ${duration}s (Exit Code: $($proc.ExitCode))" -Level "SUCCESS"
            return $true
        }
    } catch {
        Write-Log -Message "Exception during upgrade operation: $_" -Level "ERROR"
        return $false
    }
}

Export-ModuleMember -Function Test-WingetAvailable, Get-InstalledWingetPackages, Test-WingetPackageInstalled, Install-WingetPackage, Update-WingetPackages
