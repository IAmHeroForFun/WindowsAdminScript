# Diagnostics: Checks for VC++ redistributables and .NET Framework versions
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

if (-not (Get-UserApproval "Verify system dependencies (.NET, VC++ Runtimes, and Installer)?")) {
    Log-Msg "Dependency checks skipped by user." "WARN"
    return 0
}

Log-Msg "Starting dependency check..."

# 1. Check .NET versions
Log-Msg "Auditing installed .NET Framework versions..."
$DotNetReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -Name Release -ErrorAction SilentlyContinue
$DotNetVersion = "Unknown"
if ($DotNetReg) {
    $Release = $DotNetReg.Release
    if ($Release -ge 528040) { $DotNetVersion = "4.8.1" }
    elseif ($Release -ge 461808) { $DotNetVersion = "4.7.2" }
    elseif ($Release -ge 460798) { $DotNetVersion = "4.7" }
    elseif ($Release -ge 394802) { $DotNetVersion = "4.6.2" }
    elseif ($Release -ge 393295) { $DotNetVersion = "4.6" }
    elseif ($Release -ge 379893) { $DotNetVersion = "4.5.2" }
    elseif ($Release -ge 378675) { $DotNetVersion = "4.5.1" }
    elseif ($Release -ge 378389) { $DotNetVersion = "4.5" }
}
Log-Msg "Detected .NET Framework: $DotNetVersion"

# 2. Check VC++ Runtimes
Log-Msg "Auditing Visual C++ Redistributables..."
$VCRedists = @(
    @{ Name = "VC++ 2010 x86"; Path = "HKLM:\SOFTWARE\Microsoft\VisualStudio\10.0\VC\VCRedist\x86" }
    @{ Name = "VC++ 2010 x64"; Path = "HKLM:\SOFTWARE\Microsoft\VisualStudio\10.0\VC\VCRedist\x64" }
    @{ Name = "VC++ 2012 x86"; Path = "HKLM:\SOFTWARE\Microsoft\VisualStudio\11.0\VC\VCRedist\x86" }
    @{ Name = "VC++ 2012 x64"; Path = "HKLM:\SOFTWARE\Microsoft\VisualStudio\11.0\VC\VCRedist\x64" }
    @{ Name = "VC++ 2013 x86"; Path = "HKLM:\SOFTWARE\Microsoft\VisualStudio\12.0\VC\VCRedist\x86" }
    @{ Name = "VC++ 2013 x64"; Path = "HKLM:\SOFTWARE\Microsoft\VisualStudio\12.0\VC\VCRedist\x64" }
    @{ Name = "VC++ 2015-2022 x86"; Path = "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\VCRedist\x86" }
    @{ Name = "VC++ 2015-2022 x64"; Path = "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\VCRedist\x64" }
)

$MissingRedists = @()
foreach ($Redist in $VCRedists) {
    $Reg = Get-ItemProperty -Path $Redist.Path -Name Installed -ErrorAction SilentlyContinue
    if ($Reg -and $Reg.Installed -eq 1) {
        Log-Msg "  [OK] $($Redist.Name) is installed."
    } else {
        Log-Msg "  [MISSING] $($Redist.Name)" "WARN"
        $MissingRedists += $Redist.Name
    }
}

# 3. Check Windows Installer version
$MsiVersion = "Unknown"
try {
    $MsiDll = Get-Item "C:\Windows\System32\msi.dll" -ErrorAction SilentlyContinue
    if ($MsiDll) { $MsiVersion = $MsiDll.VersionInfo.ProductVersion }
} catch {}
Log-Msg "Windows Installer Version: $MsiVersion"

# 4. Check SP1 updates
Log-Msg "Checking for installed SP1/critical hotfixes..."
$Sp1Installed = $false
try {
    $KB = Get-HotFix -Id "KB2817430" -ErrorAction SilentlyContinue
    if ($KB) { $Sp1Installed = $true }
} catch {}

if ($Sp1Installed) {
    Log-Msg "Office 2013 Service Pack 1 / Hotfix KB2817430 detected."
} else {
    Log-Msg "Hotfix KB2817430 (SP1 equivalent) not explicitly found in Windows HotFix list." "WARN"
}

# Output report data
$Global:DependencyReport = [PSCustomObject]@{
    DotNetVersion  = $DotNetVersion
    MissingRedists = ($MissingRedists -join ", ")
    MsiVersion     = $MsiVersion
    Sp1Installed   = $Sp1Installed
}

Log-Msg "Dependency checks completed."
return 0
