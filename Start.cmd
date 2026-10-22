@echo off
setlocal
title Fortnite Tweaks Launcher
if not exist "%~dp0Launcher.ps1" (
    echo Launcher.ps1 fehlt. Bitte den vollstaendigen Projektordner entpacken.
    pause
    exit /b 1
)
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -STA -ExecutionPolicy RemoteSigned -File "%~dp0Launcher.ps1"
set "fortnite_launcher_exit=%errorlevel%"
if not "%fortnite_launcher_exit%"=="0" (
    echo.
    echo Der Launcher konnte nicht gestartet werden. Details stehen oben.
    echo Hinweise zu blockierten Downloads findest du in README.md.
    pause
)
exit /b %fortnite_launcher_exit%
