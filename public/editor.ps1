# ===================================
# SAP GUI Theme Changer Script
# Author: Le Thuc Thanh Tu
# Github: https://github.com/lethucthanhtu/
# ===================================

# Define file paths
$SourceFile = "$env:APPDATA\SAP\SAP GUI\ABAP Editor\abap_spec.xml"
$BackupFile = "$env:APPDATA\SAP\SAP GUI\ABAP Editor\abap_spec.previous_theme.xml"

# Define theme URLs
$PrimaryThemesUrl = "https://sap.lttt.dev/themes"
$FallbackThemesUrl = "https://letu-sap.vercel.app/themes"

# Function: Format display name
function Format-ThemeName {
    param ($FileName)
    return ($FileName -replace "_theme.xml", "" -replace "_", " ")
}

# Function: Backup current theme
function Backup-CurrentTheme {
    if (Test-Path $SourceFile) {
        Copy-Item -Path $SourceFile -Destination $BackupFile -Force
    }
}

# Function: Get local themes
function Get-LocalThemes {
    param ($ThemesFolder)
    if (-not (Test-Path $ThemesFolder)) {
        return @()
    }
    return Get-ChildItem -Path $ThemesFolder -Filter "*.xml" | Select-Object -ExpandProperty Name
}

# Function: Get remote themes
function Get-RemoteThemes {
    param ($ThemesUrl)
    try {
        $ThemesJsonUrl = "$ThemesUrl/themes.json"
        $ThemesList = Invoke-RestMethod -Uri $ThemesJsonUrl -ErrorAction Stop
        return @{ Success = $true; Files = $ThemesList.themes }
    } catch {
        return @{ Success = $false; Files = @() }
    }
}

# Function: Apply theme from local
function Apply-LocalTheme {
    param ($ThemesFolder, $SelectedFile)
    try {
        Backup-CurrentTheme
        $ThemeFilePath = Join-Path -Path $ThemesFolder -ChildPath $SelectedFile
        Copy-Item -Path $ThemeFilePath -Destination $SourceFile -Force
        Write-Host ""
        Write-Host "Changed theme to '$(Format-ThemeName $SelectedFile)' successfully."
        Write-Host "Please restart SAP GUI for changes to take effect."
    } catch {
        Write-Host "Error: Failed to apply local theme."
    }
}

# Function: Apply theme from remote
function Apply-RemoteTheme {
    param ($ThemesUrl, $SelectedFile)
    try {
        Backup-CurrentTheme
        $ThemeUrl = "$ThemesUrl/$SelectedFile"
        Invoke-WebRequest -Uri $ThemeUrl -OutFile $SourceFile -UseBasicParsing
        Write-Host ""
        Write-Host "Changed theme to '$(Format-ThemeName $SelectedFile)' successfully."
        Write-Host "Please restart SAP GUI for changes to take effect."
    } catch {
        Write-Host "Error: Failed to apply remote theme."
    }
}

# Function: Layout calculations
function Get-Layout {
    param (
        [string]$Title,
        [array]$Themes,
        [int]$MaxNameLengthFromThemes
    )

    $defaultLength = $Title.Length - 14 # Magic number
    $maxNameLength = [Math]::Max($defaultLength, $MaxNameLengthFromThemes)
    $maxIndexHex = "{0:X}" -f $Themes.Count
    $optionPrefixLength = ("[${maxIndexHex}] ").Length
    $lineLength = $optionPrefixLength + $maxNameLength + 10
    if ($lineLength -lt $defaultLength) { $lineLength = $defaultLength }

    return @{
        MaxNameLength = $maxNameLength
        EqualsLine = "=" * $lineLength
        DashLine = "-" * $lineLength
    }
}

# Function: Show main menu (reusable)
function Show-MainMenu {
    param (
        [string]$Title,
        [array]$Themes,
        [hashtable]$ThemeDict = @{},
        [string]$Mode,
        [int]$MaxNameLength,
        [string]$EqualsLine,
        [string]$DashLine
    )

    do {
        Clear-Host
        Write-Host $Title
        Write-Host $EqualsLine
        Write-Host "[0] Exit program"
        Write-Host "[1] Rollback to previous theme"

        if ($Mode -eq "remote") {
            Write-Host "[2] Specify local themes folder"
        }

        Write-Host $DashLine
        Write-Host "Available themes:"

        for ($i = 0; $i -lt $Themes.Count; $i++) {
            $entry = $Themes[$i]
            $displayName = Format-ThemeName $entry.Name
            $optionHex = "{0:X}" -f ($i + 3) # offset options by 3

            $sources = $ThemeDict[$displayName] | Select-Object -ExpandProperty Source
            $isDuplicate = ($sources | Select-Object -Unique).Count -gt 1
            $tag = if ($isDuplicate) { "($($entry.Source))" } else { "" }

            $paddedName = $displayName.PadRight($MaxNameLength + 2)
            Write-Host ("[{0}] {1} {2}" -f $optionHex, $paddedName, $tag)
        }
        Write-Host $EqualsLine

        $Choice = Read-Host "Enter your option"

        if ($Choice -eq "0") { return "exit" }
        elseif ($Choice -eq "1") { return "rollback" }
        elseif ($Choice -eq "2" -and $Mode -eq "remote") { return "specifyLocal" }
        elseif ($Choice -match "^[0-9A-Fa-f]+$") {
            $ChoiceDec = [Convert]::ToInt32($Choice, 16) - 3
            if ($ChoiceDec -ge 0 -and $ChoiceDec -lt $Themes.Count) { return $ChoiceDec }
        }

        Write-Host "Invalid input. Please try again."
        Start-Sleep -Seconds 1
    } while ($true)
}

# ===================================
# Detect local vs remote execution using switch
# ===================================

switch (-not [string]::IsNullOrEmpty($MyInvocation.MyCommand.Path)) {
    $true {
        # Local execution
        $Mode = "local"
        $Title = "SAP GUI Theme Changer (Local Execution)"
        $ThemesFolder = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "themes"
        $LocalThemes = Get-LocalThemes -ThemesFolder $ThemesFolder

        # Fetch remote themes
        $RemoteResult = Get-RemoteThemes -ThemesUrl $PrimaryThemesUrl
        if (-not $RemoteResult.Success) {
            $RemoteResult = Get-RemoteThemes -ThemesUrl $FallbackThemesUrl
        }
        $RemoteThemes = $RemoteResult.Files

        # Merge themes
        $ThemeDict = @{}
        foreach ($theme in $LocalThemes) {
            $displayName = Format-ThemeName $theme
            if (-not $ThemeDict.ContainsKey($displayName)) { $ThemeDict[$displayName] = @() }
            $ThemeDict[$displayName] += @{ Name = $theme; Source = "local"; Path = $ThemesFolder }
        }
        foreach ($theme in $RemoteThemes) {
            $displayName = Format-ThemeName $theme
            if (-not $ThemeDict.ContainsKey($displayName)) { $ThemeDict[$displayName] = @() }
            $ThemeDict[$displayName] += @{ Name = $theme; Source = "remote" }
        }

        $Themes = @()
        foreach ($key in ($ThemeDict.Keys | Sort-Object)) {
            $Themes += $ThemeDict[$key] | Sort-Object Source
        }
    }

    default {
        # Remote execution only
        $Mode = "remote"
        $Title = "SAP GUI Theme Changer (Remote Execution)"
        $RemoteResult = Get-RemoteThemes -ThemesUrl $PrimaryThemesUrl
        if (-not $RemoteResult.Success) {
            $RemoteResult = Get-RemoteThemes -ThemesUrl $FallbackThemesUrl
            if (-not $RemoteResult.Success) {
                Write-Host "Error: Could not retrieve themes list from both primary and fallback URLs."
                exit 1
            }
        }

        $RemoteThemes = $RemoteResult.Files | Sort-Object

        # Build ThemeDict
        $ThemeDict = @{}
        foreach ($theme in $RemoteThemes) {
            $displayName = Format-ThemeName $theme
            if (-not $ThemeDict.ContainsKey($displayName)) { $ThemeDict[$displayName] = @() }
            $ThemeDict[$displayName] += @{ Name = $theme; Source = "remote" }
        }

        $Themes = @()
        foreach ($key in ($ThemeDict.Keys | Sort-Object)) {
            $Themes += $ThemeDict[$key]
        }
    }
}

# Layout calculation
$maxNameLengthFromThemes = ($ThemeDict.Keys | ForEach-Object { Format-ThemeName $_ } | Measure-Object -Property Length -Maximum).Maximum
$layout = Get-Layout -Title $Title -Themes $Themes -MaxNameLengthFromThemes $maxNameLengthFromThemes

# Show menu loop
do {
    $result = Show-MainMenu -Title $Title -Themes $Themes -ThemeDict $ThemeDict -Mode $Mode -MaxNameLength $layout.MaxNameLength -EqualsLine $layout.EqualsLine -DashLine $layout.DashLine

    if ($result -eq "exit") { exit }
    elseif ($result -eq "rollback") {
        if (Test-Path $BackupFile) {
            Copy-Item -Path $BackupFile -Destination $SourceFile -Force
            Write-Host "Rolled back to previous theme successfully."
            Write-Host "Please restart SAP GUI for changes to take effect."
        } else {
            Write-Host "No backup theme found."
        }
        exit
    }
    elseif ($result -eq "specifyLocal" -and $Mode -eq "remote") {
        $UserLocalPath = Read-Host "Enter full path to your local themes folder"
        if (Test-Path $UserLocalPath) {
            $UserLocalThemes = Get-ChildItem -Path $UserLocalPath -Filter "*.xml" | Select-Object -ExpandProperty Name
            foreach ($theme in $UserLocalThemes) {
                $displayName = Format-ThemeName $theme
                if (-not $ThemeDict.ContainsKey($displayName)) { $ThemeDict[$displayName] = @() }
                $ThemeDict[$displayName] += @{ Name = $theme; Source = "local"; Path = $UserLocalPath }
            }
            # Rebuild Themes
            $Themes = @()
            foreach ($key in ($ThemeDict.Keys | Sort-Object)) {
                $Themes += $ThemeDict[$key] | Sort-Object Source
            }
        } else {
            Write-Host "Invalid path. Continuing with existing themes."
        }
    }
    elseif ($null -ne $result) {
        $Selected = $Themes[$result]
        if ($Selected.Source -eq "local") {
            Apply-LocalTheme -ThemesFolder $Selected.Path -SelectedFile $Selected.Name
        } else {
            $UsingUrl = ($RemoteResult.Success) ? $PrimaryThemesUrl : $FallbackThemesUrl
            Apply-RemoteTheme -ThemesUrl $UsingUrl -SelectedFile $Selected.Name
        }
        exit
    }
} while ($true)

Write-Host ""
Write-Host "You can close this window now."
