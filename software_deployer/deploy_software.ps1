<#
.SYNOPSIS
    OmviHub Cloud Software Deployer - 100% Genuine Ninite-Style Graphical Application
.DESCRIPTION
    A complete, standalone graphical application engineered in native PowerShell (Windows Forms) that replicates
    the authentic Ninite experience:
    
    1. Selection Screen: 4-Column checkbox layout categorized by software type (Web Browsers, IT Admin Tools, Network & Security, Utilities & Dev Tools).
    2. Live Installation Progress Screen: Transitions smoothly to an in-window graphical installation monitor with real-time status updates ("[..] Waiting", "[>>] Downloading & Installing...", "[OK] Installed"), itemized table, and a live green progress bar.
    3. Zero AWS Bandwidth Used: Uses native Microsoft Winget and Chocolatey to download directly from official vendor CDNs at gigabit edge speeds.
    4. Forensic Reporting: Automatically generates itemized CSV audit logs and dark-mode HTML dashboards upon completion.
#>

[CmdletBinding()]
param (
    [string[]]$Packages = @(),
    [string]$Preset = "",
    [switch]$NoGUI,
    [switch]$ForceInstall
)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------
# 1. ADMIN ELEVATION CHECK
# ---------------------------------------------------------
function Test-IsAdmin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Host "==========================================================================" -ForegroundColor DarkYellow
    Write-Host "  [ELEVATION REQUIRED] OmviHub Ninite Software Deployer requires Admin rights." -ForegroundColor Yellow
    Write-Host "  Requesting UAC Elevation... Please click 'Yes' on the prompt." -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor DarkYellow
    
    $CommandLine = "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    if ($Packages.Count -gt 0) { $CommandLine += " -Packages $($Packages -join ',')" }
    if ($Preset) { $CommandLine += " -Preset $Preset" }
    if ($NoGUI) { $CommandLine += " -NoGUI" }
    
    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList $CommandLine -Verb RunAs -Wait
        exit
    } catch {
        Write-Host "`n[ERROR] Administrative elevation failed or cancelled." -ForegroundColor Red
        Write-Host "`nPress Enter to exit..." -ForegroundColor DarkGray; [void](Read-Host)
        exit 1
    }
}

Clear-Host
Write-Host "Initializing OmviHub Ninite-Style Cloud Software Deployer..." -ForegroundColor Cyan

# ---------------------------------------------------------
# 2. PACKAGE MANAGER ENGINE BOOTSTRAPPER
# ---------------------------------------------------------
$PackageManager = "None"
if (Get-Command winget -ErrorAction SilentlyContinue) {
    $PackageManager = "Winget"
} elseif (Get-Command choco -ErrorAction SilentlyContinue) {
    $PackageManager = "Chocolatey"
} else {
    Write-Host "[!] Neither Winget nor Chocolatey detected. Bootstrapping Chocolatey..." -ForegroundColor Yellow
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        $env:Path += ";$env:ALLUSERSPROFILE\chocolatey\bin"
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            $PackageManager = "Chocolatey"
        } else {
            throw "Chocolatey command not found after installation."
        }
    } catch {
        Write-Host "[ERROR] Failed to bootstrap package manager: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please install Microsoft Winget or Chocolatey manually." -ForegroundColor Yellow
        Write-Host "`nPress Enter to exit..." -ForegroundColor DarkGray; [void](Read-Host)
        exit 1
    }
}

# ---------------------------------------------------------
# 3. MASTER SOFTWARE CATALOG (32 ENTERPRISE APPLICATIONS)
# ---------------------------------------------------------
$Catalog = @(
    # Web Browsers & Messaging (Col 1)
    [PSCustomObject]@{ Id = 1;  Category = "Web Browsers"; Name = "Google Chrome"; WingetID = "Google.Chrome"; ChocoID = "googlechrome"; Description = "Fast, secure web browser by Google"; Col = 0 },
    [PSCustomObject]@{ Id = 2;  Category = "Web Browsers"; Name = "Mozilla Firefox"; WingetID = "Mozilla.Firefox"; ChocoID = "firefox"; Description = "Open-source privacy-focused web browser"; Col = 0 },
    [PSCustomObject]@{ Id = 3;  Category = "Web Browsers"; Name = "Microsoft Edge"; WingetID = "Microsoft.Edge"; ChocoID = "microsoft-edge"; Description = "Chromium-based enterprise web browser"; Col = 0 },
    [PSCustomObject]@{ Id = 4;  Category = "Web Browsers"; Name = "Brave Browser"; WingetID = "Brave.Brave"; ChocoID = "brave"; Description = "Privacy-first ad-blocking web browser"; Col = 0 },
    [PSCustomObject]@{ Id = 5;  Category = "Messaging & Media"; Name = "Zoom Workplace"; WingetID = "Zoom.Zoom"; ChocoID = "zoom"; Description = "Video conferencing and enterprise meetings"; Col = 0 },
    [PSCustomObject]@{ Id = 6;  Category = "Messaging & Media"; Name = "Microsoft Teams"; WingetID = "Microsoft.Teams"; ChocoID = "microsoft-teams"; Description = "Enterprise messaging and collaboration"; Col = 0 },
    [PSCustomObject]@{ Id = 7;  Category = "Messaging & Media"; Name = "Discord"; WingetID = "Discord.Discord"; ChocoID = "discord"; Description = "Voice, video, and text communication"; Col = 0 },
    [PSCustomObject]@{ Id = 8;  Category = "Messaging & Media"; Name = "VLC Media Player"; WingetID = "VideoLAN.VLC"; ChocoID = "vlc"; Description = "Universal multimedia video and audio player"; Col = 0 },

    # IT Admin & System Tools (Col 2)
    [PSCustomObject]@{ Id = 9;  Category = "IT Admin Tools"; Name = "Sysinternals Suite"; WingetID = "Microsoft.SysinternalsSuite"; ChocoID = "sysinternals"; Description = "Advanced Windows system administration utilities"; Col = 1 },
    [PSCustomObject]@{ Id = 10; Category = "IT Admin Tools"; Name = "PuTTY (SSH Client)"; WingetID = "PuTTY.PuTTY"; ChocoID = "putty"; Description = "Telnet and SSH terminal client"; Col = 1 },
    [PSCustomObject]@{ Id = 11; Category = "IT Admin Tools"; Name = "WinSCP (SFTP/SCP)"; WingetID = "WinSCP.WinSCP"; ChocoID = "winscp"; Description = "SFTP, SCP, and FTP client for remote transfer"; Col = 1 },
    [PSCustomObject]@{ Id = 12; Category = "IT Admin Tools"; Name = "Notepad++"; WingetID = "Notepad++.Notepad++"; ChocoID = "notepadplusplus"; Description = "Advanced source code and configuration editor"; Col = 1 },
    [PSCustomObject]@{ Id = 13; Category = "IT Admin Tools"; Name = "TreeSize Free"; WingetID = "JAM Software.TreeSize.Free"; ChocoID = "treesizefree"; Description = "Disk space analyzer and folder hierarchy manager"; Col = 1 },
    [PSCustomObject]@{ Id = 14; Category = "IT Admin Tools"; Name = "PowerToys"; WingetID = "Microsoft.PowerToys"; ChocoID = "powertoys"; Description = "Microsoft system tuning and productivity utilities"; Col = 1 },
    [PSCustomObject]@{ Id = 15; Category = "IT Admin Tools"; Name = "Windows Terminal"; WingetID = "Microsoft.WindowsTerminal"; ChocoID = "microsoft-windows-terminal"; Description = "Modern tabbed command-line console"; Col = 1 },

    # Network & Remote Support (Col 3)
    [PSCustomObject]@{ Id = 16; Category = "Network & Security"; Name = "Wireshark"; WingetID = "WiresharkFoundation.Wireshark"; ChocoID = "wireshark"; Description = "Network protocol analyzer and packet sniffer"; Col = 2 },
    [PSCustomObject]@{ Id = 17; Category = "Network & Security"; Name = "Advanced IP Scanner"; WingetID = "Famatech.AdvancedIPScanner"; ChocoID = "advanced-ip-scanner"; Description = "Fast LAN subnet scanner with remote control"; Col = 2 },
    [PSCustomObject]@{ Id = 18; Category = "Network & Security"; Name = "Nmap"; WingetID = "Insecure.Nmap"; ChocoID = "nmap"; Description = "Security scanner and network exploration tool"; Col = 2 },
    [PSCustomObject]@{ Id = 19; Category = "Network & Security"; Name = "OpenVPN Client"; WingetID = "OpenVPNTechnologies.OpenVPN"; ChocoID = "openvpn"; Description = "Enterprise SSL VPN tunneling client"; Col = 2 },
    [PSCustomObject]@{ Id = 20; Category = "Remote Support"; Name = "RustDesk"; WingetID = "RustDesk.RustDesk"; ChocoID = "rustdesk"; Description = "Open-source remote desktop and RMM software"; Col = 2 },
    [PSCustomObject]@{ Id = 21; Category = "Remote Support"; Name = "AnyDesk"; WingetID = "AnyDeskSoftwareGmbH.AnyDesk"; ChocoID = "anydesk"; Description = "Fast remote desktop assistance application"; Col = 2 },
    [PSCustomObject]@{ Id = 22; Category = "Remote Support"; Name = "TeamViewer"; WingetID = "TeamViewer.TeamViewer"; ChocoID = "teamviewer"; Description = "Enterprise remote support and collaboration"; Col = 2 },

    # File Utilities & Dev Tools (Col 4)
    [PSCustomObject]@{ Id = 23; Category = "File Utilities"; Name = "7-Zip"; WingetID = "7zip.7zip"; ChocoID = "7zip"; Description = "High-compression file archiving utility"; Col = 3 },
    [PSCustomObject]@{ Id = 24; Category = "File Utilities"; Name = "WinRAR"; WingetID = "RARLab.WinRAR"; ChocoID = "winrar"; Description = "Popular archive and compression tool"; Col = 3 },
    [PSCustomObject]@{ Id = 25; Category = "File Utilities"; Name = "Everything Search"; WingetID = "voidtools.Everything"; ChocoID = "everything"; Description = "Instant real-time filename search engine"; Col = 3 },
    [PSCustomObject]@{ Id = 26; Category = "File Utilities"; Name = "OpenHashTab"; WingetID = "namazso.OpenHashTab"; ChocoID = "openhashtab"; Description = "File checksum verification tab in explorer"; Col = 3 },
    [PSCustomObject]@{ Id = 27; Category = "Developer Tools"; Name = "Visual Studio Code"; WingetID = "Microsoft.VisualStudioCode"; ChocoID = "vscode"; Description = "Lightweight source code editor by Microsoft"; Col = 3 },
    [PSCustomObject]@{ Id = 28; Category = "Developer Tools"; Name = "Git for Windows"; WingetID = "Git.Git"; ChocoID = "git"; Description = "Distributed version control system and bash"; Col = 3 },
    [PSCustomObject]@{ Id = 29; Category = "Developer Tools"; Name = "Python 3"; WingetID = "Python.Python.3"; ChocoID = "python3"; Description = "Python programming language runtime"; Col = 3 },
    [PSCustomObject]@{ Id = 30; Category = "Developer Tools"; Name = "PowerShell 7"; WingetID = "Microsoft.PowerShell"; ChocoID = "powershell-core"; Description = "Modern cross-platform PowerShell engine"; Col = 3 }
)

# ---------------------------------------------------------
# 4. PRE-CONFIGURED ENTERPRISE BUNDLES
# ---------------------------------------------------------
$Bundles = @{
    "ALL_ADMIN"      = @(9, 10, 11, 12, 13, 14, 15, 16, 17, 23, 25, 30)
    "ALL_BROWSERS"   = @(1, 2, 3, 4)
    "ALL_NETWORK"    = @(10, 11, 16, 17, 18, 19)
    "ALL_REMOTE"     = @(20, 21, 22)
    "ALL_DEV"        = @(12, 15, 27, 28, 29, 30)
    "ALL_ESSENTIALS" = @(1, 5, 8, 12, 23, 25)
}

# ---------------------------------------------------------
# 5. APPLICATION SELECTION & EXECUTION LOGIC
# ---------------------------------------------------------
$SelectedApps = @()

if ($Packages.Count -gt 0) {
    Write-Host "[+] Processing command-line package selections..." -ForegroundColor Cyan
    foreach ($Pkg in $Packages) {
        $Match = $Catalog | Where-Object { $_.WingetID -eq $Pkg -or $_.ChocoID -eq $Pkg -or $_.Name -like "*$Pkg*" }
        if ($Match) { $SelectedApps += $Match } else { Write-Host " [!] Unknown package: $Pkg" -ForegroundColor Yellow }
    }
} elseif ($Preset -and $Bundles.ContainsKey($Preset.ToUpper())) {
    Write-Host "[+] Loading pre-configured bundle: $($Preset.ToUpper())..." -ForegroundColor Cyan
    $BundleIds = $Bundles[$Preset.ToUpper()]
    $SelectedApps = $Catalog | Where-Object { $_.Id -in $BundleIds }
} else {
    $GUISuccess = $false
    
    if (-not $NoGUI) {
        try {
            Add-Type -AssemblyName System.Windows.Forms
            Add-Type -AssemblyName System.Drawing

            # Create Main Form
            $Form = New-Object System.Windows.Forms.Form
            $Form.Text = "OmviHub Ninite Software Deployer"
            $Form.Size = New-Object System.Drawing.Size(1020, 720)
            $Form.StartPosition = "CenterScreen"
            $Form.BackColor = [System.Drawing.Color]::FromArgb(18, 24, 38) # Deep Dark Navy #121826
            $Form.ForeColor = [System.Drawing.Color]::White
            $Form.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
            $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
            $Form.MaximizeBox = $false

            # Header Panel
            $HeaderPanel = New-Object System.Windows.Forms.Panel
            $HeaderPanel.Size = New-Object System.Drawing.Size(1020, 80)
            $HeaderPanel.Dock = [System.Windows.Forms.DockStyle]::Top
            $HeaderPanel.BackColor = [System.Drawing.Color]::FromArgb(26, 35, 50)
            $Form.Controls.Add($HeaderPanel)

            $TitleLabel = New-Object System.Windows.Forms.Label
            $TitleLabel.Text = "OmviHub Ninite Software Deployer"
            $TitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
            $TitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(56, 189, 248) # Bright Cyan
            $TitleLabel.Location = New-Object System.Drawing.Point(20, 15)
            $TitleLabel.Size = New-Object System.Drawing.Size(600, 32)
            $HeaderPanel.Controls.Add($TitleLabel)

            $SubTitle = New-Object System.Windows.Forms.Label
            $SubTitle.Text = "Check the apps you want to install and click Install. Downloads directly from official vendor CDNs via $PackageManager."
            $SubTitle.ForeColor = [System.Drawing.Color]::FromArgb(148, 163, 184) # Muted Slate
            $SubTitle.Location = New-Object System.Drawing.Point(22, 48)
            $SubTitle.Size = New-Object System.Drawing.Size(850, 22)
            $HeaderPanel.Controls.Add($SubTitle)

            # =========================================================
            # PANEL 1: SELECTION SCREEN (4 COLUMNS OF CHECKBOXES)
            # =========================================================
            $SelectionPanel = New-Object System.Windows.Forms.Panel
            $SelectionPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
            $Form.Controls.Add($SelectionPanel)
            $SelectionPanel.BringToFront()

            # Bottom Action Bar for Selection Panel
            $BottomBar = New-Object System.Windows.Forms.Panel
            $BottomBar.Size = New-Object System.Drawing.Size(1020, 85)
            $BottomBar.Dock = [System.Windows.Forms.DockStyle]::Bottom
            $BottomBar.BackColor = [System.Drawing.Color]::FromArgb(26, 35, 50)
            $SelectionPanel.Controls.Add($BottomBar)

            $InstallBtn = New-Object System.Windows.Forms.Button
            $InstallBtn.Text = "Install Selected Software (0 Selected)"
            $InstallBtn.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
            $InstallBtn.BackColor = [System.Drawing.Color]::FromArgb(100, 116, 139) # Disabled Slate initially
            $InstallBtn.ForeColor = [System.Drawing.Color]::White
            $InstallBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            $InstallBtn.FlatAppearance.BorderSize = 0
            $InstallBtn.Size = New-Object System.Drawing.Size(380, 45)
            $InstallBtn.Location = New-Object System.Drawing.Point(600, 20)
            $InstallBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
            $BottomBar.Controls.Add($InstallBtn)

            $SelectAllBtn = New-Object System.Windows.Forms.Button
            $SelectAllBtn.Text = "Select All"
            $SelectAllBtn.BackColor = [System.Drawing.Color]::FromArgb(51, 65, 85)
            $SelectAllBtn.ForeColor = [System.Drawing.Color]::White
            $SelectAllBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            $SelectAllBtn.Size = New-Object System.Drawing.Size(100, 35)
            $SelectAllBtn.Location = New-Object System.Drawing.Point(20, 25)
            $BottomBar.Controls.Add($SelectAllBtn)

            $ClearAllBtn = New-Object System.Windows.Forms.Button
            $ClearAllBtn.Text = "Clear All"
            $ClearAllBtn.BackColor = [System.Drawing.Color]::FromArgb(51, 65, 85)
            $ClearAllBtn.ForeColor = [System.Drawing.Color]::White
            $ClearAllBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            $ClearAllBtn.Size = New-Object System.Drawing.Size(100, 35)
            $ClearAllBtn.Location = New-Object System.Drawing.Point(130, 25)
            $BottomBar.Controls.Add($ClearAllBtn)

            $AdminPresetBtn = New-Object System.Windows.Forms.Button
            $AdminPresetBtn.Text = "IT Admin Pack"
            $AdminPresetBtn.BackColor = [System.Drawing.Color]::FromArgb(168, 85, 247) # Purple
            $AdminPresetBtn.ForeColor = [System.Drawing.Color]::White
            $AdminPresetBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
            $AdminPresetBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            $AdminPresetBtn.Size = New-Object System.Drawing.Size(150, 35)
            $AdminPresetBtn.Location = New-Object System.Drawing.Point(250, 25)
            $BottomBar.Controls.Add($AdminPresetBtn)

            $WorkerPresetBtn = New-Object System.Windows.Forms.Button
            $WorkerPresetBtn.Text = "Worker Pack"
            $WorkerPresetBtn.BackColor = [System.Drawing.Color]::FromArgb(14, 165, 233) # Cyan
            $WorkerPresetBtn.ForeColor = [System.Drawing.Color]::White
            $WorkerPresetBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
            $WorkerPresetBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            $WorkerPresetBtn.Size = New-Object System.Drawing.Size(150, 35)
            $WorkerPresetBtn.Location = New-Object System.Drawing.Point(410, 25)
            $BottomBar.Controls.Add($WorkerPresetBtn)

            # Checkbox Columns Area
            $ColumnsArea = New-Object System.Windows.Forms.Panel
            $ColumnsArea.Dock = [System.Windows.Forms.DockStyle]::Fill
            $ColumnsArea.AutoScroll = $true
            $ColumnsArea.Padding = New-Object System.Windows.Forms.Padding(15)
            $SelectionPanel.Controls.Add($ColumnsArea)

            [int]$ColWidth = 230
            [int[]]$ColX = @(20, 265, 510, 755)
            [int[]]$ColY = @(15, 15, 15, 15)

            $CheckBoxes = @()
            $UniqueCats = $Catalog | Select-Object -ExpandProperty Category -Unique

            foreach ($Cat in $UniqueCats) {
                $CatApps = $Catalog | Where-Object { $_.Category -eq $Cat }
                [int]$ColIndex = [int]$CatApps[0].Col
                [int]$BoxHeight = 35 + ([int]$CatApps.Count * 28)

                $GroupBox = New-Object System.Windows.Forms.GroupBox
                $GroupBox.Text = "  $Cat  "
                $GroupBox.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
                $GroupBox.ForeColor = [System.Drawing.Color]::FromArgb(56, 189, 248)
                $GroupBox.Location = New-Object System.Drawing.Point($ColX[$ColIndex], $ColY[$ColIndex])
                $GroupBox.Size = New-Object System.Drawing.Size([int]$ColWidth, [int]$BoxHeight)
                $ColumnsArea.Controls.Add($GroupBox)

                [int]$AppY = 28
                foreach ($App in $CatApps) {
                    $CB = New-Object System.Windows.Forms.CheckBox
                    $CB.Text = $App.Name
                    $CB.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
                    $CB.ForeColor = [System.Drawing.Color]::White
                    $CB.Location = New-Object System.Drawing.Point(15, [int]$AppY)
                    [int]$CBWidth = [int]$ColWidth - 25
                    $CB.Size = New-Object System.Drawing.Size([int]$CBWidth, 22)
                    $CB.Tag = $App
                    $CB.Cursor = [System.Windows.Forms.Cursors]::Hand
                    
                    $ToolTip = New-Object System.Windows.Forms.ToolTip
                    $ToolTip.SetToolTip($CB, $App.Description)

                    $CB.Add_CheckedChanged({
                        [int]$CheckedCount = ($CheckBoxes | Where-Object { $_.Checked }).Count
                        $InstallBtn.Text = "Install Selected Software ($CheckedCount Selected)"
                        if ($CheckedCount -gt 0) {
                            $InstallBtn.BackColor = [System.Drawing.Color]::FromArgb(34, 197, 94) # Bright Green
                        } else {
                            $InstallBtn.BackColor = [System.Drawing.Color]::FromArgb(100, 116, 139)
                        }
                    })

                    $GroupBox.Controls.Add($CB)
                    $CheckBoxes += $CB
                    $AppY += 26
                }

                $ColY[$ColIndex] += $BoxHeight + 15
            }

            # =========================================================
            # PANEL 2: LIVE NINITE INSTALLATION PROGRESS SCREEN
            # =========================================================
            $ProgressPanel = New-Object System.Windows.Forms.Panel
            $ProgressPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
            $ProgressPanel.Visible = $false
            $Form.Controls.Add($ProgressPanel)

            # Bottom Bar for Progress Panel
            $ProgBottomBar = New-Object System.Windows.Forms.Panel
            $ProgBottomBar.Size = New-Object System.Drawing.Size(1020, 95)
            $ProgBottomBar.Dock = [System.Windows.Forms.DockStyle]::Bottom
            $ProgBottomBar.BackColor = [System.Drawing.Color]::FromArgb(26, 35, 50)
            $ProgressPanel.Controls.Add($ProgBottomBar)

            $ProgressBar = New-Object System.Windows.Forms.ProgressBar
            $ProgressBar.Location = New-Object System.Drawing.Point(20, 20)
            $ProgressBar.Size = New-Object System.Drawing.Size(960, 25)
            $ProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
            $ProgBottomBar.Controls.Add($ProgressBar)

            $ProgressStatusLabel = New-Object System.Windows.Forms.Label
            $ProgressStatusLabel.Text = "Overall Progress: 0 of 0 completed (0%)"
            $ProgressStatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $ProgressStatusLabel.ForeColor = [System.Drawing.Color]::FromArgb(248, 250, 252)
            $ProgressStatusLabel.Location = New-Object System.Drawing.Point(20, 55)
            $ProgressStatusLabel.Size = New-Object System.Drawing.Size(550, 25)
            $ProgBottomBar.Controls.Add($ProgressStatusLabel)

            $CloseReportBtn = New-Object System.Windows.Forms.Button
            $CloseReportBtn.Text = "View HTML Report & Close"
            $CloseReportBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $CloseReportBtn.BackColor = [System.Drawing.Color]::FromArgb(56, 189, 248) # Cyan
            $CloseReportBtn.ForeColor = [System.Drawing.Color]::FromArgb(15, 23, 42)
            $CloseReportBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            $CloseReportBtn.Size = New-Object System.Drawing.Size(260, 35)
            $CloseReportBtn.Location = New-Object System.Drawing.Point(720, 50)
            $CloseReportBtn.Visible = $false
            $CloseReportBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
            $ProgBottomBar.Controls.Add($CloseReportBtn)

            # DataGridView Table for Live Installation Status
            $Grid = New-Object System.Windows.Forms.DataGridView
            $Grid.Dock = [System.Windows.Forms.DockStyle]::Fill
            $Grid.BackgroundColor = [System.Drawing.Color]::FromArgb(18, 24, 38)
            $Grid.ForeColor = [System.Drawing.Color]::White
            $Grid.GridColor = [System.Drawing.Color]::FromArgb(51, 65, 85)
            $Grid.BorderStyle = [System.Windows.Forms.BorderStyle]::None
            $Grid.AllowUserToAddRows = $false
            $Grid.AllowUserToDeleteRows = $false
            $Grid.ReadOnly = $true
            $Grid.RowHeadersVisible = $false
            $Grid.SelectionMode = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
            $Grid.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
            $Grid.DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(30, 41, 59)
            $Grid.DefaultCellStyle.ForeColor = [System.Drawing.Color]::White
            $Grid.DefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 10)
            $Grid.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(51, 65, 85)
            $Grid.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(15, 23, 42)
            $Grid.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(56, 189, 248)
            $Grid.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $Grid.ColumnHeadersHeight = 40
            $Grid.RowTemplate.Height = 36
            $Grid.EnableHeadersVisualStyles = $false

            $Grid.ColumnCount = 4
            $Grid.Columns[0].Name = "Application Name"
            $Grid.Columns[0].FillWeight = 30
            $Grid.Columns[1].Name = "Category"
            $Grid.Columns[1].FillWeight = 25
            $Grid.Columns[2].Name = "Package Identifier"
            $Grid.Columns[2].FillWeight = 25
            $Grid.Columns[3].Name = "Current Status"
            $Grid.Columns[3].FillWeight = 20
            $ProgressPanel.Controls.Add($Grid)

            # =========================================================
            # BUTTON EVENT HANDLERS
            # =========================================================
            $SelectAllBtn.Add_Click({ foreach ($CB in $CheckBoxes) { $CB.Checked = $true } })
            $ClearAllBtn.Add_Click({ foreach ($CB in $CheckBoxes) { $CB.Checked = $false } })

            $AdminPresetBtn.Add_Click({
                $AdminIds = $Bundles["ALL_ADMIN"]
                foreach ($CB in $CheckBoxes) { if ($CB.Tag.Id -in $AdminIds) { $CB.Checked = $true } else { $CB.Checked = $false } }
            })

            $WorkerPresetBtn.Add_Click({
                $WorkerIds = $Bundles["ALL_ESSENTIALS"]
                foreach ($CB in $CheckBoxes) { if ($CB.Tag.Id -in $WorkerIds) { $CB.Checked = $true } else { $CB.Checked = $false } }
            })

            $InstallBtn.Add_Click({
                $Checked = $CheckBoxes | Where-Object { $_.Checked }
                if ($Checked.Count -eq 0) {
                    [System.Windows.Forms.MessageBox]::Show("Please check at least one application box to install!", "No Software Selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                    return
                }

                $script:SelectedApps = $Checked | ForEach-Object { $_.Tag }
                
                # Switch to Progress Screen!
                $SelectionPanel.Visible = $false
                $ProgressPanel.Visible = $true
                $ProgressPanel.BringToFront()
                $SubTitle.Text = "Installing $($SelectedApps.Count) applications. Please wait while packages are downloaded and verified..."
                
                # Populate Grid with selected apps
                $Grid.Rows.Clear()
                foreach ($App in $SelectedApps) {
                    $PkgId = if ($PackageManager -eq "Winget") { $App.WingetID } else { $App.ChocoID }
                    $RowIdx = $Grid.Rows.Add($App.Name, $App.Category, $PkgId, "[..] Waiting in queue...")
                    $Grid.Rows[$RowIdx].Cells[3].Style.ForeColor = [System.Drawing.Color]::FromArgb(148, 163, 184)
                }

                $ProgressBar.Value = 0
                $ProgressStatusLabel.Text = "Overall Progress: 0 of $($SelectedApps.Count) completed (0%)"
                [System.Windows.Forms.Application]::DoEvents()
                $Form.Refresh()

                # Start Async Deployment Loop
                $ReportsDir = Join-Path $PSScriptRoot "reports"
                if (-not (Test-Path $ReportsDir)) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null }
                $script:DeploymentResults = @()
                $TotalApps = $SelectedApps.Count
                $CurrentIdx = 0

                for ($i = 0; $i -lt $TotalApps; $i++) {
                    $App = $SelectedApps[$i]
                    $CurrentIdx++

                    # Update UI for currently installing app
                    $Grid.Rows[$i].Cells[3].Value = "[>>] Downloading & Installing..."
                    $Grid.Rows[$i].Cells[3].Style.ForeColor = [System.Drawing.Color]::FromArgb(56, 189, 248) # Cyan
                    $Grid.Rows[$i].Selected = $true
                    $Grid.FirstDisplayedScrollingRowIndex = $i
                    [System.Windows.Forms.Application]::DoEvents()
                    $Form.Refresh()

                    $StartTime = Get-Date
                    $Status = "Failed"
                    $ErrorMsg = "None"

                    try {
                        if ($PackageManager -eq "Winget") {
                            $InstallCmd = "winget install --id $($App.WingetID) --silent --accept-package-agreements --accept-source-agreements"
                            if ($ForceInstall) { $InstallCmd += " --force" }
                            $Output = Invoke-Expression $InstallCmd 2>&1 | Out-String
                            if ($LASTEXITCODE -eq 0 -or $Output -match "Successfully installed|already installed|No applicable update found") {
                                $Status = "Success"
                            } else {
                                if (Get-Command choco -ErrorAction SilentlyContinue) {
                                    $Grid.Rows[$i].Cells[3].Value = "[>>] Winget failed -> Retrying via Choco..."
                                    [System.Windows.Forms.Application]::DoEvents()
                                    $ChocoCmd = "choco install $($App.ChocoID) -y --no-progress"
                                    $Output = Invoke-Expression $ChocoCmd 2>&1 | Out-String
                                    if ($LASTEXITCODE -eq 0 -or $Output -match "already installed|The install of $($App.ChocoID) was successful") {
                                        $Status = "Success (Choco Fallback)"
                                    } else {
                                        $Status = "Failed"
                                        $ErrorMsg = "Both Winget and Choco installations failed."
                                    }
                                } else {
                                    $Status = "Failed"
                                    $ErrorMsg = "Winget exit code $LASTEXITCODE"
                                }
                            }
                        } elseif ($PackageManager -eq "Chocolatey") {
                            $ChocoCmd = "choco install $($App.ChocoID) -y --no-progress"
                            $Output = Invoke-Expression $ChocoCmd 2>&1 | Out-String
                            if ($LASTEXITCODE -eq 0 -or $Output -match "already installed|The install of $($App.ChocoID) was successful") {
                                $Status = "Success"
                            } else {
                                $Status = "Failed"
                                $ErrorMsg = "Choco exit code $LASTEXITCODE"
                            }
                        }
                    } catch {
                        $Status = "Error"
                        $ErrorMsg = $_.Exception.Message
                    }

                    $Duration = ((Get-Date) - $StartTime).TotalSeconds
                    $script:DeploymentResults += [PSCustomObject]@{
                        Timestamp    = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                        Category     = $App.Category
                        Name         = $App.Name
                        PackageID    = if ($PackageManager -eq "Winget") { $App.WingetID } else { $App.ChocoID }
                        Status       = $Status
                        DurationSec  = [math]::Round($Duration, 1)
                        ErrorMessage = $ErrorMsg
                    }

                    # Update UI Row Status
                    if ($Status -like "*Success*") {
                        $Grid.Rows[$i].Cells[3].Value = "[OK] Installed Successfully"
                        $Grid.Rows[$i].Cells[3].Style.ForeColor = [System.Drawing.Color]::FromArgb(34, 197, 94) # Green
                    } else {
                        $Grid.Rows[$i].Cells[3].Value = "[FAILED] Error: $ErrorMsg"
                        $Grid.Rows[$i].Cells[3].Style.ForeColor = [System.Drawing.Color]::FromArgb(239, 68, 68) # Red
                    }

                    # Update Progress Bar
                    $ProgressBar.Value = [math]::Round(($CurrentIdx / $TotalApps) * 100)
                    $ProgressStatusLabel.Text = "Overall Progress: $CurrentIdx of $TotalApps completed ($($ProgressBar.Value)%)"
                    [System.Windows.Forms.Application]::DoEvents()
                    $Form.Refresh()
                }

                # Completion State
                $SubTitle.Text = "All installations completed! Click below to view the full HTML audit report."
                $TitleLabel.Text = "Software Deployment Complete!"
                $TitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(34, 197, 94)
                $CloseReportBtn.Visible = $true
                [System.Windows.Forms.Application]::DoEvents()
                $Form.Refresh()
            })

            $CloseReportBtn.Add_Click({
                $Form.DialogResult = [System.Windows.Forms.DialogResult]::OK
                $Form.Close()
            })

            # Show Dialog
            $Result = $Form.ShowDialog()
            if ($Result -eq [System.Windows.Forms.DialogResult]::OK -and $SelectedApps.Count -gt 0) {
                $GUISuccess = $true
            } else {
                Write-Host "`n[!] Graphical window closed. Aborting." -ForegroundColor Yellow
                exit
            }
        } catch {
            Write-Host "[!] Graphical window failed: $($_.Exception.Message). Falling back to console menu..." -ForegroundColor Yellow
        }
    }
    
    # Console Fallback
    if (-not $GUISuccess) {
        Write-Host "`n==========================================================================" -ForegroundColor Cyan
        Write-Host "         OMVIHUB CONSOLE SOFTWARE CATALOG [SELECT BY NUMBER]" -ForegroundColor White
        Write-Host "==========================================================================" -ForegroundColor Cyan
        
        $Categories = $Catalog | Select-Object -ExpandProperty Category -Unique
        foreach ($Cat in $Categories) {
            Write-Host "`n-- $Cat --" -ForegroundColor Yellow
            $CatApps = $Catalog | Where-Object { $_.Category -eq $Cat }
            foreach ($App in $CatApps) {
                Write-Host "  [$($App.Id)] $($App.Name) " -NoNewline -ForegroundColor White
                Write-Host "($($App.Description))" -ForegroundColor DarkGray
            }
        }
        
        Write-Host "`n-- PRE-CONFIGURED ENTERPRISE BUNDLES --" -ForegroundColor Green
        Write-Host "  [ALL_ADMIN]      IT Admin Suite (Sysinternals, Putty, WinSCP, Notepad++, TreeSize)" -ForegroundColor White
        Write-Host "  [ALL_BROWSERS]   All Web Browsers (Chrome, Firefox, Edge, Brave)" -ForegroundColor White
        Write-Host "  [ALL_NETWORK]    Network & Forensics (Wireshark, IP Scanner, Nmap, OpenVPN)" -ForegroundColor White
        Write-Host "  [ALL_DEV]        Developer Pack (VS Code, Git, Python 3, PowerShell 7)" -ForegroundColor White
        Write-Host "  [ALL_ESSENTIALS] Standard Worker Essentials (Chrome, 7-Zip, Notepad++, VLC, Zoom)" -ForegroundColor White
        Write-Host "==========================================================================" -ForegroundColor Cyan
        
        $InputStr = Read-Host "`nEnter application numbers separated by commas (e.g. 1, 5, 8, 12, 16) or BUNDLE name"
        if (-not $InputStr -or $InputStr.Trim() -eq "") { exit }
        
        $CleanInput = $InputStr.Trim().ToUpper()
        if ($Bundles.ContainsKey($CleanInput)) {
            $BundleIds = $Bundles[$CleanInput]
            $SelectedApps = $Catalog | Where-Object { $_.Id -in $BundleIds }
        } else {
            $IdStrings = $CleanInput -split "," | ForEach-Object { $_.Trim() }
            $Ids = @()
            foreach ($Str in $IdStrings) { if ($Str -match "^\d+$") { $Ids += [int]$Str } }
            $SelectedApps = $Catalog | Where-Object { $_.Id -in $Ids }
        }

        # Execute console deployment loop
        $ReportsDir = Join-Path $PSScriptRoot "reports"
        if (-not (Test-Path $ReportsDir)) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null }
        $script:DeploymentResults = @()
        $TotalApps = $SelectedApps.Count
        $CurrentIdx = 0

        foreach ($App in $SelectedApps) {
            $CurrentIdx++
            Write-Host "[${CurrentIdx}/${TotalApps}] Installing $($App.Name)..." -ForegroundColor Yellow -NoNewline
            $StartTime = Get-Date; $Status = "Failed"; $ErrorMsg = "None"
            try {
                if ($PackageManager -eq "Winget") {
                    $InstallCmd = "winget install --id $($App.WingetID) --silent --accept-package-agreements --accept-source-agreements"
                    if ($ForceInstall) { $InstallCmd += " --force" }
                    $Output = Invoke-Expression $InstallCmd 2>&1 | Out-String
                    if ($LASTEXITCODE -eq 0 -or $Output -match "Successfully installed|already installed|No applicable update found") {
                        $Status = "Success"; Write-Host " [OK - Winget]" -ForegroundColor Green
                    } else {
                        if (Get-Command choco -ErrorAction SilentlyContinue) {
                            $ChocoCmd = "choco install $($App.ChocoID) -y --no-progress"
                            $Output = Invoke-Expression $ChocoCmd 2>&1 | Out-String
                            if ($LASTEXITCODE -eq 0 -or $Output -match "already installed|The install of $($App.ChocoID) was successful") {
                                $Status = "Success (Choco Fallback)"; Write-Host " [OK - Choco]" -ForegroundColor Green
                            } else { $Status = "Failed"; $ErrorMsg = "Both Winget and Choco failed."; Write-Host " [FAILED]" -ForegroundColor Red }
                        } else { $Status = "Failed"; $ErrorMsg = "Winget exit code $LASTEXITCODE"; Write-Host " [FAILED]" -ForegroundColor Red }
                    }
                } elseif ($PackageManager -eq "Chocolatey") {
                    $ChocoCmd = "choco install $($App.ChocoID) -y --no-progress"
                    $Output = Invoke-Expression $ChocoCmd 2>&1 | Out-String
                    if ($LASTEXITCODE -eq 0 -or $Output -match "already installed|The install of $($App.ChocoID) was successful") {
                        $Status = "Success"; Write-Host " [OK - Choco]" -ForegroundColor Green
                    } else { $Status = "Failed"; $ErrorMsg = "Choco exit code $LASTEXITCODE"; Write-Host " [FAILED]" -ForegroundColor Red }
                }
            } catch { $Status = "Error"; $ErrorMsg = $_.Exception.Message; Write-Host " [ERROR: $ErrorMsg]" -ForegroundColor Red }
            
            $Duration = ((Get-Date) - $StartTime).TotalSeconds
            $script:DeploymentResults += [PSCustomObject]@{
                Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); Category = $App.Category; Name = $App.Name
                PackageID = if ($PackageManager -eq "Winget") { $App.WingetID } else { $App.ChocoID }
                Status = $Status; DurationSec = [math]::Round($Duration, 1); ErrorMessage = $ErrorMsg
            }
        }
    }
}

if ($DeploymentResults.Count -eq 0) { exit }

# ---------------------------------------------------------
# 6. GENERATE CSV AUDIT LOG
# ---------------------------------------------------------
$ReportsDir = Join-Path $PSScriptRoot "reports"
$CsvPath = Join-Path $ReportsDir "deployment_history.csv"
$AppendCsv = Test-Path $CsvPath
$DeploymentResults | Export-Csv -Path $CsvPath -NoTypeInformation -Append:$AppendCsv -Force
Write-Host "`n[+] Deployment history recorded in: $CsvPath" -ForegroundColor Green

# ---------------------------------------------------------
# 7. GENERATE SELF-CONTAINED DARK-MODE HTML REPORT
# ---------------------------------------------------------
$HtmlPath = Join-Path $ReportsDir "deployment_report.html"
$SuccessCount = ($DeploymentResults | Where-Object { $_.Status -like "*Success*" }).Count
$FailCount    = ($DeploymentResults | Where-Object { $_.Status -notlike "*Success*" }).Count

$RowsHtml = ""
foreach ($Res in $DeploymentResults) {
    $BadgeClass = if ($Res.Status -like "*Success*") { "badge-success" } else { "badge-danger" }
    $RowsHtml += "<tr><td>$($Res.Timestamp)</td><td><span class=`"category-tag`">$($Res.Category)</span></td><td style=`"font-weight: 600; color: #f8fafc;`">$($Res.Name)</td><td style=`"font-family: monospace; color: #38bdf8;`">$($Res.PackageID)</td><td><span class=`"badge $BadgeClass`">$($Res.Status)</span></td><td>$($Res.DurationSec)s</td><td style=`"color: #f87171; font-size: 0.85rem;`">$($Res.ErrorMessage)</td></tr>`n"
}

$HtmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OmviHub Cloud Software Deployment Report</title>
    <style>
        :root {
            --bg-primary: #0f172a;
            --bg-secondary: #1e293b;
            --bg-card: #334155;
            --text-main: #f8fafc;
            --text-muted: #94a3b8;
            --accent-blue: #38bdf8;
            --accent-green: #22c55e;
            --accent-red: #ef4444;
            --accent-purple: #c084fc;
        }
        body {
            font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
            background-color: var(--bg-primary);
            color: var(--text-main);
            margin: 0;
            padding: 2rem;
            line-height: 1.5;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        .header {
            background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
            border-left: 5px solid var(--accent-purple);
            padding: 2rem; border-radius: 0.75rem;
            box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.5);
            margin-bottom: 2rem; display: flex; justify-content: space-between; align-items: center;
        }
        .header h1 { margin: 0; font-size: 1.8rem; color: var(--text-main); display: flex; align-items: center; gap: 0.75rem; }
        .header p { margin: 0.5rem 0 0 0; color: var(--text-muted); font-size: 0.95rem; }
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 1.5rem; margin-bottom: 2rem; }
        .stat-card {
            background-color: var(--bg-secondary); padding: 1.5rem; border-radius: 0.75rem;
            border-top: 4px solid var(--accent-blue); box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.3);
        }
        .stat-card.success { border-color: var(--accent-green); }
        .stat-card.danger { border-color: var(--accent-red); }
        .stat-card h3 { margin: 0; font-size: 0.85rem; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.05em; }
        .stat-card .value { font-size: 2.2rem; font-weight: 700; margin-top: 0.5rem; color: var(--text-main); }
        .section-title { font-size: 1.3rem; margin-bottom: 1rem; color: var(--accent-blue); border-bottom: 2px solid var(--bg-card); padding-bottom: 0.5rem; }
        table {
            width: 100%; border-collapse: collapse; background-color: var(--bg-secondary);
            border-radius: 0.75rem; overflow: hidden; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.3); margin-bottom: 2rem;
        }
        th, td { padding: 1rem; text-align: left; border-bottom: 1px solid var(--bg-card); }
        th { background-color: #0b1120; color: var(--text-muted); font-weight: 600; font-size: 0.85rem; text-transform: uppercase; letter-spacing: 0.05em; }
        tr:hover { background-color: rgba(255, 255, 255, 0.03); }
        .badge { padding: 0.35rem 0.75rem; border-radius: 9999px; font-size: 0.75rem; font-weight: 700; text-transform: uppercase; display: inline-block; }
        .badge-success { background-color: rgba(34, 197, 94, 0.2); color: #4ade80; border: 1px solid rgba(34, 197, 94, 0.4); }
        .badge-danger { background-color: rgba(239, 68, 68, 0.2); color: #f87171; border: 1px solid rgba(239, 68, 68, 0.4); }
        .category-tag { background-color: var(--bg-card); color: var(--text-main); padding: 0.25rem 0.6rem; border-radius: 0.375rem; font-size: 0.8rem; }
        .footer { text-align: center; color: var(--text-muted); font-size: 0.85rem; margin-top: 3rem; padding-top: 1.5rem; border-top: 1px solid var(--bg-card); }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div>
                <h1>OmviHub Cloud Software Deployment Report</h1>
                <p>Ninite-Style Hybrid CDN Package Deployment Command Center</p>
            </div>
            <div style="text-align: right;">
                <p style="color: var(--text-main); font-weight: 600;">$env:COMPUTERNAME</p>
                <p style="font-size: 0.85rem;">Engine: $PackageManager</p>
            </div>
        </div>

        <div class="stats-grid">
            <div class="stat-card">
                <h3>Total Processed</h3>
                <div class="value">$TotalApps</div>
            </div>
            <div class="stat-card success">
                <h3>Successful Deploys</h3>
                <div class="value" style="color: var(--accent-green);">$SuccessCount</div>
            </div>
            <div class="stat-card danger">
                <h3>Failed / Errors</h3>
                <div class="value" style="color: var(--accent-red);">$FailCount</div>
            </div>
        </div>

        <div class="section-title">Itemized Deployment Log</div>
        <table>
            <thead>
                <tr>
                    <th>Timestamp</th>
                    <th>Category</th>
                    <th>Application Name</th>
                    <th>Package Identifier</th>
                    <th>Status</th>
                    <th>Duration</th>
                    <th>Error Detail</th>
                </tr>
            </thead>
            <tbody>
                $RowsHtml
            </tbody>
        </table>

        <div class="footer">
            Generated by OmviHub Windows & Windows Server IT Administration Toolkit [Option 16] &bull; 100% Offline-Compatible Report
        </div>
    </div>
</body>
</html>
"@

$HtmlContent | Out-File -FilePath $HtmlPath -Encoding utf8 -Force
Write-Host "[+] HTML deployment dashboard generated: $HtmlPath" -ForegroundColor Green

if (-not $NoGUI) {
    Start-Process $HtmlPath
} else {
    Write-Host "`nWould you like to open the HTML deployment dashboard now? [Y/N]" -ForegroundColor Yellow
    $OpenChoice = Read-Host
    if ($OpenChoice -eq "Y" -or $OpenChoice -eq "y") { Start-Process $HtmlPath }
}
