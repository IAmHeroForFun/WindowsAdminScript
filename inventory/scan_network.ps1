# PowerShell Network Discovery Script
# Compatible with Windows 7 (PowerShell 2.0) through Windows 11 (PowerShell 5.1 & 7+)
# Designed to run without administrator privileges.
# Scans the local network, discovers active devices, and populates 'inventory.csv' with placeholders.

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
    if ($null -eq $str) { return "Pending USB Scan" }
    $s = ([string]$str) -replace '[\r\n]+', ' ' -replace '\s+', ' '
    return $s.Trim()
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
$BackupDir = Join-Path -Path $ReportsDir -ChildPath "backups"

if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

# Create backup of existing inventory file before running scan
if (Test-Path $CsvPath) {
    $Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $BackupFile = Join-Path -Path $BackupDir -ChildPath "inventory_backup_$Timestamp.csv"
    Copy-Item -Path $CsvPath -Destination $BackupFile -Force
    Write-Host "Created backup of existing inventory: backups\inventory_backup_$Timestamp.csv" -ForegroundColor Green
}

# 2. Get local IP and determine network range
$LocalIP = $null
try {
    if (Get-Command Get-NetIPAddress -ErrorAction SilentlyContinue) {
        $LocalIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } | Select-Object -First 1).IPAddress
    }
} catch { }

if (-not $LocalIP) {
    try {
        $NetAdapters = Get-WmiData -Class "Win32_NetworkAdapterConfiguration" -Filter "IPEnabled=True"
        if ($NetAdapters) {
            foreach ($Adp in @($NetAdapters)) {
                foreach ($IP in @($Adp.IPAddress)) {
                    if ($IP -and $IP -notlike "127.*" -and $IP -notlike "169.254.*" -and $IP -match '^\d+\.\d+\.\d+\.\d+$') {
                        $LocalIP = $IP
                        break
                    }
                }
                if ($LocalIP) { break }
            }
        }
    } catch { }
}

if (-not $LocalIP) {
    $LocalIP = "192.168.1.1" # Default fallback
}

$SubnetPrefix = $LocalIP -replace '\.\d+$', '.'

Write-Host "Local Host IP: $LocalIP" -ForegroundColor Yellow
Write-Host "Scanning local network range: $($SubnetPrefix)1 to $($SubnetPrefix)254..." -ForegroundColor Cyan
Write-Host "Please wait..." -ForegroundColor Cyan

# 3. Perform fast ping scan
$IPList = 1..254 | ForEach-Object { "$SubnetPrefix$_" }
$OnlineIPs = New-Object System.Collections.ArrayList

# Check if SendPingAsync is available (.NET 4.5+ / Windows 8+)
$CanAsync = $false
try {
    $TestPing = New-Object System.Net.NetworkInformation.Ping
    if ($TestPing | Get-Member -Name "SendPingAsync") {
        $CanAsync = $true
    }
} catch { }

if ($CanAsync) {
    $Tasks = New-Object System.Collections.ArrayList
    foreach ($IP in $IPList) {
        if ($IP -eq $LocalIP) { continue }
        $PingObj = New-Object System.Net.NetworkInformation.Ping
        $TaskObj = New-Object PSObject
        Add-Member -InputObject $TaskObj -MemberType NoteProperty -Name "IP" -Value $IP
        Add-Member -InputObject $TaskObj -MemberType NoteProperty -Name "Task" -Value ($PingObj.SendPingAsync($IP, 150))
        [void]$Tasks.Add($TaskObj)
    }
    [System.Threading.Tasks.Task]::WaitAll($Tasks.Task)
    foreach ($T in $Tasks) {
        if ($T.Task.Result.Status -eq "Success") {
            [void]$OnlineIPs.Add($T.IP)
        }
    }
} else {
    # Synchronous fallback for Windows 7 (.NET 3.5 / PowerShell 2.0)
    foreach ($IP in $IPList) {
        if ($IP -eq $LocalIP) { continue }
        try {
            $PingObj = New-Object System.Net.NetworkInformation.Ping
            $Reply = $PingObj.Send($IP, 80)
            if ($Reply.Status -eq "Success") {
                [void]$OnlineIPs.Add($IP)
            }
        } catch { }
    }
}

# Add local IP to online list
if (-not $OnlineIPs.Contains($LocalIP)) {
    [void]$OnlineIPs.Add($LocalIP)
}

Write-Host "Found $($OnlineIPs.Count) active devices online. Resolving hostnames..." -ForegroundColor Cyan

# 4. Resolve Device Hostnames (Computer Names)
$DiscoveredDevices = New-Object System.Collections.ArrayList
foreach ($IP in $OnlineIPs) {
    $Hostname = ""
    if ($IP -eq $LocalIP) {
        $Hostname = $env:COMPUTERNAME
    } else {
        try {
            $Resolved = [System.Net.Dns]::GetHostEntry($IP).HostName
            if ($Resolved -like "*.*") {
                $Hostname = $Resolved.Split('.')[0]
            } else {
                $Hostname = $Resolved
            }
        } catch {
            $Hostname = "IP-$($IP.Replace('.', '-'))"
        }
    }
    
    $DevObj = New-Object PSObject
    Add-Member -InputObject $DevObj -MemberType NoteProperty -Name "IP" -Value $IP
    Add-Member -InputObject $DevObj -MemberType NoteProperty -Name "Name" -Value $Hostname.ToUpper()
    [void]$DiscoveredDevices.Add($DevObj)
}

# Define strict ordered columns matching get_inventory.ps1
$EntryProps = @(
    "Scan Date", "Computer Name", "Device Type", "Domain / Workgroup", "IP Address",
    "Logged-in User", "OS Version", "RAM (GB)", "RAM Slots Used", "Disk Health & Specs",
    "Storage C: Size (GB)", "Storage C: Free (GB)", "Battery Health", "Microsoft Office",
    "Antivirus", "Manufacturer", "Model", "Serial Number", "CPU", "MAC Address"
)

# 5. Populate inventory.csv
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
$UpdatedCount = 0
$NewCount = 0

foreach ($Dev in $DiscoveredDevices) {
    $MatchIndex = -1
    for ($i = 0; $i -lt $ExistingData.Count; $i++) {
        if ($ExistingData[$i]."Computer Name" -eq $Dev.Name) {
            $MatchIndex = $i
            break
        }
    }
    
    if ($MatchIndex -ge 0) {
        if ($ExistingData[$MatchIndex]."Device Type" -eq "Pending USB Scan" -or [string]::IsNullOrEmpty($ExistingData[$MatchIndex]."Device Type")) {
            $ExistingData[$MatchIndex]."IP Address" = $Dev.IP
            $ExistingData[$MatchIndex]."Scan Date" = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            $UpdatedCount++
        }
    } else {
        $NewRow = New-Object PSObject
        foreach ($ColName in $EntryProps) {
            $Val = "Pending USB Scan"
            if ($ColName -eq "Scan Date") { $Val = (Get-Date -Format "yyyy-MM-dd HH:mm:ss") }
            elseif ($ColName -eq "Computer Name") { $Val = $Dev.Name }
            elseif ($ColName -eq "IP Address") { $Val = $Dev.IP }
            Add-Member -InputObject $NewRow -MemberType NoteProperty -Name $ColName -Value $Val
        }
        [void]$ExistingData.Add($NewRow)
        $NewCount++
    }
}

# Write consolidated spreadsheet back
$ExistingData | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding utf8 -Force

Write-Host "Network scan complete!" -ForegroundColor Green
Write-Host " - Newly discovered devices added: $NewCount" -ForegroundColor Green
Write-Host " - Existing placeholders updated: $UpdatedCount" -ForegroundColor Yellow

# 6. Show GUI Message Box
try {
    Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
    $Msg = "Network scan complete!`n`nDevices Discovered: $($DiscoveredDevices.Count)`nNew rows added: $NewCount`n`nAll discovered devices are saved to 'inventory.csv' with 'Pending USB Scan' placeholders. When you plug the USB into those computers and run the scan, their data will automatically autofill."
    [System.Windows.MessageBox]::Show($Msg, "Network Scan Completed", "OK", "Information") | Out-Null
} catch {
    Write-Host "Network scan complete! Results saved to inventory.csv" -ForegroundColor Green
}

