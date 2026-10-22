#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('Menu', 'Status', 'System', 'Apply', 'Restore', 'Backups')]
    [string]$Action = 'Menu',
    [string]$ConfigPath,
    [string]$BackupRoot,
    [string]$BackupName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'Dieses Tool ist fuer Windows. Die Dateiverarbeitung kann unter Linux mit tests/Run-Tests.ps1 geprueft werden.'
}
if (-not $ConfigPath) {
    $ConfigPath = Join-Path $env:LOCALAPPDATA 'FortniteGame\Saved\Config\WindowsClient\GameUserSettings.ini'
}
if (-not $BackupRoot) { $BackupRoot = Join-Path $env:LOCALAPPDATA 'Fortnite-Tweaks\Backups' }
Import-Module (Join-Path $PSScriptRoot 'src\FortniteTweaks.psm1') -Force
$operationOptions = @{ WhatIf = [bool]$WhatIfPreference }
if ($PSBoundParameters.ContainsKey('Confirm')) { $operationOptions.Confirm = $PSBoundParameters['Confirm'] }

function Invoke-TweakAction {
    param([string]$SelectedAction)
    switch ($SelectedAction) {
        'Status' {
            Write-Host 'Fortnite-Tweaks | Profil: Competitive'
            Write-Host "Einstellungen: $ConfigPath"
            Write-Host "Datei vorhanden: $(Test-Path -LiteralPath $ConfigPath -PathType Leaf)"
            Write-Host "Sicherungen: $BackupRoot"
            Get-FortniteProfile | Format-Table -AutoSize
        }
        'System' {
            $os = Get-CimInstance Win32_OperatingSystem
            Write-Host "Windows: $($os.Caption) (Build $($os.BuildNumber))"
            Write-Host "RAM: $([Math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)) GB"
            Get-CimInstance Win32_Processor | Select-Object @{Name = 'CPU'; Expression = { $_.Name }} | Format-Table -AutoSize
            Get-CimInstance Win32_VideoController | Select-Object @{Name = 'GPU'; Expression = { $_.Name }}, DriverVersion | Format-Table -AutoSize
        }
        'Backups' {
            $backups = @(Get-FortniteBackups -ConfigPath $ConfigPath -BackupRoot $BackupRoot)
            if ($backups.Count -eq 0) { Write-Host 'Noch keine Sicherung vorhanden.' }
            else { $backups | Select-Object Name, LastWriteTimeUtc | Format-Table -AutoSize }
        }
        'Apply' {
            $result = Set-FortniteCompetitiveProfile -ConfigPath $ConfigPath -BackupRoot $BackupRoot @operationOptions
            if ($null -ne $result) {
                if ($result.Status -eq 'Unchanged') { Write-Host 'Das Profil ist bereits eingetragen.' }
                else {
                    Write-Host 'Grafikprofil eingetragen. Pruefe die Einstellungen nach dem naechsten Spielstart.'
                    Write-Host "Sicherung: $($result.Backup)"
                }
            }
        }
        'Restore' {
            $parameters = @{ ConfigPath = $ConfigPath; BackupRoot = $BackupRoot }
            if ($BackupName) { $parameters.BackupName = $BackupName }
            $result = Restore-FortniteBackup @parameters @operationOptions
            if ($null -ne $result) {
                if ($result.Status -eq 'Unchanged') { Write-Host 'Die Datei entspricht bereits der Sicherung.' }
                else {
                    Write-Host "Wiederhergestellt: $($result.Backup)"
                    Write-Host "Zustand vor Wiederherstellung gesichert: $($result.SafetyBackup)"
                }
            }
        }
    }
}

if ($Action -ne 'Menu') { Invoke-TweakAction $Action; return }

do {
    Write-Host ''
    Write-Host 'Fortnite-Tweaks'
    Write-Host '1  Profil und Dateipfad anzeigen'
    Write-Host '2  Grafikprofil anwenden (Fortnite vorher beenden)'
    Write-Host '3  Letzte Sicherung wiederherstellen'
    Write-Host '4  Sicherungen auflisten'
    Write-Host '5  Hardware und Windows anzeigen'
    Write-Host '0  Beenden'
    $choice = Read-Host 'Auswahl'
    try {
        switch ($choice) {
            '1' { Invoke-TweakAction 'Status' }
            '2' { Invoke-TweakAction 'Apply' }
            '3' { Invoke-TweakAction 'Restore' }
            '4' { Invoke-TweakAction 'Backups' }
            '5' { Invoke-TweakAction 'System' }
            '0' { }
            default { Write-Host 'Bitte 0 bis 5 eingeben.' }
        }
    } catch { Write-Host $_.Exception.Message -ForegroundColor Red }
} while ($choice -ne '0')
