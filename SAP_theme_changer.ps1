# Define paths
$SOURCE_DIR = "$env:APPDATA\SAP\SAP GUI\ABAP Editor\abap_spec.xml"
$THEMES_DIR = "./themes"
$FILES_POSTFIX = "theme.xml"

# Get theme files
$FILES = Get-ChildItem -Path $THEMES_DIR -Filter "*$FILES_POSTFIX"
$FILES_LENGTH = $FILES.Count
$FILES_OFFSET = 3

# Function to format theme name
function Format-Name {
    param ($filePath)
    return ([System.IO.Path]::GetFileNameWithoutExtension($filePath) -replace "_", " ")
}

# Function to format file name
function Format-File {
    param ($filePath)
    $newFileName = ($filePath.Name -replace " ", "_")
    if ($filePath.Name -ne $newFileName) {
        Rename-Item -Path $filePath.FullName -NewName $newFileName
    }
}

# Function to format files
function Format-Files {
    Get-ChildItem -Path $THEMES_DIR | ForEach-Object { Format-File $_ }
}

# Function to change theme
function Change-Theme {
    param ($selectedFile)
    try {
        Copy-Item -Path $selectedFile -Destination $SOURCE_DIR -Force
        Write-Host "Change theme to $(Format-Name $selectedFile) successfully!"
        Write-Host "Please restart SAP GUI for change to take effect."
    } catch {
        Write-Host "Error: Change theme failed!"
    }
}

# Function to save theme
function Save-Theme {
    $themeName = Read-Host "Name your theme to save. Leave blank for 'previous_theme.xml'"
    if ([string]::IsNullOrWhiteSpace($themeName)) {
        $themeName = "previous"
    }
    $themeName = "$themeName`_$FILES_POSTFIX"
    try {
        Copy-Item -Path $SOURCE_DIR -Destination "$THEMES_DIR\$themeName" -Force
        Write-Host "Save theme '$themeName' successfully!"
    } catch {
        Write-Host "Error: Save theme failed!"
    }
}

# Format files
Format-Files

# Check if there are theme files
if ($FILES_LENGTH -eq 0) {
    Write-Host "No theme XML file found."
    exit 1
}

# Input validation loop
while ($true) {
    Write-Host "======================="
    Write-Host "[0] Exit program"
    Write-Host "[1] Save current theme"
    Write-Host "[2] Format theme names"
    Write-Host "-----------------------"
    Write-Host "Available themes:"

    for ($i = 0; $i -lt $FILES_LENGTH; $i++) {
        Write-Host "[$($i + $FILES_OFFSET)] $(Format-Name $FILES[$i]) theme"
    }
    Write-Host "======================="

    $choice = Read-Host "Enter your option"

    if ($choice -match "^[0-9]+$" -and
        $choice -ge 0 -and
        $choice -le ($FILES_LENGTH + $FILES_OFFSET)) {
        break
    } else {
        Clear-Host
        Write-Host "Not a valid input. Please try again."
    }
}

switch ($choice) {
    0 { exit 1 }
    1 {
        Save-Theme
        Format-Files
    }
    2 {
        Format-Files
        Write-Host "Format theme names successfully!"
    }
    default {
        $selectedFile = $FILES[$choice - $FILES_OFFSET]
        Change-Theme $selectedFile
    }
}

# Wait for user to exit
Read-Host "Press any key to exit"