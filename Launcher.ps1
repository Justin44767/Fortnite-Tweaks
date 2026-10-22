#Requires -Version 5.1
[CmdletBinding()]
param([string]$ConfigPath, [string]$BackupRoot, [string]$KeyboardStatePath)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'src/Launcher.psm1') -Force
$launcher = New-FortniteLauncher -ConfigPath $ConfigPath -BackupRoot $BackupRoot -KeyboardStatePath $KeyboardStatePath
try { [void]$launcher.Window.ShowDialog() }
finally { $launcher.Window.Close() }
