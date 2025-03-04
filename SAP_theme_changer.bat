@echo off
setlocal enabledelayedexpansion

:: Define paths
set "SOURCE_DIR=%APPDATA%\SAP\SAP GUI\ABAP Editor\abap_spec.xml"
set "THEMES_DIR=themes"
set "FILES_POSTFIX=theme.xml"

:: Ensure themes directory exists
if not exist "%THEMES_DIR%" (
    echo No theme directory found.
    exit /b 1
)

:: Format file names
for /r "%THEMES_DIR%" %%F in (* ) do (
    set "OLD_NAME=%%~nxF"
    set "NEW_NAME=!OLD_NAME: =_!"
    if not "!OLD_NAME!"=="!NEW_NAME!" ren "%%F" "!NEW_NAME!"
)

:: Get files count
set /a FILES_LENGTH=0
for /f %%F in ('dir /b "%THEMES_DIR%\*%FILES_POSTFIX%" 2^>nul') do (
    set /a FILES_LENGTH+=1
)
if %FILES_LENGTH%==0 (
    echo No theme XML file found.
    exit /b 1
)

:MENU
cls

echo =======================
echo [0] Exit program
echo [1] Save current theme
echo [2] Format theme names
echo -----------------------
echo Available themes:
set /a INDEX=3
for /f "delims=" %%F in ('dir /b "%THEMES_DIR%\*%FILES_POSTFIX%"') do (
    echo [!INDEX!] %%~nF theme
    set "THEME[!INDEX!]=%%F"
    set /a INDEX+=1
)
echo ========================

set /p CHOICE=Enter your option:
if "%CHOICE%"=="0" exit /b
if "%CHOICE%"=="1" goto SAVE_THEME
if "%CHOICE%"=="2" goto FORMAT_NAMES
if not defined THEME[%CHOICE%] (
    echo Invalid input. Try again.
    pause
    goto MENU
)

goto CHANGE_THEME

:SAVE_THEME
echo Enter theme name to save (leave blank for "previous_theme.xml"):
set /p THEME_NAME=
if "%THEME_NAME%"=="" set "THEME_NAME=previous"
set "THEME_NAME=%THEME_NAME%_%FILES_POSTFIX%"
copy "%SOURCE_DIR%" "%THEMES_DIR%\%THEME_NAME%" >nul 2>&1
if errorlevel 1 (
    echo Error: Save theme failed!
) else (
    echo Save theme "%THEME_NAME%" successfully!
)
pause
goto MENU

:FORMAT_NAMES
for /r "%THEMES_DIR%" %%F in (* ) do (
    set "OLD_NAME=%%~nxF"
    set "NEW_NAME=!OLD_NAME: =_!"
    if not "!OLD_NAME!"=="!NEW_NAME!" ren "%%F" "!NEW_NAME!"
)
echo Format theme names successfully!
pause
goto MENU

:CHANGE_THEME
set "SELECTED_FILE=%THEMES_DIR%\!THEME[%CHOICE%]!"
copy "%SELECTED_FILE%" "%SOURCE_DIR%" /y >nul 2>&1
if errorlevel 1 (
    echo Error: Change theme failed!
) else (
    echo Change theme to "!THEME[%CHOICE%]!" successfully!
    echo Please restart SAP GUI for the change to take effect.
)
pause
goto MENU
