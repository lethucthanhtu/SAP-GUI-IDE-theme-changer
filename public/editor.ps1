# Paths
$SourceFile = "$env:APPDATA\SAP\SAP GUI\ABAP Editor\abap_spec.xml"
$BackupFile = "$env:APPDATA\SAP\SAP GUI\ABAP Editor\abap_spec.previous_theme.xml"
$ThemesUrl = "https://letu-sap.vercel.app/themes"
$ThemesJson = "$ThemesUrl/themes.json"

# Fetch available themes
try {
    $ThemesList = Invoke-RestMethod -Uri $ThemesJson
    $Files = $ThemesList.themes
} catch {
    Write-Host "Error: Could not retrieve themes list."
    exit 1
}

# Function to format display name
function Format-ThemeName {
    param ($FileName)
    return ($FileName -replace "_theme.xml", "" -replace "_", " ")
}

# Backup current theme before changing
function Backup-CurrentTheme {
    if (Test-Path $SourceFile) {
        Copy-Item -Path $SourceFile -Destination $BackupFile -Force
    }
}

# Apply selected theme
function Apply-Theme {
    param ($SelectedFile)
    try {
        Backup-CurrentTheme
        $ThemeUrl = "$ThemesUrl/$SelectedFile"
        Invoke-WebRequest -Uri $ThemeUrl -OutFile $SourceFile -UseBasicParsing
        Write-Host "Changed theme to '$(Format-ThemeName $SelectedFile)' successfully!"
        Write-Host "Please restart SAP GUI for changes to take effect."
    } catch {
        Write-Host "Error: Failed to apply theme."
    }
}

# Rollback to previous theme
function Rollback-Theme {
    if (Test-Path $BackupFile) {
        Copy-Item -Path $BackupFile -Destination $SourceFile -Force
        Write-Host "Rolled back to previous theme successfully!"
        Write-Host "Please restart SAP GUI for changes to take effect."
    } else {
        Write-Host "No previous theme backup found."
    }
}

# Main Menu
do {
    Clear-Host
    Write-Host "==============================="
    Write-Host "[0] Exit program"

    # Show rollback option if backup exists
    if (Test-Path $BackupFile) {
        Write-Host "[R] Rollback to previous theme"
    }

    Write-Host "-------------------------------"
    Write-Host "Available themes:"

    for ($i = 0; $i -lt $Files.Count; $i++) {
        Write-Host "[$($i + 1)] $(Format-ThemeName $Files[$i])"
    }
    Write-Host "==============================="

    $Choice = Read-Host "Enter your option"

    if ($Choice -eq "0") {
        break
    } elseif ($Choice -match "^[Rr]$" -and (Test-Path $BackupFile)) {
        Rollback-Theme
        break
    } elseif ($Choice -match "^[0-9]+$" -and $Choice -ge 1 -and $Choice -le $Files.Count) {
        $SelectedFile = $Files[$Choice - 1]
        Apply-Theme $SelectedFile
        break
    } else {
        Write-Host "Invalid option. Please try again."
        Start-Sleep -Seconds 2
    }
} while ($true)

Read-Host "Press Enter to exit"
