# ===================================
# SAP GUI Theme Changer Script
# Author: Le Thuc Thanh Tu
# GitHub: https://github.com/lethucthanhtu/SAP-GUI-IDE-theme-changer
# License: GPL-3.0
# Version: 1.0.0
# ===================================
# This script allows switching SAP GUI ABAP Editor themes via local or remote XML theme files.
# It supports:
#   - Listing and merging local & remote themes
#   - Base-16 or base-10 option selection
#   - Rollback to previous theme
#   - Specifying local folder during remote use
#
# DISCLAIMER:
# Ensure your XML files are valid SAP GUI themes. Applying malformed files may cause UI issues.
#
# CONTRIBUTING:
# Feel free to fork, create pull requests, and suggest enhancements via GitHub.
# ===================================

# ===================================
# CONFIGURATION
# ===================================

# Toggle using fallback backup server (true/false)
$UseBackupServer = $true

# Toggle merging remote themes with local themes (true/false)
$MergeRemoteWithLocal = $true

# Option numbering base: "16" for hexadecimal, "10" for decimal
$OptionNumberingBase = 16

# ===================================
# Define theme URLs
# ===================================

# For those who want to sef-host the themes, you can use your own URLs.
# The URLs should point to a JSON file containing the list of themes.
# Change to your own URL if needed
$PrimaryThemesUrl = "https://sap.lttt.dev/themes"

# Fallback URL in case the primary URL fails
# This is used when the primary URL is not reachable or returns an error
$FallbackThemesUrl = "https://letu-sap.vercel.app/themes"

# ===================================
# Define file paths
# ===================================

# Source file for SAP GUI ABAP Editor theme
# This is the file that will be modified to change the theme
$SourceFile = "$env:APPDATA\SAP\SAP GUI\ABAP Editor\abap_spec.xml"

# Backup file for the current theme
# This file will be created when the current theme is backed up
# Change this path if you want to store backups in a different location
# It is recommended to keep it in the same folder as the source file
$BackupFile = "$env:APPDATA\SAP\SAP GUI\ABAP Editor\abap_spec.previous_theme.xml"

# ===================================
# Function: Format display name
# ===================================

function Format-ThemeName {
    param ($FileName)
    return ($FileName -replace "_theme.xml", "" -replace "_", " ")
}

# ===================================
# Function: Backup current theme
# ===================================

function Backup-CurrentTheme {
    if (Test-Path $SourceFile) {
        Copy-Item -Path $SourceFile -Destination $BackupFile -Force
    }
}

# ===================================
# Function: Get local themes
# ===================================

function Get-LocalThemes {
    param ($ThemesFolder)
    if (-not (Test-Path $ThemesFolder)) {
        return @()
    }
    return Get-ChildItem -Path $ThemesFolder -Filter "*.xml" | Select-Object -ExpandProperty Name
}

# ===================================
# Function: Get remote themes
# ===================================

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

# ===================================
# Function: Apply theme from local
# ===================================

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

# ===================================
# Function: Apply theme from remote
# ===================================

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

# ===================================
# Function: Layout calculations
# ===================================

function Get-Layout {
    param (
        [string]$Title,
        [array]$Themes,
        [int]$MaxNameLengthFromThemes
    )

    $defaultLength = $Title.Length - 14
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

# ===================================
# Function: Show main menu (reusable)
# ===================================

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

        if (Test-Path $BackupFile) {
            Write-Host "[1] Rollback to previous theme"
        }

        if ($Mode -eq "remote") {
            Write-Host "[2] Specify local themes folder"
        }

        Write-Host $DashLine
        Write-Host "Available themes:"

        for ($i = 0; $i -lt $Themes.Count; $i++) {
            $entry = $Themes[$i]
            $displayName = Format-ThemeName $entry.Name

            if ($OptionNumberingBase -eq 16) {
                $optionDisplay = "{0:X}" -f ($i + 3)
            } else {
                $optionDisplay = ($i + 3).ToString()
            }

            try {
                $entry = $ThemeDict[$displayName]

                if ($entry -and $entry.PSObject.Properties.Name -contains "Source") {
                    $sources = $entry.Source
                    $isDuplicate = ($sources | Select-Object -Unique).Count -gt 1
                    $tag = if ($isDuplicate) { "($($entry.Source))" } else { "" }
                } else {
                    $tag = ""
                }

                $paddedName = $displayName.PadRight($MaxNameLength + 2)
                Write-Host ("[{0}] {1} {2}" -f $optionDisplay, $paddedName, $tag)
            }
            catch {
                $paddedName = $displayName.PadRight($MaxNameLength + 2)
                Write-Host ("[{0}] {1}" -f $optionDisplay, $paddedName)
            }
        }
        Write-Host $EqualsLine

        $Choice = Read-Host "Enter your option"

        if ($Choice -eq "0") { return "exit" }
        elseif ($Choice -eq "1") {
            if (Test-Path $BackupFile) { return "rollback" }
            else {
                Write-Host "No previous theme backup found."
                Start-Sleep -Seconds 2
            }
        }
        elseif ($Choice -eq "2" -and $Mode -eq "remote") { return "specifyLocal" }
        elseif ($Choice -match "^[0-9A-Fa-f]+$") {
            if ($OptionNumberingBase -eq 16) {
                $ChoiceDec = [Convert]::ToInt32($Choice, 16) - 3
            } else {
                $ChoiceDec = [int]$Choice - 3
            }
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
        if (-not $RemoteResult.Success -and $UseBackupServer) {
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

        if ($MergeRemoteWithLocal) {
            foreach ($theme in $RemoteThemes) {
                $displayName = Format-ThemeName $theme
                if (-not $ThemeDict.ContainsKey($displayName)) { $ThemeDict[$displayName] = @() }
                $ThemeDict[$displayName] += @{ Name = $theme; Source = "remote" }
            }
        }

        $Themes = @()
        foreach ($key in ($ThemeDict.Keys | Sort-Object)) {
            $Themes += $ThemeDict[$key] | Sort-Object Source
        }
    }

    default {
        # Remote execution
        $Mode = "remote"
        $Title = "SAP GUI Theme Changer (Remote Execution)"
        $RemoteResult = Get-RemoteThemes -ThemesUrl $PrimaryThemesUrl
        if (-not $RemoteResult.Success -and $UseBackupServer) {
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

# ===================================
# Layout calculation
# ===================================

$maxNameLengthFromThemes = ($ThemeDict.Keys | ForEach-Object { Format-ThemeName $_ } | Measure-Object -Property Length -Maximum).Maximum
$layout = Get-Layout -Title $Title -Themes $Themes -MaxNameLengthFromThemes $maxNameLengthFromThemes

# ===================================
# Show menu loop
# ===================================

do {
    $result = Show-MainMenu -Title $Title -Themes $Themes -ThemeDict $ThemeDict -Mode $Mode -MaxNameLength $layout.MaxNameLength -EqualsLine $layout.EqualsLine -DashLine $layout.DashLine

    if ($result -eq "exit") { exit }
    elseif ($result -eq "rollback") {
        Copy-Item -Path $BackupFile -Destination $SourceFile -Force
        Write-Host "Rolled back to previous theme successfully."
        Write-Host "Please restart SAP GUI for changes to take effect."
        Read-Host "Press Enter to exit"
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
            Start-Sleep -Seconds 1
        }
    }
    elseif ($null -ne $result) {
        $Selected = $Themes[$result]
        if ($Selected.Source -eq "local") {
            Apply-LocalTheme -ThemesFolder $Selected.Path -SelectedFile $Selected.Name
        } else {
            # $UsingUrl = ($RemoteResult.Success) ? $PrimaryThemesUrl : $FallbackThemesUrl
            if ($RemoteResult.Success) {
                $UsingUrl = $PrimaryThemesUrl
            } else {
                $UsingUrl = $FallbackThemesUrl
            }
            Apply-RemoteTheme -ThemesUrl $UsingUrl -SelectedFile $Selected.Name
        }

        # Show selected theme confirmation and prompt before exit
        Write-Host ""
        Write-Host "Theme '$(Format-ThemeName $Selected.Name)' applied successfully."
        Write-Host "Please restart SAP GUI for changes to take effect."
        Read-Host "Press Enter to exit"
        exit
    }
} while ($true)
