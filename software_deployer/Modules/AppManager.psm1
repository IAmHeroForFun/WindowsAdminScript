# ==============================================================================
# MODULE: AppManager.psm1
# PURPOSE: Loads application catalog from JSON and synchronizes installation
#          status indicators against the Winget package cache.
# ==============================================================================

<#
.SYNOPSIS
    Reads Apps.json and converts each application into an observable PSCustomObject
    suitable for WPF ListView / DataGrid data binding.
.PARAMETER CatalogPath
    Absolute path to Apps.json.
#>
function Get-AppCatalog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CatalogPath
    )

    if (-not (Test-Path -Path $CatalogPath)) {
        Write-Log -Message "Error: Catalog file not found at $CatalogPath" -Level "ERROR"
        return @()
    }

    try {
        $rawJson = Get-Content -Path $CatalogPath -Raw -Encoding UTF8
        $jsonApps = $rawJson | ConvertFrom-Json

        $catalog = @()
        foreach ($app in $jsonApps) {
            $catalog += [PSCustomObject]@{
                IsSelected  = $false
                Id          = $app.Id
                Name        = $app.Name
                Category    = $app.Category
                Description = $app.Description
                IsInstalled = $false
                StatusText  = "Checking..."
                StatusColor = "#94A3B8"  # Slate / Gray
            }
        }

        Write-Log -Message "Successfully loaded $($catalog.Count) software definitions from Apps.json." -Level "INFO"
        return $catalog
    } catch {
        Write-Log -Message "Failed to parse Apps.json: $_" -Level "ERROR"
        return @()
    }
}

<#
.SYNOPSIS
    Extracts unique category names from the loaded application catalog.
.OUTPUTS
    Array of category strings starting with "All Categories".
#>
function Get-AppCategories {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Catalog
    )

    $categories = @("All Categories")
    $uniqueCats = $Catalog | Select-Object -ExpandProperty Category -Unique | Sort-Object
    $categories += $uniqueCats
    return $categories
}

<#
.SYNOPSIS
    Updates the installation status (.IsInstalled, .StatusText, .StatusColor) of each
    application object by matching against the installed Winget package cache.
#>
function Update-AppStatus {
    param(
        [Parameter(Mandatory = $true)][array]$Catalog,
        [Parameter(Mandatory = $true)][hashtable]$WingetCache
    )

    Write-Log -Message "Synchronizing catalog status against installed software cache..." -Level "INFO"
    
    foreach ($app in $Catalog) {
        $installed = Test-WingetPackageInstalled -Id $app.Id -Name $app.Name -InstalledCache $WingetCache
        $app.IsInstalled = $installed

        if ($installed) {
            $app.StatusText = "Installed"
            $app.StatusColor = "#22C55E"  # Vibrant Green
        } else {
            $app.StatusText = "Not Installed"
            $app.StatusColor = "#94A3B8"  # Muted Gray
        }
    }

    Write-Log -Message "Status synchronization complete." -Level "DONE"
}

Export-ModuleMember -Function Get-AppCatalog, Get-AppCategories, Update-AppStatus
