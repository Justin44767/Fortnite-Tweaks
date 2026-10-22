#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'These tests require Windows and STA; run Run-Tests.ps1 for the portable suite.'
}
Import-Module (Join-Path $PSScriptRoot '../src/Launcher.psm1') -Force
$testDirectory = Join-Path ([IO.Path]::GetTempPath()) ('fortnite-launcher-tests-' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($testDirectory)
$config = Join-Path $testDirectory 'GameUserSettings.ini'
$backupRoot = Join-Path $testDirectory 'backups'
$powerStatePath = Join-Path $testDirectory 'power-plan.json'
$originalText = "[ScalabilityGroups]`r`nsg.ShadowQuality=3`r`n[/Script/FortniteGame.FortGameUserSettings]`r`nbUseVSync=True`r`nResolutionSizeX=1920`r`n"
$original = [Text.Encoding]::UTF8.GetBytes($originalText)
[IO.File]::WriteAllBytes($config, $original)
$launcher = $null
$missing = $null

function Assert-Launcher {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Get-ConfigBase64 { return [Convert]::ToBase64String([IO.File]::ReadAllBytes($config)) }

function Click-LauncherButton {
    param($Button)
    $clickEvent = New-Object Windows.RoutedEventArgs([Windows.Controls.Button]::ClickEvent)
    $Button.RaiseEvent($clickEvent)
}

try {
    $launcher = New-FortniteLauncher -ConfigPath $config -BackupRoot $backupRoot -PowerStatePath $powerStatePath
    Assert-Launcher $launcher.IsReady 'Launcher did not recognize valid settings.'
    Assert-Launcher ($launcher.Controls.ProfileGrid.Items.Count -eq 11) 'Profile grid was not populated.'
    Assert-Launcher $launcher.Controls.ApplyButton.IsEnabled 'Apply should be enabled.'
    Assert-Launcher (-not $launcher.Controls.RestoreButton.IsEnabled) 'Restore should be disabled without backups.'
    Assert-Launcher (-not (Test-Path -LiteralPath $backupRoot)) 'Opening the launcher wrote backups.'
    Assert-Launcher ($launcher.ManualRows.Count -eq 6 -and @($launcher.ManualRows | Where-Object { $_.Selected }).Count -eq 0) 'Manual options should start unselected.'
    Assert-Launcher (-not [IO.File]::Exists($powerStatePath)) 'Opening the launcher wrote power state.'
    Assert-Launcher ((Get-ConfigBase64) -ceq [Convert]::ToBase64String($original)) 'Opening the launcher changed settings.'

    # Show without a modal loop so layout and ContentRendered can be exercised unattended.
    $launcher.Window.Show()
    $launcher.Window.UpdateLayout()
    $launcher.Window.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::ApplicationIdle)
    Assert-Launcher $launcher.HardwareLoaded 'Hardware callback did not execute.'
    Write-Host 'PASS Launcher loads XAML, hardware callback, and a read-only preview.'

    Click-LauncherButton $launcher.Controls.ManualApplyButton
    Assert-Launcher ($launcher.LastError -match 'mindestens') 'Empty selection was not rejected.'
    Assert-Launcher ((Get-ConfigBase64) -ceq [Convert]::ToBase64String($original)) 'Empty selection changed settings.'
    @($launcher.ManualRows | Where-Object { $_.Id -eq 'VSyncOff' })[0].Selected = $true
    Click-LauncherButton $launcher.Controls.ManualApplyButton
    Assert-Launcher ($null -eq $launcher.LastError) "Manual apply failed: $($launcher.LastError)"
    Assert-Launcher ([IO.File]::ReadAllText($config) -ceq $originalText.Replace('bUseVSync=True', 'bUseVSync=False')) 'Manual option changed unselected values.'
    $launcher.ConfirmRestore = { param($owner, $label) return $true }
    Click-LauncherButton $launcher.Controls.RestoreButton
    Assert-Launcher ((Get-ConfigBase64) -ceq [Convert]::ToBase64String($original)) 'Manual option was not restorable.'
    Write-Host 'PASS Manual apply changes only selected values and remains restorable.'

    foreach ($row in $launcher.ManualRows) { $row.Selected = ($row.Id -eq 'FpsCap') }
    $launcher.Controls.FpsLimitBox.Text = '237'
    Click-LauncherButton $launcher.Controls.ManualApplyButton
    $capped = [IO.File]::ReadAllText($config)
    Assert-Launcher ($null -eq $launcher.LastError -and $capped.Contains('FrameRateLimit=237.000000') -and $capped.Contains('sg.ShadowQuality=3') -and $capped.Contains('bUseVSync=True')) 'Manual FPS selection did not stay isolated.'
    Assert-Launcher (@($launcher.ManualRows | Where-Object { $_.Id -eq 'FpsCap' })[0].Status.Contains('237.000000')) 'Current FPS cap was not shown.'
    Click-LauncherButton $launcher.Controls.RestoreButton
    $launcher.Controls.FpsLimitBox.Text = 'not-a-number'
    Click-LauncherButton $launcher.Controls.ManualApplyButton
    Assert-Launcher ($launcher.LastError -match '30 bis 1000') 'Invalid FPS input was not rejected.'
    Assert-Launcher ((Get-ConfigBase64) -ceq [Convert]::ToBase64String($original)) 'Invalid FPS input changed settings.'
    foreach ($row in $launcher.ManualRows) { $row.Selected = $false }
    $launcher.Controls.FpsLimitBox.Text = '144'
    Write-Host 'PASS Manual FPS cap and invalid input use the actual launcher controls.'

    $backupsBeforeProfile = $launcher.Controls.BackupPicker.Items.Count
    Click-LauncherButton $launcher.Controls.ApplyButton
    Assert-Launcher ($null -eq $launcher.LastError) "Apply failed: $($launcher.LastError)"
    Assert-Launcher ((Get-ConfigBase64) -cne [Convert]::ToBase64String($original)) 'Apply button did not change settings.'
    Assert-Launcher (-not $launcher.Controls.ApplyButton.IsEnabled) 'Apply stayed enabled for an applied profile.'
    Assert-Launcher ($launcher.Controls.BackupPicker.Items.Count -eq ($backupsBeforeProfile + 1)) 'Created backup did not appear in picker.'
    Assert-Launcher $launcher.Controls.RestoreButton.IsEnabled 'Restore did not become available.'
    Write-Host 'PASS Apply button creates backup, applies profile, and refreshes controls.'

    $applied = Get-ConfigBase64
    $launcher.ConfirmRestore = { param($owner, $label) return $false }
    Click-LauncherButton $launcher.Controls.RestoreButton
    Assert-Launcher ((Get-ConfigBase64) -ceq $applied) 'Cancelling restore changed settings.'
    Write-Host 'PASS Cancelling restore preserves current settings.'

    $launcher.ConfirmRestore = { param($owner, $label) return $true }
    Click-LauncherButton $launcher.Controls.RestoreButton
    Assert-Launcher ($null -eq $launcher.LastError) "Restore failed: $($launcher.LastError)"
    Assert-Launcher ((Get-ConfigBase64) -ceq [Convert]::ToBase64String($original)) 'Restore button did not restore original bytes.'
    Assert-Launcher $launcher.Controls.ApplyButton.IsEnabled 'Apply did not become available after restore.'
    Write-Host 'PASS Restore button uses the selected backup and restores original bytes.'

    Click-LauncherButton $launcher.Controls.ApplyButton
    $selectedBackup = $launcher.Controls.BackupPicker.SelectedItem.Path
    [IO.File]::AppendAllText($selectedBackup, "`r`n; corrupted backup")
    $beforeFailedRestore = Get-ConfigBase64
    Click-LauncherButton $launcher.Controls.RestoreButton
    Assert-Launcher ($launcher.LastError -match 'SHA256') 'Corrupted backup did not produce an inline error.'
    Assert-Launcher ((Get-ConfigBase64) -ceq $beforeFailedRestore) 'Failed restore changed settings.'
    Write-Host 'PASS Restore error appears in the launcher without changing current settings.'

    $missing = New-FortniteLauncher -ConfigPath (Join-Path $testDirectory 'missing.ini') -BackupRoot $backupRoot -PowerStatePath $powerStatePath
    Assert-Launcher (-not $missing.IsReady) 'Missing settings reported as ready.'
    Assert-Launcher (-not $missing.Controls.ApplyButton.IsEnabled -and -not $missing.Controls.RestoreButton.IsEnabled) 'Actions enabled for missing settings.'
    Assert-Launcher (-not $missing.Controls.ManualApplyButton.IsEnabled) 'Manual apply enabled for missing settings.'
    Assert-Launcher ($missing.Controls.HintText.Text -match 'Starte Fortnite') 'Missing settings guidance was not shown.'
    Write-Host 'PASS Missing settings display guidance and disable changes.'
} finally {
    if ($null -ne $missing) { $missing.Window.Close() }
    if ($null -ne $launcher) { $launcher.Window.Close() }
    Remove-Item -LiteralPath $testDirectory -Recurse -Force
}
