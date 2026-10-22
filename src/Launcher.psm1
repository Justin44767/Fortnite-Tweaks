Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot 'FortniteTweaks.psm1') -Force

$script:SettingLabels = @{
    'sg.AntiAliasingQuality' = 'Kantenglättung'
    'sg.ShadowQuality' = 'Schatten'
    'sg.GlobalIlluminationQuality' = 'Globale Beleuchtung'
    'sg.ReflectionQuality' = 'Reflexionen'
    'sg.PostProcessQuality' = 'Nachbearbeitung'
    'sg.TextureQuality' = 'Texturen'
    'sg.EffectsQuality' = 'Effekte'
    'sg.FoliageQuality' = 'Vegetation'
    'sg.ShadingQuality' = 'Shading'
    'bUseVSync' = 'VSync'
    'bMotionBlur' = 'Bewegungsunschärfe'
}

function Get-LauncherDisplayValue {
    param([string]$Value)
    switch ($Value) {
        '0' { return 'Niedrig (0)' }
        '1' { return 'Mittel (1)' }
        '2' { return 'Hoch (2)' }
        '3' { return 'Episch (3)' }
        'False' { return 'Aus' }
        'True' { return 'Ein' }
        default { return $Value }
    }
}

function Write-LauncherLog {
    param($State, [string]$Message)
    $State.Controls.LogBox.AppendText(('[' + [DateTime]::Now.ToString('HH:mm:ss') + '] ' + $Message + [Environment]::NewLine))
    $State.Controls.LogBox.ScrollToEnd()
}

function Update-LauncherState {
    param($State)
    $controls = $State.Controls
    $controls.ConfigPathText.Text = $State.ConfigPath
    $controls.ConfigPathText.ToolTip = $State.ConfigPath
    $controls.ApplyButton.IsEnabled = $false
    $controls.RestoreButton.IsEnabled = $false
    $controls.OpenBackupsButton.IsEnabled = [IO.Directory]::Exists($State.BackupRoot)
    $State.LastError = $null
    $State.IsReady = $false
    try {
        $preview = @(Get-FortniteProfilePreview -ConfigPath $State.ConfigPath)
        $rows = @($preview | ForEach-Object {
            [pscustomobject]@{
                Label = $script:SettingLabels[$_.Setting]
                CurrentLabel = Get-LauncherDisplayValue $_.CurrentValue
                TargetLabel = Get-LauncherDisplayValue $_.ProfileValue
            }
        })
        $controls.ProfileGrid.ItemsSource = $rows
        $changes = @($preview | Where-Object { $_.NeedsChange }).Count
        $controls.ChangeCountText.Text = "$changes von $($preview.Count) Werten ändern"
        $running = @(Get-Process -ErrorAction Stop | Where-Object {
            $_.ProcessName -like 'FortniteClient*' -or $_.ProcessName -eq 'FortniteLauncher'
        }).Count -gt 0
        $selectedName = $null
        if ($null -ne $controls.BackupPicker.SelectedItem) { $selectedName = $controls.BackupPicker.SelectedItem.Name }
        $backups = @(Get-FortniteBackups -ConfigPath $State.ConfigPath -BackupRoot $State.BackupRoot | ForEach-Object {
            [pscustomobject]@{ Name = $_.Name; Label = $_.LastWriteTime.ToString('dd.MM.yyyy HH:mm:ss.fff'); Path = $_.FullName }
        })
        $controls.BackupPicker.ItemsSource = $backups
        $controls.BackupPicker.IsEnabled = $backups.Count -gt 0
        if ($backups.Count -gt 0) {
            $controls.BackupPicker.SelectedIndex = 0
            for ($index = 0; $index -lt $backups.Count; $index++) {
                if ($backups[$index].Name -eq $selectedName) { $controls.BackupPicker.SelectedIndex = $index; break }
            }
        }
        if ($running) {
            $controls.StatusText.Text = 'Fortnite läuft'
            $controls.StatusText.Foreground = [Windows.Media.Brushes]::Orange
            $controls.HintText.Text = 'Beende Fortnite und klicke auf Aktualisieren, um Einstellungen zu ändern.'
        } else {
            $State.IsReady = $true
            $controls.ApplyButton.IsEnabled = $changes -gt 0
            $controls.RestoreButton.IsEnabled = $backups.Count -gt 0
            $controls.StatusText.Foreground = [Windows.Media.Brushes]::LightGreen
            if ($changes -eq 0) {
                $controls.StatusText.Text = 'Profil eingetragen'
                $controls.HintText.Text = 'Die Datei entspricht dem Profil. Prüfe die Einstellungen nach dem Spielstart.'
            } else {
                $controls.StatusText.Text = 'Bereit'
                $controls.HintText.Text = 'Vergleiche die Werte und wende das Profil mit automatischer Sicherung an.'
            }
        }
    } catch {
        $State.LastError = $_.Exception.Message
        $controls.ProfileGrid.ItemsSource = @()
        $controls.BackupPicker.ItemsSource = @()
        $controls.BackupPicker.IsEnabled = $false
        $controls.ChangeCountText.Text = ''
        $controls.StatusText.Text = 'Einstellungen prüfen'
        $controls.StatusText.Foreground = [Windows.Media.Brushes]::Orange
        if (-not [IO.File]::Exists($State.ConfigPath)) {
            $controls.HintText.Text = 'Starte Fortnite einmal und beende es. Alternativ kannst du die Einstellungsdatei auswählen.'
        } else { $controls.HintText.Text = $State.LastError }
    }
}

function Invoke-LauncherAction {
    param($State, [string]$Action)
    $failure = $null
    try {
        switch ($Action) {
            'Apply' {
                $result = Set-FortniteCompetitiveProfile -ConfigPath $State.ConfigPath -BackupRoot $State.BackupRoot -Confirm:$false
                if ($result.Status -eq 'Applied') {
                    Write-LauncherLog $State 'Profil eingetragen. Starte Fortnite und prüfe die Einstellungen.'
                    Write-LauncherLog $State ("Sicherung: " + $result.Backup)
                } else { Write-LauncherLog $State 'Das Profil ist bereits eingetragen.' }
            }
            'Restore' {
                $selected = $State.Controls.BackupPicker.SelectedItem
                if ($null -eq $selected) { throw 'Wähle zuerst eine Sicherung aus.' }
                if (-not (& $State.ConfirmRestore $State.Window $selected.Label)) { return }
                $result = Restore-FortniteBackup -ConfigPath $State.ConfigPath -BackupRoot $State.BackupRoot -BackupName $selected.Name -Confirm:$false
                if ($result.Status -eq 'Restored') {
                    Write-LauncherLog $State ("Wiederhergestellt: " + $result.Backup)
                    Write-LauncherLog $State ("Vorheriger Zustand gesichert: " + $result.SafetyBackup)
                } else { Write-LauncherLog $State 'Die Datei entspricht bereits der Sicherung.' }
            }
            'Browse' {
                $dialog = New-Object Microsoft.Win32.OpenFileDialog
                $dialog.Title = 'Fortnite-Einstellungsdatei auswählen'
                $dialog.Filter = 'Fortnite-Einstellungen (GameUserSettings.ini)|GameUserSettings.ini'
                $dialog.CheckFileExists = $true
                if ($dialog.ShowDialog($State.Window)) {
                    $State.ConfigPath = $dialog.FileName
                    Write-LauncherLog $State ("Datei ausgewählt: " + $dialog.FileName)
                }
            }
            'OpenBackups' {
                if (-not [IO.Directory]::Exists($State.BackupRoot)) { throw 'Es wurde noch keine Sicherung angelegt.' }
                $start = New-Object Diagnostics.ProcessStartInfo
                $start.FileName = $State.BackupRoot
                $start.UseShellExecute = $true
                [void][Diagnostics.Process]::Start($start)
            }
            'Hardware' {
                $State.HardwareLoaded = $true
                $cpu = @(Get-CimInstance Win32_Processor -OperationTimeoutSec 5 | Select-Object -ExpandProperty Name) -join ' / '
                $gpu = @(Get-CimInstance Win32_VideoController -OperationTimeoutSec 5 | Select-Object -ExpandProperty Name) -join ' / '
                $memory = (Get-CimInstance Win32_ComputerSystem -OperationTimeoutSec 5).TotalPhysicalMemory
                if ([string]::IsNullOrWhiteSpace($cpu)) { $cpu = 'Nicht erkannt' }
                if ([string]::IsNullOrWhiteSpace($gpu)) { $gpu = 'Nicht erkannt' }
                $State.Controls.CpuText.Text = $cpu
                $State.Controls.CpuText.ToolTip = $cpu
                $State.Controls.GpuText.Text = $gpu
                $State.Controls.GpuText.ToolTip = $gpu
                $State.Controls.RamText.Text = "$([Math]::Round($memory / 1GB)) GB"
            }
            'Refresh' { }
        }
    } catch {
        $failure = $_.Exception.Message
        Write-LauncherLog $State ("Fehler: " + $failure)
        if ($Action -eq 'Hardware') {
            foreach ($name in @('CpuText', 'GpuText', 'RamText')) { $State.Controls[$name].Text = 'Nicht erkannt' }
        }
    } finally {
        Update-LauncherState $State
        if ($failure) {
            $State.LastError = $failure
            $State.Controls.StatusText.Text = 'Hinweis'
            $State.Controls.StatusText.Foreground = [Windows.Media.Brushes]::Orange
            $State.Controls.HintText.Text = $failure
        }
    }
}

function New-FortniteLauncher {
    [CmdletBinding()]
    param([string]$ConfigPath, [string]$BackupRoot)
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'Der grafische Launcher benötigt Windows.' }
    if ([Threading.Thread]::CurrentThread.ApartmentState -ne [Threading.ApartmentState]::STA) {
        throw 'Starte den Launcher über Start.cmd oder powershell.exe -NoProfile -STA -File .\Launcher.ps1.'
    }
    if (-not $ConfigPath) { $ConfigPath = Join-Path $env:LOCALAPPDATA 'FortniteGame\Saved\Config\WindowsClient\GameUserSettings.ini' }
    if (-not $BackupRoot) { $BackupRoot = Join-Path $env:LOCALAPPDATA 'Fortnite-Tweaks\Backups' }
    $ConfigPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ConfigPath)
    $BackupRoot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($BackupRoot)
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
    $xml = New-Object Xml.XmlDocument
    $xml.XmlResolver = $null
    $xml.LoadXml([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Launcher.xaml')))
    $reader = New-Object Xml.XmlNodeReader($xml)
    try { $window = [Windows.Markup.XamlReader]::Load($reader) }
    finally { $reader.Close() }
    $window.MaxHeight = [Windows.SystemParameters]::WorkArea.Height
    $window.Height = [Math]::Min($window.Height, $window.MaxHeight)
    $window.MaxWidth = [Windows.SystemParameters]::WorkArea.Width
    $window.Width = [Math]::Min($window.Width, $window.MaxWidth)
    $window.MinHeight = [Math]::Min($window.MinHeight, $window.MaxHeight)
    $window.MinWidth = [Math]::Min($window.MinWidth, $window.MaxWidth)
    $controls = @{}
    foreach ($name in @('RefreshButton', 'BrowseButton', 'OpenBackupsButton', 'ApplyButton', 'RestoreButton', 'BackupPicker', 'StatusText', 'HintText', 'CpuText', 'GpuText', 'RamText', 'ConfigPathText', 'ChangeCountText', 'ProfileGrid', 'LogBox')) {
        $controls[$name] = $window.FindName($name)
        if ($null -eq $controls[$name]) { throw "Launcher-Steuerelement fehlt: $name" }
    }
    $state = [pscustomobject]@{
        Window = $window; Controls = $controls; ConfigPath = $ConfigPath; BackupRoot = $BackupRoot
        LastError = $null; IsReady = $false; HardwareLoaded = $false; Refresh = $null
        ConfirmRestore = {
            param($owner, $label)
            $message = "Die gesamte Einstellungsdatei auf die Sicherung vom $label zurücksetzen? Auch spätere Einstellungen im Spiel werden zurückgesetzt. Der aktuelle Stand wird vorher gesichert."
            return [Windows.MessageBox]::Show($owner, $message, 'Sicherung wiederherstellen', [Windows.MessageBoxButton]::YesNo, [Windows.MessageBoxImage]::Question, [Windows.MessageBoxResult]::No) -eq [Windows.MessageBoxResult]::Yes
        }
    }
    # FunctionInfo retains this module's scope when WPF invokes an event later.
    $dispatch = Get-Command Invoke-LauncherAction
    $state.Refresh = { & $dispatch -State $state -Action 'Refresh' }.GetNewClosure()
    foreach ($pair in @{
        RefreshButton = 'Refresh'; BrowseButton = 'Browse'; OpenBackupsButton = 'OpenBackups'
        ApplyButton = 'Apply'; RestoreButton = 'Restore'
    }.GetEnumerator()) {
        $controls[$pair.Key].Tag = $pair.Value
        $controls[$pair.Key].Add_Click({
            param($sender, $eventArgs)
            & $dispatch -State $state -Action ([string]$sender.Tag)
        }.GetNewClosure())
    }
    $window.Add_ContentRendered({
        if (-not $state.HardwareLoaded) { & $dispatch -State $state -Action 'Hardware' }
    }.GetNewClosure())
    Update-LauncherState $state
    Write-LauncherLog $state 'Launcher gestartet. Es wurden keine Einstellungen verändert.'
    return $state
}

Export-ModuleMember -Function New-FortniteLauncher
