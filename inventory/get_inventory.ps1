# PowerShell System Inventory Script
# Compatible with Windows 7 (PowerShell 2.0) through Windows 11 (PowerShell 5.1 & 7+)
# Consolidates hardware information into 'inventory.csv' (updates or appends)
# Exports detailed installed software to 'installed_software\<ComputerName>_software.txt'

$ErrorActionPreference = "Stop"

# Try to bypass Execution Policy for the current session/process
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
} catch {}

# 0. Ensure $PSScriptRoot is defined for PowerShell 2.0 compatibility
if (-not $PSScriptRoot) {
    if ($MyInvocation.MyCommand.Definition) {
        $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    } else {
        $PSScriptRoot = Get-Location | Select-Object -ExpandProperty Path
    }
}

# Centralized report directory handling
$ReportsDir = $null
$ParentDir = Split-Path -Parent -Path $PSScriptRoot
if ($ParentDir -match "SysMaster") {
    $ReportsDir = Join-Path $ParentDir "reports"
} else {
    $ReportsDir = $PSScriptRoot
}
if (-not (Test-Path $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null
}

$CsvPath = Join-Path -Path $ReportsDir -ChildPath "inventory.csv"
$SoftwareDir = Join-Path -Path $ReportsDir -ChildPath "installed_software"
$BackupDir = Join-Path -Path $ReportsDir -ChildPath "backups"

# Ensure software and backup directories exist
if (-not (Test-Path $SoftwareDir)) {
    New-Item -ItemType Directory -Path $SoftwareDir -Force | Out-Null
}
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}
$SoftwareFilePath = Join-Path -Path $SoftwareDir -ChildPath "$($env:COMPUTERNAME)_software.txt"

# Create backup of existing inventory file before running scan
if (Test-Path $CsvPath) {
    $Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $BackupFile = Join-Path -Path $BackupDir -ChildPath "inventory_backup_$Timestamp.csv"
    Copy-Item -Path $CsvPath -Destination $BackupFile -Force
    Write-Host "Created backup of existing inventory: backups\inventory_backup_$Timestamp.csv" -ForegroundColor Green
}

Write-Host "Gathering system specifications..." -ForegroundColor Cyan

# Helper function to query WMI/CIM across PowerShell 2.0 (Win 7) through PowerShell 7+ (Win 11)
function Get-WmiData {
    param(
        [string]$Class,
        [string]$Namespace = "root\cimv2",
        [string]$Filter = $null
    )
    if (Get-Command Get-WmiObject -ErrorAction SilentlyContinue) {
        if ($Filter) {
            Get-WmiObject -Namespace $Namespace -Class $Class -Filter $Filter -ErrorAction Stop
        } else {
            Get-WmiObject -Namespace $Namespace -Class $Class -ErrorAction Stop
        }
    } elseif (Get-Command Get-CimInstance -ErrorAction SilentlyContinue) {
        if ($Filter) {
            Get-CimInstance -Namespace $Namespace -ClassName $Class -Filter $Filter -ErrorAction Stop
        } else {
            Get-CimInstance -Namespace $Namespace -ClassName $Class -ErrorAction Stop
        }
    }
}

# Helper function to strip newlines and carriage returns to prevent CSV row splitting/corruption
function Clean-String($str) {
    if ($null -eq $str) { return "N/A" }
    $s = ([string]$str) -replace '[\r\n]+', ' ' -replace '\s+', ' '
    return $s.Trim()
}

# 2. Gather Device Type (Desktop or Laptop)
$DeviceType = "Unknown"
try {
    $Chassis = Get-WmiData -Class "Win32_SystemEnclosure"
    if ($Chassis) {
        $ChassisType = @(@($Chassis)[0].ChassisTypes)[0]
        # Chassis codes: 8, 9, 10, 11, 12, 14, 18, 21, 30, 31, 32 are portable/laptops
        # Chassis codes: 3, 4, 5, 6, 7, 13, 15, 16, 17 are desktop/towers
        if (@(8, 9, 10, 11, 12, 14, 18, 21, 30, 31, 32) -contains $ChassisType) {
            $DeviceType = "Laptop"
        } elseif (@(3, 4, 5, 6, 7, 13, 15, 16, 17) -contains $ChassisType) {
            $DeviceType = "Desktop"
        } elseif ($ChassisType -eq 23) {
            $DeviceType = "Server"
        } else {
            $DeviceType = "Other / Unknown"
        }
    }
} catch {
    $DeviceType = "Unknown"
}

# 3. Gather Identity & Operating System Info
try {
    $OS = Get-WmiData -Class "Win32_OperatingSystem"
    $OSName = Clean-String $OS.Caption
    $OSVersion = Clean-String $OS.Version
    $OSArchitecture = Clean-String $OS.OSArchitecture
    if ($OSArchitecture -eq "N/A" -or -not $OSArchitecture) {
        if ([IntPtr]::Size -eq 8) { $OSArchitecture = "64-bit" } else { $OSArchitecture = "32-bit" }
    }
} catch {
    $OSName = "Unknown Windows OS"
    $OSVersion = "N/A"
    $OSArchitecture = "N/A"
}

# 4. Gather Hardware System Specs (Model, Serial, CPU, RAM)
try {
    $CS = Get-WmiData -Class "Win32_ComputerSystem"
    $Manufacturer = Clean-String $CS.Manufacturer
    $Model = Clean-String $CS.Model
    $TotalRamBytes = $CS.TotalPhysicalMemory
    $TotalRamGB = [Math]::Round($TotalRamBytes / 1GB, 2)
    
    $Domain = Clean-String $CS.Domain
    $PartOfDomain = $CS.PartOfDomain
    $DomainStatus = if ($PartOfDomain) { "Domain: $Domain" } else { "Workgroup: $Domain" }
} catch {
    $Manufacturer = "Unknown"
    $Model = "Unknown"
    $TotalRamGB = "N/A"
    $DomainStatus = "Unknown"
}

# RAM Slots Used out of Total Slots
$RamSlots = "Unknown"
try {
    $Sticks = @(Get-WmiData -Class "Win32_PhysicalMemory")
    $UsedSlots = $Sticks.Count
    $Array = Get-WmiData -Class "Win32_PhysicalMemoryArray"
    $TotalSlots = if ($Array) { ($Array | Measure-Object -Property MemoryDevices -Sum).Sum } else { 0 }
    
    if ($UsedSlots -gt 0 -and $TotalSlots -gt 0) {
        $RamSlots = "$UsedSlots of $TotalSlots slots used"
    } else {
        $RamSlots = "N/A"
    }
} catch {
    $RamSlots = "Unknown"
}

try {
    $Bios = Get-WmiData -Class "Win32_Bios"
    $SerialNumber = Clean-String $Bios.SerialNumber
} catch {
    $SerialNumber = "N/A"
}

try {
    $CPUs = @(Get-WmiData -Class "Win32_Processor")
    $CPUNames = New-Object System.Collections.ArrayList
    foreach ($C in $CPUs) {
        if ($C.Name) {
            $CleanName = Clean-String $C.Name
            if (-not $CPUNames.Contains($CleanName)) {
                [void]$CPUNames.Add($CleanName)
            }
        }
    }
    $CPUName = ($CPUNames -join " + ")
    if (-not $CPUName) { $CPUName = "Unknown CPU" }
} catch {
    $CPUName = "Unknown CPU"
}

# 5. Gather Storage Size & Health Status (SSD / HDD)
$DiskInfo = ""
try {
    # Attempt Storage API first (Windows 8/10/11)
    $Disks = Get-WmiData -Namespace "root\Microsoft\Windows\Storage" -Class "MSFT_PhysicalDisk"
    if ($Disks) {
        $DiskParts = New-Object System.Collections.ArrayList
        foreach ($D in @($Disks)) {
            $Type = switch ($D.MediaType) {
                3 { "HDD" }
                4 { "SSD" }
                5 { "SCM" }
                default { "Unspecified" }
            }
            $Health = switch ($D.HealthStatus) {
                0 { "Healthy" }
                1 { "Warning" }
                2 { "Unhealthy" }
                default { "Unknown" }
            }
            $SizeGB = [Math]::Round($D.Size / 1GB, 1)
            [void]$DiskParts.Add("[$Type] $(Clean-String $D.FriendlyName) ($SizeGB GB): $Health")
        }
        $DiskInfo = ($DiskParts -join " | ")
    }
} catch { }

if (-not $DiskInfo) {
    # Fallback to Win32_DiskDrive (Windows 7 compatibility)
    try {
        $Disks = Get-WmiData -Class "Win32_DiskDrive"
        if ($Disks) {
            $DiskParts = New-Object System.Collections.ArrayList
            foreach ($D in @($Disks)) {
                $SizeGB = [Math]::Round($D.Size / 1GB, 1)
                $Health = Clean-String $D.Status # Reports SMART status (e.g. "OK")
                [void]$DiskParts.Add("[Drive] $(Clean-String $D.Model) ($SizeGB GB) - SMART: $Health")
            }
            $DiskInfo = ($DiskParts -join " | ")
        }
    } catch {
        $DiskInfo = "Unknown Drive Info"
    }
}

# Gather C: Partition Space details
try {
    $Disk = Get-WmiData -Class "Win32_LogicalDisk" -Filter "DeviceID='C:'"
    $DiskSizeGB = [Math]::Round($Disk.Size / 1GB, 2)
    $DiskFreeGB = [Math]::Round($Disk.FreeSpace / 1GB, 2)
} catch {
    $DiskSizeGB = "N/A"
    $DiskFreeGB = "N/A"
}

# 6. Gather Battery Health & Status Details
$BatteryInfo = "N/A (No Battery)"
try {
    $Batteries = Get-WmiData -Class "Win32_Battery"
    if ($Batteries) {
        $BatParts = New-Object System.Collections.ArrayList
        foreach ($B in @($Batteries)) {
            $Charge = $B.EstimatedChargeRemaining
            $Design = $B.DesignCapacity
            $Full = $B.FullChargeCapacity
            
            if ($Design -gt 0 -and $Full -gt 0) {
                $HealthPct = [Math]::Round(($Full / $Design) * 100, 1)
                $HealthStr = "Health: $HealthPct%"
            } else {
                $HealthStr = "Health: Unknown"
            }
            $Status = $B.Status
            [void]$BatParts.Add("Charge: $Charge% | $HealthStr | Status: $Status")
        }
        $BatteryInfo = ($BatParts -join " | ")
    }
} catch {
    $BatteryInfo = "Error Querying Battery"
}

# 7. Gather Network Info (IP & MAC Address)
try {
    $Network = @(Get-WmiData -Class "Win32_NetworkAdapterConfiguration" -Filter "IPEnabled=True")[0]
    $IPAddress = if ($Network) { Clean-String (@($Network.IPAddress)[0]) } else { "N/A" }
    $MACAddress = if ($Network) { Clean-String $Network.MACAddress } else { "N/A" }
} catch {
    $IPAddress = "N/A"
    $MACAddress = "N/A"
}

# 8. Gather Installed Software (Needed for Microsoft Office check & detailed export)
$RegPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$InstalledApps = @(Get-ItemProperty $RegPaths -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -and $_.SystemComponent -ne 1 -and $_.ParentKeyName -eq $null } |
    Select-Object DisplayName, DisplayVersion, Publisher |
    Sort-Object DisplayName)

# Filter and detect Microsoft Office details
$OfficeInfo = "Not Found"
try {
    $OfficeApps = @($InstalledApps | Where-Object { 
        ($_.DisplayName -like "*Microsoft Office*" -or $_.DisplayName -like "*Microsoft 365*" -or $_.DisplayName -like "*Office 16 Click-to-Run*") -and
        ($_.DisplayName -notlike "*Language Pack*") -and
        ($_.DisplayName -notlike "*Proofing Tools*") -and
        ($_.DisplayName -notlike "*Project*") -and
        ($_.DisplayName -notlike "*Visio*") -and
        ($_.DisplayName -notlike "*Access Runtime*")
    })
    if ($OfficeApps -and $OfficeApps.Count -gt 0) {
        $OfficeParts = New-Object System.Collections.ArrayList
        foreach ($App in $OfficeApps) {
            [void]$OfficeParts.Add("$(Clean-String $App.DisplayName) ($(Clean-String $App.DisplayVersion))")
        }
        $OfficeInfo = ($OfficeParts -join " | ")
    }
} catch {
    $OfficeInfo = "Error detecting Office"
}

# 9. Gather Antivirus Product & State Info
$AVInfo = "Not Found"
try {
    $AVProducts = Get-WmiData -Namespace "root\SecurityCenter2" -Class "AntiVirusProduct"
    if ($AVProducts) {
        $AVParts = New-Object System.Collections.ArrayList
        foreach ($AV in @($AVProducts)) {
            $StateInt = [int]$AV.productState
            $StateHex = "{0:X6}" -f $StateInt
            $MiddleByte = $StateHex.Substring(2, 2)
            $Status = switch ($MiddleByte) {
                "10" { "Active & Up-to-date" }
                "11" { "Active (Signature Out of Date)" }
                "00" { "Disabled" }
                "01" { "Inactive" }
                default { "Installed" }
            }
            [void]$AVParts.Add("$(Clean-String $AV.displayName) ($Status)")
        }
        if ($AVParts.Count -gt 0) {
            $AVInfo = ($AVParts -join " | ")
        }
    }
} catch { }

if ($AVInfo -eq "Not Found") {
    $DefenderService = Get-Service -Name "Windefend" -ErrorAction SilentlyContinue
    if ($DefenderService) {
        if ($DefenderService.Status -eq "Running") {
            $AVInfo = "Windows Defender (Active)"
        } else {
            $AVInfo = "Windows Defender (Stopped)"
        }
    } else {
        $AVInfo = "Standard / Not Detected"
    }
}

# 10. Define strict ordered columns to ensure Export-Csv never corrupts columns on PS 2.0
$EntryProps = @(
    @("Scan Date",            (Get-Date -Format "yyyy-MM-dd HH:mm:ss")),
    @("Computer Name",        (Clean-String $env:COMPUTERNAME)),
    @("Device Type",          (Clean-String $DeviceType)),
    @("Domain / Workgroup",   (Clean-String $DomainStatus)),
    @("IP Address",           (Clean-String $IPAddress)),
    @("Logged-in User",       (Clean-String "$env:USERDOMAIN\$env:USERNAME")),
    @("OS Version",           (Clean-String "$OSName ($OSVersion)")),
    @("RAM (GB)",             $TotalRamGB),
    @("RAM Slots Used",       (Clean-String $RamSlots)),
    @("Disk Health & Specs",  (Clean-String $DiskInfo)),
    @("Storage C: Size (GB)", $DiskSizeGB),
    @("Storage C: Free (GB)", $DiskFreeGB),
    @("Battery Health",       (Clean-String $BatteryInfo)),
    @("Microsoft Office",     (Clean-String $OfficeInfo)),
    @("Antivirus",            (Clean-String $AVInfo)),
    @("Manufacturer",         (Clean-String $Manufacturer)),
    @("Model",                (Clean-String $Model)),
    @("Serial Number",        (Clean-String $SerialNumber)),
    @("CPU",                  (Clean-String $CPUName)),
    @("MAC Address",          (Clean-String $MACAddress))
)

# Create PSObject with explicitly ordered NoteProperties compatible with PowerShell 2.0
$NewEntry = New-Object PSObject
foreach ($Prop in $EntryProps) {
    Add-Member -InputObject $NewEntry -MemberType NoteProperty -Name $Prop[0] -Value $Prop[1]
}

# 11. Save/Update CSV File on USB
Write-Host "Updating consolidated inventory.csv..." -ForegroundColor Cyan

$ExistingData = New-Object System.Collections.ArrayList
if (Test-Path $CsvPath) {
    $Imported = @(Import-Csv -Path $CsvPath -ErrorAction SilentlyContinue)
    if ($Imported) {
        foreach ($Row in $Imported) {
            # Normalize existing row columns to prevent Export-Csv schema corruption
            $CleanRow = New-Object PSObject
            foreach ($Prop in $EntryProps) {
                $ColName = $Prop[0]
                $Val = $Row.$ColName
                if ($null -eq $Val) { $Val = "Pending USB Scan" }
                Add-Member -InputObject $CleanRow -MemberType NoteProperty -Name $ColName -Value (Clean-String $Val)
            }
            [void]$ExistingData.Add($CleanRow)
        }
    }
    $MatchIndex = -1
    
    # Check if computer already exists in list (matching by Computer Name or Serial Number)
    for ($i = 0; $i -lt $ExistingData.Count; $i++) {
        $IsMatch = $false
        if ($ExistingData[$i]."Computer Name" -eq $env:COMPUTERNAME) {
            $IsMatch = $true
        } elseif ($SerialNumber -and $SerialNumber -ne "N/A" -and $SerialNumber -ne "To be filled by O.E.M." -and $ExistingData[$i]."Serial Number" -eq $SerialNumber) {
            $IsMatch = $true
        }
        
        if ($IsMatch) {
            $MatchIndex = $i
            break
        }
    }
    
    if ($MatchIndex -ge 0) {
        Write-Host "Computer already exists in inventory. Updating row..." -ForegroundColor Yellow
        $ExistingData[$MatchIndex] = $NewEntry
    } else {
        Write-Host "New computer detected. Appending row..." -ForegroundColor Green
        [void]$ExistingData.Add($NewEntry)
    }
} else {
    Write-Host "Creating new inventory.csv..." -ForegroundColor Green
    [void]$ExistingData.Add($NewEntry)
}

# Export using explicit encoding and Force to ensure clean CSV formatting
$ExistingData | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding utf8 -Force

# 12. Export Detailed Software list to text file
Write-Host "Exporting installed software details..." -ForegroundColor Cyan

$SoftwareReport = New-Object System.Collections.ArrayList
[void]$SoftwareReport.Add("==========================================================================")
[void]$SoftwareReport.Add("INSTALLED SOFTWARE INVENTORY FOR $($env:COMPUTERNAME)")
[void]$SoftwareReport.Add("Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$SoftwareReport.Add("User: $env:USERNAME")
[void]$SoftwareReport.Add("==========================================================================")
[void]$SoftwareReport.Add("")
[void]$SoftwareReport.Add([String]::Format("{0,-65} | {1,-20} | {2,-30}", "Application Name", "Version", "Publisher"))
[void]$SoftwareReport.Add("-" * 121)

foreach ($App in $InstalledApps) {
    $Name = Clean-String $App.DisplayName
    $Version = if ($App.DisplayVersion) { Clean-String $App.DisplayVersion } else { "N/A" }
    $Publisher = if ($App.Publisher) { Clean-String $App.Publisher } else { "N/A" }
    
    if ($Name.Length -gt 63) { $Name = $Name.Substring(0, 60) + "..." }
    if ($Version.Length -gt 18) { $Version = $Version.Substring(0, 15) + "..." }
    if ($Publisher.Length -gt 28) { $Publisher = $Publisher.Substring(0, 25) + "..." }
    
    [void]$SoftwareReport.Add([String]::Format("{0,-65} | {1,-20} | {2,-30}", $Name, $Version, $Publisher))
}

$SoftwareReport | Out-File -FilePath $SoftwareFilePath -Encoding utf8 -Force
Write-Host "Software list exported to 'installed_software\$($env:COMPUTERNAME)_software.txt'" -ForegroundColor Green

# 13. Show Graphical Complete Dialog
try {
    Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
    $Message = "Inventory completed successfully for computer: `n'$($env:COMPUTERNAME)'`n`nHardware specifications added/updated in 'inventory.csv'`n`nDetailed software list written to: 'installed_software\$($env:COMPUTERNAME)_software.txt'"
    [System.Windows.MessageBox]::Show($Message, "Inventory Completed", "OK", "Information") | Out-Null
} catch {
    Write-Host "Inventory completed successfully!" -ForegroundColor Green
}

