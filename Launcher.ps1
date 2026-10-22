#Requires -Version 5.1
[CmdletBinding()]
param([string]$ConfigPath, [string]$BackupRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'src/Launcher.psm1') -Force
$launcher = New-FortniteLauncher -ConfigPath $ConfigPath -BackupRoot $BackupRoot
try { [void]$launcher.Window.ShowDialog() }
finally { $launcher.Window.Close() }
