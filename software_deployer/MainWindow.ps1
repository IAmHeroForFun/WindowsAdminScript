# ==============================================================================
# SCRIPT: MainWindow.ps1
# PURPOSE: Connects WPF XAML controls to PowerShell event handlers, manages
#          Winget package installations, and updates UI without freezing.
# ==============================================================================

# Ensure script is running from its own directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptDir

# 1. Import project modules
Import-Module (Join-Path $scriptDir "Modules\Logger.psm1") -Force
Import-Module (Join-Path $scriptDir "Modules\Winget.psm1") -Force
Import-Module (Join-Path $scriptDir "Modules\AppManager.psm1") -Force

# 2. Helper function to pump WPF event loop and prevent GUI freezing during synchronous loops
function Update-WpfGui {
    $frame = New-Object System.Windows.Threading.DispatcherFrame
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
        [System.Windows.Threading.DispatcherPriority]::Background,
        [System.Action][scriptblock]{ $frame.Continue = $false }
    ) | Out-Null
    [System.Windows.Threading.Dispatcher]::PushFrame($frame)
}

# 3. Load XAML GUI definition
$xamlPath = Join-Path $scriptDir "MainWindow.xaml"
if (-not (Test-Path $xamlPath)) {
    Write-Host "[CRITICAL] MainWindow.xaml not found at $xamlPath" -ForegroundColor Red
    exit 1
}

[xml]$xaml = Get-Content -Path $xamlPath -Raw -Encoding UTF8
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# 4. Connect named XAML elements to script variables
$HeaderPanel     = $window.FindName("HeaderPanel")
$BtnMinimize     = $window.FindName("BtnMinimize")
$BtnMaximize     = $window.FindName("BtnMaximize")
$BtnClose        = $window.FindName("BtnClose")

$LstApps         = $window.FindName("LstApps")
$TxtSearch       = $window.FindName("TxtSearch")
$CmbCategory     = $window.FindName("CmbCategory")
$BtnSelectAll    = $window.FindName("BtnSelectAll")
$BtnDeselectAll  = $window.FindName("BtnDeselectAll")
$BtnRefresh      = $window.FindName("BtnRefresh")
$BtnInstall      = $window.FindName("BtnInstall")
$BtnUpdate       = $window.FindName("BtnUpdate")
$PrgDeploy       = $window.FindName("PrgDeploy")
$TxtStatus       = $window.FindName("TxtStatus")
$TxtLog          = $window.FindName("TxtLog")
$TxtWingetStatus = $window.FindName("TxtWingetStatus")
$ImgWingetStatus = $window.FindName("ImgWingetStatus")

# 5. Hook up Window Controls (Minimize / Maximize / Close & Draggable Header)
if ($HeaderPanel) {
    $HeaderPanel.Add_MouseLeftButtonDown({
        param($sender, $e)
        if ($e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Pressed) {
            try { $window.DragMove() } catch {}
        }
    })
}

if ($BtnMinimize) {
    $BtnMinimize.Add_Click({ $window.WindowState = [System.Windows.WindowState]::Minimized })
}

if ($BtnMaximize) {
    $BtnMaximize.Add_Click({
        if ($window.WindowState -eq [System.Windows.WindowState]::Maximized) {
            $window.WindowState = [System.Windows.WindowState]::Normal
            $BtnMaximize.Content = "🗖"
        } else {
            $window.WindowState = [System.Windows.WindowState]::Maximized
            $BtnMaximize.Content = "🗗"
        }
    })
}

if ($BtnClose) {
    $BtnClose.Add_Click({ $window.Close() })
}

# 6. Initialize Logging system with real-time XAML Textbox callback
$logsDir = Join-Path $scriptDir "Logs"
Initialize-Logger -LogDir $logsDir -GuiCallback {
    param([string]$msg)
    if ($TxtLog) {
        $TxtLog.AppendText($msg + "`r`n")
        $TxtLog.ScrollToEnd()
        Update-WpfGui
    }
}

# 7. Load Application Catalog from Apps.json (104 Applications across 10 Categories)
$appsJsonPath = Join-Path $scriptDir "Apps.json"
$script:Catalog = Get-AppCatalog -CatalogPath $appsJsonPath

# Populate category filter ComboBox
$categories = Get-AppCategories -Catalog $script:Catalog
$CmbCategory.ItemsSource = $categories
$CmbCategory.SelectedIndex = 0

# Helper to filter and refresh ListView based on Search and Category selection
function Refresh-CatalogView {
    $query = $TxtSearch.Text.Trim().ToLower()
    $selectedCat = $CmbCategory.SelectedItem

    $filtered = $script:Catalog | Where-Object {
        $matchCat = ($selectedCat -eq "All Categories" -or $_.Category -eq $selectedCat)
        $matchName = (-not $query -or $_.Name.ToLower().Contains($query) -or $_.Category.ToLower().Contains($query) -or $_.Id.ToLower().Contains($query))
        return ($matchCat -and $matchName)
    }

    $LstApps.ItemsSource = $filtered
    $LstApps.Items.Refresh()
}

# 8. Hook up Filter Toolbar Events
$TxtSearch.Add_TextChanged({ Refresh-CatalogView })
$CmbCategory.Add_SelectionChanged({ Refresh-CatalogView })

$BtnSelectAll.Add_Click({
    foreach ($app in $LstApps.ItemsSource) { $app.IsSelected = $true }
    $LstApps.Items.Refresh()
})

$BtnDeselectAll.Add_Click({
    foreach ($app in $LstApps.ItemsSource) { $app.IsSelected = $false }
    $LstApps.Items.Refresh()
})

# 9. Hook up Refresh & Status Synchronization
function Sync-SystemStatus {
    $TxtStatus.Text = "Scanning system for installed applications via Winget..."
    $PrgDeploy.Value = 20
    Update-WpfGui

    $wingetOk = Test-WingetAvailable
    if ($wingetOk) {
        $TxtWingetStatus.Text = "Winget Ready"
        $ImgWingetStatus.Fill = "#22C55E" # Green
    } else {
        $TxtWingetStatus.Text = "Winget Missing / Disabled"
        $ImgWingetStatus.Fill = "#EF4444" # Red
        $TxtStatus.Text = "Error: Microsoft Winget is not available on this system!"
        return
    }

    $PrgDeploy.Value = 50
    Update-WpfGui

    # Perform bulk Winget list cache query
    $cache = Get-InstalledWingetPackages
    $PrgDeploy.Value = 80
    Update-WpfGui

    # Update catalog objects
    Update-AppStatus -Catalog $script:Catalog -WingetCache $cache
    Refresh-CatalogView

    $PrgDeploy.Value = 0
    $TxtStatus.Text = "System scan complete. Select applications to deploy from 100+ choices."
}

$BtnRefresh.Add_Click({ Sync-SystemStatus })

# 10. Hook up Installation Execution Engine
$BtnInstall.Add_Click({
    $selectedApps = $script:Catalog | Where-Object { $_.IsSelected -eq $true }
    $total = $selectedApps.Count

    if ($total -eq 0) {
        $TxtStatus.Text = "Please select at least one application to install!"
        Write-Log -Message "Installation attempted with 0 applications selected." -Level "WARN"
        return
    }

    # Disable controls during deployment
    $BtnInstall.IsEnabled = $false
    $BtnUpdate.IsEnabled = $false
    $BtnRefresh.IsEnabled = $false
    $PrgDeploy.Value = 0

    Write-Log -Message "Starting deployment batch for $total selected application(s)..." -Level "START"

    [int]$current = 0
    foreach ($app in $selectedApps) {
        $current++
        [double]$progressVal = ($current - 1) / $total * 100
        $PrgDeploy.Value = $progressVal
        $TxtStatus.Text = "[$current/$total] Processing: $($app.Name)..."
        Update-WpfGui

        # Skip if already installed
        if ($app.IsInstalled) {
            Write-Log -Message "Skipping $($app.Name) - Already installed on system." -Level "SKIP"
            $app.StatusText = "Skipped (Installed)"
            $app.StatusColor = "#4ADE80" # Light Green
            $LstApps.Items.Refresh()
            continue
        }

        # Update status to Installing
        $app.StatusText = "Installing..."
        $app.StatusColor = "#FACC15" # Yellow
        $LstApps.Items.Refresh()
        Update-WpfGui

        # Execute Winget Silent Install
        $res = Install-WingetPackage -Id $app.Id -Name $app.Name -GuiProgressCallback { Update-WpfGui }

        if ($res.Success) {
            $app.IsInstalled = $true
            $app.StatusText = "Installed"
            $app.StatusColor = "#22C55E" # Green
        } else {
            $app.StatusText = "Install Failed"
            $app.StatusColor = "#EF4444" # Red
        }

        $LstApps.Items.Refresh()
        $PrgDeploy.Value = ($current / $total * 100)
        Update-WpfGui
    }

    Write-Log -Message "Deployment batch completed!" -Level "DONE"
    $TxtStatus.Text = "✅ Deployment complete! Check activity log for details."
    $PrgDeploy.Value = 100

    # Re-enable controls
    $BtnInstall.IsEnabled = $true
    $BtnUpdate.IsEnabled = $true
    $BtnRefresh.IsEnabled = $true
})

# 11. Hook up Dedicated Update Installed Apps Engine
$BtnUpdate.Add_Click({
    $BtnInstall.IsEnabled = $false
    $BtnUpdate.IsEnabled = $false
    $BtnRefresh.IsEnabled = $false
    $PrgDeploy.Value = 30

    $TxtStatus.Text = "Running system-wide Winget upgrade for all installed applications..."
    Update-WpfGui

    $success = Update-WingetPackages -GuiProgressCallback { Update-WpfGui }

    if ($success) {
        $TxtStatus.Text = "✅ All installed applications updated successfully!"
        $PrgDeploy.Value = 100
    } else {
        $TxtStatus.Text = "❌ Upgrade operation completed with errors or warnings."
        $PrgDeploy.Value = 0
    }

    # Refresh status after update
    Sync-SystemStatus

    $BtnInstall.IsEnabled = $true
    $BtnUpdate.IsEnabled = $true
    $BtnRefresh.IsEnabled = $true
})

# 12. Perform initial scan on window load
$window.Add_Loaded({
    Sync-SystemStatus
})

# 13. Display WPF Window
$window.ShowDialog() | Out-Null
