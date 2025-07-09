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
    return Get-ChildItem -Path $ThemesFolder -Filter "*_theme.xml" | Select-Object -ExpandProperty Name
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

# ===================================
# Detect local vs remote execution
# ===================================

switch (-not [string]::IsNullOrEmpty($MyInvocation.MyCommand.Path)) {
    $true {
        # Local execution
        $ThemesFolder = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "themes"
        $LocalThemes = Get-LocalThemes -ThemesFolder $ThemesFolder

        # Fetch remote themes
        $RemoteResult = Get-RemoteThemes -ThemesUrl $PrimaryThemesUrl
        if (-not $RemoteResult.Success) {
            $RemoteResult = Get-RemoteThemes -ThemesUrl $FallbackThemesUrl
        }
        $RemoteThemes = $RemoteResult.Files

        # Merge themes into a dictionary grouped by formatted name
        $ThemeDict = @{}
        foreach ($theme in $LocalThemes) {
            $displayName = Format-ThemeName $theme
            if (-not $ThemeDict.ContainsKey($displayName)) {
                $ThemeDict[$displayName] = @()
            }
            $ThemeDict[$displayName] += @{ Name = $theme; Source = "local" }
        }
        foreach ($theme in $RemoteThemes) {
            $displayName = Format-ThemeName $theme
            if (-not $ThemeDict.ContainsKey($displayName)) {
                $ThemeDict[$displayName] = @()
            }
            $ThemeDict[$displayName] += @{ Name = $theme; Source = "remote" }
        }

        # Build merged themes list sorted by display name then source
        $MergedThemes = @()
        foreach ($key in ($ThemeDict.Keys | Sort-Object)) {
            $entries = $ThemeDict[$key] | Sort-Object Source
            $MergedThemes += $entries
        }

        # Calculate layout lengths
        $defaultLine = "[R] Rollback to previous theme"
        $defaultLength = $defaultLine.Length - 15
        $maxNameLengthFromThemes = ($ThemeDict.Keys | ForEach-Object { Format-ThemeName $_ } | Measure-Object -Property Length -Maximum).Maximum
        $maxNameLength = [Math]::Max($defaultLength, $maxNameLengthFromThemes)

        $maxIndexHex = "{0:X}" -f $MergedThemes.Count
        $optionPrefixLength = ("[${maxIndexHex}] ").Length
        $lineLength = $optionPrefixLength + $maxNameLength + 10
        if ($lineLength -lt 30) { $lineLength = 30 } # Minimum line length

        $equalsLine = "=" * $lineLength
        $dashLine = "-" * $lineLength

        # Main Menu
        do {
            Clear-Host
            Write-Host "SAP GUI Theme Changer (Local Execution)"
            Write-Host $equalsLine
            Write-Host "[0] Exit program"

            if (Test-Path $BackupFile) {
                Write-Host "$defaultLine"
            }

            Write-Host $dashLine
            Write-Host "Available themes:"

            for ($i = 0; $i -lt $MergedThemes.Count; $i++) {
                $entry = $MergedThemes[$i]
                $displayName = Format-ThemeName $entry.Name
                $sources = $ThemeDict[$displayName] | Select-Object -ExpandProperty Source
                $isDuplicate = ($sources | Select-Object -Unique).Count -gt 1
                $tag = if ($isDuplicate) { "($($entry.Source))" } else { "" }

                $optionHex = "{0:X}" -f ($i + 1)
                $paddedName = $displayName.PadRight($maxNameLength + 2)
                Write-Host ("[{0}] {1} {2}" -f $optionHex, $paddedName, $tag)
            }
            Write-Host $equalsLine

            $Choice = Read-Host "Enter your option"

            if ($Choice -eq "0") {
                break
            } elseif ($Choice -match "^[Rr]$" -and (Test-Path $BackupFile)) {
                Copy-Item -Path $BackupFile -Destination $SourceFile -Force
                Write-Host "Rolled back to previous theme successfully."
                Write-Host "Please restart SAP GUI for changes to take effect."
                break
            } elseif ($Choice -match "^[0-9A-Fa-f]+$") {
                $ChoiceDec = [Convert]::ToInt32($Choice, 16)
                if ($ChoiceDec -ge 1 -and $ChoiceDec -le $MergedThemes.Count) {
                    $Selected = $MergedThemes[$ChoiceDec - 1]
                    if ($Selected.Source -eq "local") {
                        Apply-LocalTheme -ThemesFolder $ThemesFolder -SelectedFile $Selected.Name
                    } else {
                        $UsingUrl = ($RemoteResult.Success) ? $PrimaryThemesUrl : $FallbackThemesUrl
                        Apply-RemoteTheme -ThemesUrl $UsingUrl -SelectedFile $Selected.Name
                    }
                    break
                }
            }
            Write-Host "Invalid input. Please try again."
            Start-Sleep -Seconds 1
        } while ($true)
    }

    default {
        # Remote execution only
        $RemoteResult = Get-RemoteThemes -ThemesUrl $PrimaryThemesUrl
        if (-not $RemoteResult.Success) {
            $RemoteResult = Get-RemoteThemes -ThemesUrl $FallbackThemesUrl
            if (-not $RemoteResult.Success) {
                Write-Host "Error: Could not retrieve themes list from both primary and fallback URLs."
                exit 1
            }
        }

        $RemoteThemes = $RemoteResult.Files | Sort-Object

        # Calculate layout lengths
        $defaultLine = "[R] Rollback to previous theme"
        $defaultLength = $defaultLine.Length - "[R] ".Length
        $maxNameLengthFromThemes = ($RemoteThemes | ForEach-Object { Format-ThemeName $_ } | Measure-Object -Property Length -Maximum).Maximum
        $maxNameLength = [Math]::Max($defaultLength, $maxNameLengthFromThemes)

        $maxIndexHex = "{0:X}" -f $RemoteThemes.Count
        $optionPrefixLength = ("[${maxIndexHex}] ").Length
        $lineLength = $optionPrefixLength + $maxNameLength + 10
        if ($lineLength -lt 30) { $lineLength = 30 }

        $equalsLine = "=" * $lineLength
        $dashLine = "-" * $lineLength

        # Main Menu
        do {
            Clear-Host
            Write-Host "SAP GUI Theme Changer (Remote Execution)"
            Write-Host $equalsLine
            Write-Host "[0] Exit program"

            if (Test-Path $BackupFile) {
                Write-Host "$defaultLine"
            }

            Write-Host $dashLine
            Write-Host "Available themes:"

            for ($i = 0; $i -lt $RemoteThemes.Count; $i++) {
                $optionHex = "{0:X}" -f ($i + 1)
                $displayName = Format-ThemeName $RemoteThemes[$i]
                $paddedName = $displayName.PadRight($maxNameLength + 2)
                Write-Host ("[{0}] {1}" -f $optionHex, $paddedName)
            }
            Write-Host $equalsLine

            $Choice = Read-Host "Enter your option"

            if ($Choice -eq "0") {
                break
            } elseif ($Choice -match "^[Rr]$" -and (Test-Path $BackupFile)) {
                Copy-Item -Path $BackupFile -Destination $SourceFile -Force
                Write-Host "Rolled back to previous theme successfully."
                Write-Host "Please restart SAP GUI for changes to take effect."
                break
            } elseif ($Choice -match "^[0-9A-Fa-f]+$") {
                $ChoiceDec = [Convert]::ToInt32($Choice, 16)
                if ($ChoiceDec -ge 1 -and $ChoiceDec -le $RemoteThemes.Count) {
                    $SelectedFile = $RemoteThemes[$ChoiceDec - 1]
                    $UsingUrl = ($RemoteResult.Success) ? $PrimaryThemesUrl : $FallbackThemesUrl
                    Apply-RemoteTheme -ThemesUrl $UsingUrl -SelectedFile $SelectedFile
                    break
                }
            }
            Write-Host "Invalid input. Please try again."
            Start-Sleep -Seconds 1
        } while ($true)
    }
}

Write-Host ""
Write-Host "You can close this window now."
