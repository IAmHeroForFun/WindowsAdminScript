# PowerShell Remote Network Inventory Script
# Compatible with Windows 7 (PowerShell 2.0) through Windows 11 (PowerShell 5.1 & 7+)
# Scans the network and remotely gathers hardware and software inventory from online PCs over WMI/DCOM.

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

if (-not (Test-Path $SoftwareDir)) { New-Item -ItemType Directory -Path $SoftwareDir -Force | Out-Null }
if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }

# Create backup of existing inventory file before running remote scan
if (Test-Path $CsvPath) {
    $Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $BackupFile = Join-Path -Path $BackupDir -ChildPath "inventory_backup_$Timestamp.csv"
    Copy-Item -Path $CsvPath -Destination $BackupFile -Force
    Write-Host "Created backup of existing inventory: backups\inventory_backup_$Timestamp.csv" -ForegroundColor Green
}

# Helper function to clean strings
function Clean-String($str) {
    if ($null -eq $str) { return "N/A" }
    $s = ([string]$str) -replace '[\r\n]+', ' ' -replace '\s+', ' '
    return $s.Trim()
}

# Helper function to query remote WMI/CIM
function Get-RemoteWmiData {
    param(
        [string]$Class,
        [string]$Target,
        [System.Management.Automation.PSCredential]$Cred = $null,
        [string]$Namespace = "root\cimv2",
        [string]$Filter = $null
    )
    $Params = @{
        Namespace = $Namespace
        ErrorAction = "Stop"
    }
    if ($Target -ne $env:COMPUTERNAME -and $Target -ne "127.0.0.1") {
        $Params.Add("ComputerName", $Target)
        if ($Cred) { $Params.Add("Credential", $Cred) }
    }
    
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

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "                 REMOTE NETWORK INVENTORY TOOL" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "To query remote PCs over the network, administrative access is required."
Write-Host "1. By default, your current logged-in Windows credentials (e.g. Domain Admin) are used."
Write-Host "2. You can specify Primary credentials (e.g. DOMAIN\Administrator)."
Write-Host "3. You can also specify Fallback credentials (e.g. .\Administrator) for non-domain PCs."
Write-Host ""
$UseCred = Read-Host "Do you want to enter alternate Primary Admin credentials? (Y/N, default N)"
$Cred = $null
if ($UseCred -like "Y*") {
    Write-Host "`nEnter Primary Credentials (e.g. DOMAIN\Admin):" -ForegroundColor Yellow
    $Cred = Get-Credential
}

$UseFallback = Read-Host "Do you want to enter Fallback credentials for non-domain/workgroup PCs? (Y/N, default N)"
$FallbackCred = $null
if ($UseFallback -like "Y*") {
    Write-Host "`nEnter Fallback Workgroup Credentials (e.g. .\Administrator or LocalAdmin):" -ForegroundColor Yellow
    $FallbackCred = Get-Credential
}

# 2. Get local IP and subnet
$LocalIP = "192.168.1.1"
try {
    if (Get-Command Get-NetIPAddress -ErrorAction SilentlyContinue) {
        $LocalIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } | Select-Object -First 1).IPAddress
    } else {
        $NetAdapters = Get-RemoteWmiData -Class "Win32_NetworkAdapterConfiguration" -Target "127.0.0.1" -Filter "IPEnabled=True"
        if ($NetAdapters) {
            foreach ($Adp in @($NetAdapters)) {
                foreach ($IP in @($Adp.IPAddress)) {
                    if ($IP -and $IP -notlike "127.*" -and $IP -notlike "169.254.*" -and $IP -match '^\d+\.\d+\.\d+\.\d+$') {
                        $LocalIP = $IP; break
                    }
                }
                if ($LocalIP -ne "192.168.1.1") { break }
            }
        }
    }
} catch { }

$SubnetPrefix = $LocalIP -replace '\.\d+$', '.'
Write-Host "`nScanning network range: $($SubnetPrefix)1 to $($SubnetPrefix)254 for online PCs..." -ForegroundColor Cyan

# 3. Fast Ping Scan
$IPList = 1..254 | ForEach-Object { "$SubnetPrefix$_" }
$OnlineIPs = New-Object System.Collections.ArrayList

$CanAsync = $false
try {
    $TestPing = New-Object System.Net.NetworkInformation.Ping
    if ($TestPing | Get-Member -Name "SendPingAsync") { $CanAsync = $true }
} catch { }

if ($CanAsync) {
    $Tasks = New-Object System.Collections.ArrayList
    foreach ($IP in $IPList) {
        $PingObj = New-Object System.Net.NetworkInformation.Ping
        $TaskObj = New-Object PSObject
        Add-Member -InputObject $TaskObj -MemberType NoteProperty -Name "IP" -Value $IP
        Add-Member -InputObject $TaskObj -MemberType NoteProperty -Name "Task" -Value ($PingObj.SendPingAsync($IP, 150))
        [void]$Tasks.Add($TaskObj)
    }
    [System.Threading.Tasks.Task]::WaitAll($Tasks.Task)
    foreach ($T in $Tasks) {
        if ($T.Task.Result.Status -eq "Success") { [void]$OnlineIPs.Add($T.IP) }
    }
} else {
    foreach ($IP in $IPList) {
        try {
            $PingObj = New-Object System.Net.NetworkInformation.Ping
            if ($PingObj.Send($IP, 80).Status -eq "Success") { [void]$OnlineIPs.Add($IP) }
        } catch { }
    }
}

Write-Host "Found $($OnlineIPs.Count) active devices online. Starting remote WMI inventory..." -ForegroundColor Green

# Define ordered columns
$EntryProps = @(
    "Scan Date", "Computer Name", "Device Type", "Domain / Workgroup", "IP Address",
    "Logged-in User", "OS Version", "RAM (GB)", "RAM Slots Used", "Disk Health & Specs",
    "Storage C: Size (GB)", "Storage C: Free (GB)", "Battery Health", "Microsoft Office",
    "Antivirus", "Manufacturer", "Model", "Serial Number", "CPU", "MAC Address"
)

$ExistingData = New-Object System.Collections.ArrayList
if (Test-Path $CsvPath) {
    $Imported = @(Import-Csv -Path $CsvPath -ErrorAction SilentlyContinue)
    if ($Imported) {
        foreach ($Row in $Imported) {
            $CleanRow = New-Object PSObject
            foreach ($ColName in $EntryProps) {
                $Val = $Row.$ColName
                if ($null -eq $Val) { $Val = "Pending USB Scan" }
                Add-Member -InputObject $CleanRow -MemberType NoteProperty -Name $ColName -Value (Clean-String $Val)
            }
            [void]$ExistingData.Add($CleanRow)
        }
    }
}

$SuccessCount = 0
$FailCount = 0

foreach ($IP in $OnlineIPs) {
    Write-Host "`nConnecting to device at $IP..." -ForegroundColor Yellow
    
    # Resolve basic hostname first
    $Hostname = "IP-$($IP.Replace('.', '-'))"
    try {
        $Resolved = [System.Net.Dns]::GetHostEntry($IP).HostName
        if ($Resolved -like "*.*") { $Hostname = $Resolved.Split('.')[0] } else { $Hostname = $Resolved }
    } catch { }
    $Hostname = $Hostname.ToUpper()
    
    try {
        # Attempt to query Win32_ComputerSystem to verify WMI access and get real hostname
        $CS = $null
        $ActiveCred = $Cred
        try {
            $CS = Get-RemoteWmiData -Class "Win32_ComputerSystem" -Target $IP -Cred $Cred
        } catch {
            if ($FallbackCred) {
                Write-Host " -> Primary auth failed on $Hostname ($IP). Retrying with fallback workgroup credentials..." -ForegroundColor Yellow
                $CS = Get-RemoteWmiData -Class "Win32_ComputerSystem" -Target $IP -Cred $FallbackCred
                $ActiveCred = $FallbackCred
            } else {
                throw $_
            }
        }
        if (-not $CS) { throw "No WMI response" }
        
        $RealName = Clean-String $CS.Name
        if ($RealName -and $RealName -ne "N/A") { $Hostname = $RealName.ToUpper() }
        Write-Host " -> WMI Connected to [$Hostname]. Gathering specs..." -ForegroundColor Green
        
        $Manufacturer = Clean-String $CS.Manufacturer
        $Model = Clean-String $CS.Model
        $TotalRamGB = [Math]::Round($CS.TotalPhysicalMemory / 1GB, 2)
        $DomainStatus = if ($CS.PartOfDomain) { "Domain: $(Clean-String $CS.Domain)" } else { "Workgroup: $(Clean-String $CS.Domain)" }
        $LoggedUser = Clean-String $CS.UserName
        
        # Chassis / Device Type
        $DeviceType = "Unknown"
        try {
            $Chassis = Get-RemoteWmiData -Class "Win32_SystemEnclosure" -Target $IP -Cred $ActiveCred
            if ($Chassis) {
                $CType = @(@($Chassis)[0].ChassisTypes)[0]
                if (@(8, 9, 10, 11, 12, 14, 18, 21, 30, 31, 32) -contains $CType) { $DeviceType = "Laptop" }
                elseif (@(3, 4, 5, 6, 7, 13, 15, 16, 17) -contains $CType) { $DeviceType = "Desktop" }
                elseif ($CType -eq 23) { $DeviceType = "Server" }
                else { $DeviceType = "Other / Unknown" }
            }
        } catch { }
        
        # OS Info
        try {
            $OS = Get-RemoteWmiData -Class "Win32_OperatingSystem" -Target $IP -Cred $ActiveCred
            $OSVersion = "$(Clean-String $OS.Caption) ($(Clean-String $OS.Version))"
        } catch { $OSVersion = "Unknown Windows OS" }
        
        # RAM Slots
        $RamSlots = "Unknown"
        try {
            $Sticks = @(Get-RemoteWmiData -Class "Win32_PhysicalMemory" -Target $IP -Cred $ActiveCred)
            $Array = Get-RemoteWmiData -Class "Win32_PhysicalMemoryArray" -Target $IP -Cred $ActiveCred
            $TotalSlots = if ($Array) { ($Array | Measure-Object -Property MemoryDevices -Sum).Sum } else { 0 }
            if ($Sticks.Count -gt 0 -and $TotalSlots -gt 0) { $RamSlots = "$($Sticks.Count) of $TotalSlots slots used" }
            else { $RamSlots = "N/A" }
        } catch { }
        
        # BIOS Serial
        try {
            $Bios = Get-RemoteWmiData -Class "Win32_Bios" -Target $IP -Cred $ActiveCred
            $SerialNumber = Clean-String $Bios.SerialNumber
        } catch { $SerialNumber = "N/A" }
        
        # CPU
        try {
            $CPUs = @(Get-RemoteWmiData -Class "Win32_Processor" -Target $IP -Cred $ActiveCred)
            $CPUNames = New-Object System.Collections.ArrayList
            foreach ($C in $CPUs) {
                if ($C.Name) { [void]$CPUNames.Add((Clean-String $C.Name)) }
            }
            $CPUName = ($CPUNames | Select-Object -Unique) -join " + "
            if (-not $CPUName) { $CPUName = "Unknown CPU" }
        } catch { $CPUName = "Unknown CPU" }
        
        # Storage
        $DiskInfo = ""
        try {
            $Disks = Get-RemoteWmiData -Namespace "root\Microsoft\Windows\Storage" -Class "MSFT_PhysicalDisk" -Target $IP -Cred $ActiveCred
            if ($Disks) {
                $DiskParts = New-Object System.Collections.ArrayList
                foreach ($D in @($Disks)) {
                    $Type = switch ($D.MediaType) { 3 {"HDD"} 4 {"SSD"} 5 {"SCM"} default {"Unspecified"} }
                    $Health = switch ($D.HealthStatus) { 0 {"Healthy"} 1 {"Warning"} 2 {"Unhealthy"} default {"Unknown"} }
                    [void]$DiskParts.Add("[$Type] $(Clean-String $D.FriendlyName) ($([Math]::Round($D.Size/1GB, 1)) GB): $Health")
                }
                $DiskInfo = ($DiskParts -join " | ")
            }
        } catch { }
        if (-not $DiskInfo) {
            try {
                $Disks = Get-RemoteWmiData -Class "Win32_DiskDrive" -Target $IP -Cred $ActiveCred
                if ($Disks) {
                    $DiskParts = New-Object System.Collections.ArrayList
                    foreach ($D in @($Disks)) {
                        [void]$DiskParts.Add("[Drive] $(Clean-String $D.Model) ($([Math]::Round($D.Size/1GB, 1)) GB) - SMART: $(Clean-String $D.Status)")
                    }
                    $DiskInfo = ($DiskParts -join " | ")
                }
            } catch { $DiskInfo = "Unknown Drive Info" }
        }
        
        # Logical Disk C:
        try {
            $Disk = Get-RemoteWmiData -Class "Win32_LogicalDisk" -Target $IP -Cred $ActiveCred -Filter "DeviceID='C:'"
            $DiskSizeGB = [Math]::Round($Disk.Size / 1GB, 2)
            $DiskFreeGB = [Math]::Round($Disk.FreeSpace / 1GB, 2)
        } catch { $DiskSizeGB = "N/A"; $DiskFreeGB = "N/A" }
        
        # Battery
        $BatteryInfo = "N/A (No Battery)"
        try {
            $Batteries = Get-RemoteWmiData -Class "Win32_Battery" -Target $IP -Cred $ActiveCred
            if ($Batteries) {
                $BatParts = New-Object System.Collections.ArrayList
                foreach ($B in @($Batteries)) {
                    $HealthStr = if ($B.DesignCapacity -gt 0) { "Health: $([Math]::Round(($B.FullChargeCapacity / $B.DesignCapacity)*100, 1))%" } else { "Health: Unknown" }
                    [void]$BatParts.Add("Charge: $($B.EstimatedChargeRemaining)% | $HealthStr | Status: $($B.Status)")
                }
                $BatteryInfo = ($BatParts -join " | ")
            }
        } catch { }
        
        # Network MAC Address
        try {
            $Net = @(Get-RemoteWmiData -Class "Win32_NetworkAdapterConfiguration" -Target $IP -Cred $ActiveCred -Filter "IPEnabled=True")[0]
            $MACAddress = if ($Net) { Clean-String $Net.MACAddress } else { "N/A" }
        } catch { $MACAddress = "N/A" }
        
        # Antivirus
        $AVInfo = "Not Found"
        try {
            $AVProducts = Get-RemoteWmiData -Namespace "root\SecurityCenter2" -Class "AntiVirusProduct" -Target $IP -Cred $ActiveCred
            if ($AVProducts) {
                $AVParts = New-Object System.Collections.ArrayList
                foreach ($AV in @($AVProducts)) {
                    $StateHex = "{0:X6}" -f [int]$AV.productState
                    $Status = switch ($StateHex.Substring(2, 2)) { "10" {"Active & Up-to-date"} "11" {"Active (Signature Out of Date)"} "00" {"Disabled"} default {"Installed"} }
                    [void]$AVParts.Add("$(Clean-String $AV.displayName) ($Status)")
                }
                if ($AVParts.Count -gt 0) { $AVInfo = ($AVParts -join " | ") }
            }
        } catch { }
        if ($AVInfo -eq "Not Found") {
            try {
                $Def = Get-RemoteWmiData -Class "Win32_Service" -Target $IP -Cred $ActiveCred -Filter "Name='Windefend'"
                if ($Def) { $AVInfo = if ($Def.State -eq "Running") { "Windows Defender (Active)" } else { "Windows Defender (Stopped)" } }
            } catch { $AVInfo = "Standard / Not Detected" }
        }
        
        # Remote Installed Applications via WMI StdRegProv
        $InstalledApps = New-Object System.Collections.ArrayList
        $OfficeInfo = "Not Found"
        try {
            $Reg = Get-RemoteWmiData -Namespace "root\default" -Class "StdRegProv" -Target $IP -Cred $ActiveCred
            if ($Reg) {
                $Subkeys = @("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall")
                foreach ($KeyPath in $Subkeys) {
                    $Names = $Reg.EnumKey(2147483650, $KeyPath).sNames
                    if ($Names) {
                        foreach ($Sub in $Names) {
                            $SubPath = "$KeyPath\$Sub"
                            $DName = $Reg.GetStringValue(2147483650, $SubPath, "DisplayName").sValue
                            if ($DName) {
                                $DVer = $Reg.GetStringValue(2147483650, $SubPath, "DisplayVersion").sValue
                                $DPub = $Reg.GetStringValue(2147483650, $SubPath, "Publisher").sValue
                                [void]$InstalledApps.Add([PSCustomObject]@{ DisplayName = Clean-String $DName; DisplayVersion = Clean-String $DVer; Publisher = Clean-String $DPub })
                            }
                        }
                    }
                }
            }
            # Detect Office
            $OfficeApps = @($InstalledApps | Where-Object { $_.DisplayName -like "*Microsoft Office*" -or $_.DisplayName -like "*Microsoft 365*" })
            if ($OfficeApps.Count -gt 0) {
                $OfficeInfo = (@($OfficeApps | ForEach-Object { "$($_.DisplayName) ($($_.DisplayVersion))" }) | Select-Object -Unique) -join " | "
            }
            
            # Export remote software report
            $RemoteSoftwarePath = Join-Path -Path $SoftwareDir -ChildPath "${Hostname}_software.txt"
            $SoftReport = New-Object System.Collections.ArrayList
            [void]$SoftReport.Add("INSTALLED SOFTWARE INVENTORY FOR $Hostname (Gathered Remotely)")
            [void]$SoftReport.Add("==========================================================================")
            [void]$SoftReport.Add([String]::Format("{0,-65} | {1,-20} | {2,-30}", "Application Name", "Version", "Publisher"))
            [void]$SoftReport.Add("-" * 121)
            foreach ($App in ($InstalledApps | Sort-Object DisplayName)) {
                $N = $App.DisplayName; if ($N.Length -gt 63) { $N = $N.Substring(0, 60) + "..." }
                $V = $App.DisplayVersion; if ($null -eq $V) { $V = "N/A" }; if ($V.Length -gt 18) { $V = $V.Substring(0, 15) + "..." }
                $P = $App.Publisher; if ($null -eq $P) { $P = "N/A" }; if ($P.Length -gt 28) { $P = $P.Substring(0, 25) + "..." }
                [void]$SoftReport.Add([String]::Format("{0,-65} | {1,-20} | {2,-30}", $N, $V, $P))
            }
            $SoftReport | Out-File -FilePath $RemoteSoftwarePath -Encoding utf8 -Force
        } catch { }

        # Build custom object and update existing data list
        $NewEntry = New-Object PSObject
        $EntryMap = @{
            "Scan Date"            = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            "Computer Name"        = $Hostname
            "Device Type"          = $DeviceType
            "Domain / Workgroup"   = $DomainStatus
            "IP Address"           = $IP
            "Logged-in User"       = $LoggedUser
            "OS Version"           = $OSVersion
            "RAM (GB)"             = $TotalRamGB
            "RAM Slots Used"       = $RamSlots
            "Disk Health & Specs"  = $DiskInfo
            "Storage C: Size (GB)" = $DiskSizeGB
            "Storage C: Free (GB)" = $DiskFreeGB
            "Battery Health"       = $BatteryInfo
            "Microsoft Office"     = $OfficeInfo
            "Antivirus"            = $AVInfo
            "Manufacturer"         = $Manufacturer
            "Model"                = $Model
            "Serial Number"        = $SerialNumber
            "CPU"                  = $CPUName
            "MAC Address"          = $MACAddress
        }
        foreach ($ColName in $EntryProps) {
            Add-Member -InputObject $NewEntry -MemberType NoteProperty -Name $ColName -Value $EntryMap[$ColName]
        }
        
        $MatchIndex = -1
        for ($i = 0; $i -lt $ExistingData.Count; $i++) {
            if ($ExistingData[$i]."Computer Name" -eq $Hostname -or $ExistingData[$i]."IP Address" -eq $IP) {
                $MatchIndex = $i; break
            }
        }
        if ($MatchIndex -ge 0) {
            $ExistingData[$MatchIndex] = $NewEntry
        } else {
            [void]$ExistingData.Add($NewEntry)
        }
        $SuccessCount++
    } catch {
        Write-Host " -> Could not query device remotely over WMI ($Hostname / $IP): $($_.Exception.Message)" -ForegroundColor DarkYellow
        Write-Host "    (Device may be non-Windows, firewall blocked, or credentials insufficient. Marked as Pending USB Scan.)" -ForegroundColor DarkGray
        
        # Ensure placeholder exists in CSV
        $MatchIndex = -1
        for ($i = 0; $i -lt $ExistingData.Count; $i++) {
            if ($ExistingData[$i]."Computer Name" -eq $Hostname -or $ExistingData[$i]."IP Address" -eq $IP) {
                $MatchIndex = $i; break
            }
        }
        if ($MatchIndex -lt 0) {
            $NewRow = New-Object PSObject
            foreach ($ColName in $EntryProps) {
                $Val = "Pending USB Scan"
                if ($ColName -eq "Scan Date") { $Val = (Get-Date -Format "yyyy-MM-dd HH:mm:ss") }
                elseif ($ColName -eq "Computer Name") { $Val = $Hostname }
                elseif ($ColName -eq "IP Address") { $Val = $IP }
                Add-Member -InputObject $NewRow -MemberType NoteProperty -Name $ColName -Value $Val
            }
            [void]$ExistingData.Add($NewRow)
        }
        $FailCount++
    }
}

# Save updated inventory.csv
$ExistingData | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding utf8 -Force

Write-Host "`n==========================================================================" -ForegroundColor Green
Write-Host "Remote Network Inventory Completed!" -ForegroundColor Green
Write-Host " -> Successfully inventoried remotely: $SuccessCount devices" -ForegroundColor Green
Write-Host " -> Could not access remotely (need local USB scan): $FailCount devices" -ForegroundColor Yellow
Write-Host "All results updated in 'inventory.csv'." -ForegroundColor Cyan
