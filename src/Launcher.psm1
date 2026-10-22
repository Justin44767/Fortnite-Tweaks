Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot 'FortniteTweaks.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'WindowsTweaks.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'InputTweaks.psm1') -Force

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
    $controls.ManualApplyButton.IsEnabled = $false
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
        $selectedIds = @($State.ManualRows | Where-Object { $_.Selected } | ForEach-Object { $_.Id })
        $fpsPreview = 144
        $parsedFps = 0
        $fpsValid = [int]::TryParse($controls.FpsLimitBox.Text, [ref]$parsedFps) -and $parsedFps -ge 30 -and $parsedFps -le 1000
        if ($fpsValid) { $fpsPreview = $parsedFps }
        $definitions = @(Get-FortniteOptimizationOptions)
        $manualPreview = @(Get-FortniteProfilePreview -ConfigPath $State.ConfigPath -Options @($definitions | ForEach-Object { $_.Id }) -FrameRateLimit $fpsPreview)
        $State.ManualRows = @($definitions | ForEach-Object {
            $definition = $_
            $changed = @($manualPreview | Where-Object { $definition.Keys -contains $_.Setting -and $_.NeedsChange }).Count
            $status = 'Bereits eingetragen'
            if ($changed -gt 0) { $status = "$changed Wert(e) ändern" }
            if ($definition.Id -eq 'FpsCap') {
                $cap = @($manualPreview | Where-Object { $_.Setting -eq 'FrameRateLimit' })[0]
                $status = 'Aktuell: ' + $cap.CurrentValue + '  |  Ziel: ' + $cap.ProfileValue
                if (-not $fpsValid) { $status = 'FPS-Limit prüfen: ganze Zahl von 30 bis 1000' }
            }
            [pscustomobject]@{ Id = $definition.Id; Label = $definition.Label; Description = $definition.Description; Selected = ($selectedIds -contains $definition.Id); Status = $status }
        })
        $controls.ManualOptionsList.ItemsSource = $State.ManualRows
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
            $controls.ManualApplyButton.IsEnabled = $true
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
        $controls.ManualOptionsList.ItemsSource = @()
        $controls.BackupPicker.ItemsSource = @()
        $controls.BackupPicker.IsEnabled = $false
        $controls.ChangeCountText.Text = ''
        $controls.StatusText.Text = 'Einstellungen prüfen'
        $controls.StatusText.Foreground = [Windows.Media.Brushes]::Orange
        if (-not [IO.File]::Exists($State.ConfigPath)) {
            $controls.HintText.Text = 'Starte Fortnite einmal und beende es. Alternativ kannst du die Einstellungsdatei auswählen.'
        } else { $controls.HintText.Text = $State.LastError }
    }
    $controls.PowerEnableButton.IsEnabled = $false
    $controls.PowerRestoreButton.IsEnabled = $false
    try {
        $power = Get-FortnitePowerPlanState -StatePath $State.PowerStatePath
        $controls.PowerStatusText.Text = 'Aktiv: ' + $power.ActiveLabel
        $controls.PowerStatusText.ToolTip = $power.ActiveSchemeId
        $controls.PowerEnableButton.IsEnabled = ($power.HighPerformanceAvailable -and $power.ActiveSchemeId -ne '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c')
        $controls.PowerRestoreButton.IsEnabled = $power.CanRestore
        if (-not $power.HighPerformanceAvailable) { $controls.PowerStatusText.Text += ' | Hohe Leistung nicht verfügbar' }
    } catch { $controls.PowerStatusText.Text = 'Nicht verfügbar: ' + $_.Exception.Message }
    $controls.KeyboardDisableButton.IsEnabled = $false
    $controls.KeyboardRestoreButton.IsEnabled = $false
    try {
        $keyboard = Get-FortniteKeyboardState -StatePath $State.KeyboardStatePath
        $controls.KeyboardDisableButton.IsEnabled = $keyboard.FilterKeysEnabled
        $controls.KeyboardRestoreButton.IsEnabled = $keyboard.CanRestore
        if ($keyboard.FilterKeysEnabled) {
            $controls.KeyboardStatusText.Text = "Filtertasten aktiv | Annahmeverzögerung: $($keyboard.AcceptanceDelayMs) ms"
        } else { $controls.KeyboardStatusText.Text = 'Filtertasten bereits aus. Hier ist keine weitere Filterverzögerung zu entfernen.' }
    } catch { $controls.KeyboardStatusText.Text = 'Nicht verfügbar: ' + $_.Exception.Message }
}

function Invoke-LauncherAction {
    param($State, [string]$Action)
    $failure = $null
    try {
        switch ($Action) {
            'ShowInput' { $State.Controls.InputSection.BringIntoView() }
            'KeyboardDisable' {
                $result = Disable-FortniteKeyboardFilter -StatePath $State.KeyboardStatePath -Confirm:$false
                if ($result.Status -eq 'Applied') { Write-LauncherLog $State 'Filtertasten deaktiviert. Der vorherige Tastaturzustand wurde gesichert.' }
                else { Write-LauncherLog $State 'Filtertasten waren bereits deaktiviert. Es wurde nichts geändert.' }
            }
            'KeyboardRestore' {
                $result = Restore-FortniteKeyboardFilter -StatePath $State.KeyboardStatePath -Confirm:$false
                if ($result.Status -eq 'Restored') { Write-LauncherLog $State 'Vorheriger Filtertasten-Zustand wiederhergestellt.' }
                else { Write-LauncherLog $State 'Keine Tastatur-Änderung zur Wiederherstellung vorhanden.' }
            }
            'KeyboardSettings' { Start-Process 'ms-settings:easeofaccess-keyboard' -ErrorAction Stop | Out-Null }
            'VictrixSoftware' { Start-Process 'ms-windows-store://search/?query=Victrix%20Control%20Hub' -ErrorAction Stop | Out-Null }
            'ControllerSettings' {
                Start-Process -FilePath (Join-Path $env:SystemRoot 'System32/control.exe') -ArgumentList 'joy.cpl' -ErrorAction Stop | Out-Null
            }
            'ControllerCheck' {
                $controllers = @(Get-FortniteControllerState)
                if ($controllers.Count -eq 0) {
                    $State.Controls.ControllerStatusText.Text = 'Kein XInput-Controller erkannt. PlayStation- und andere DirectInput-Geräte können trotzdem in Windows und Fortnite funktionieren.'
                } else {
                    $lines = @($controllers | ForEach-Object {
                        'Controller {0}: Stick links {1:N2} %, rechts {2:N2} % | LT {3:N0} %, RT {4:N0} %' -f $_.Slot, $_.LeftStickPercent, $_.RightStickPercent, $_.LeftTriggerPercent, $_.RightTriggerPercent
                    })
                    $State.Controls.ControllerStatusText.Text = ([DateTime]::Now.ToString('HH:mm:ss') + ' | Momentaufnahme' + [Environment]::NewLine + ($lines -join [Environment]::NewLine))
                }
                Write-LauncherLog $State 'Controller-Momentaufnahme gelesen. Keine Geräte- oder Spieleinstellungen geändert.'
            }
            'ApplyManual' {
                $selectedIds = @($State.ManualRows | Where-Object { $_.Selected } | ForEach-Object { $_.Id })
                if ($selectedIds.Count -eq 0) { throw 'Wähle mindestens eine Optimierung aus.' }
                $fps = 144
                if ($selectedIds -contains 'FpsCap') {
                    if (-not [int]::TryParse($State.Controls.FpsLimitBox.Text, [ref]$fps) -or $fps -lt 30 -or $fps -gt 1000) {
                        throw 'Das FPS-Limit muss eine ganze Zahl von 30 bis 1000 sein.'
                    }
                }
                $result = Set-FortniteCompetitiveProfile -ConfigPath $State.ConfigPath -BackupRoot $State.BackupRoot -Options $selectedIds -FrameRateLimit $fps -Confirm:$false
                if ($result.Status -eq 'Applied') {
                    $State.Controls.BackupPicker.SelectedItem = $null
                    Write-LauncherLog $State ('Auswahl angewendet: ' + ($selectedIds -join ', '))
                    Write-LauncherLog $State ('Sicherung: ' + $result.Backup)
                } else { Write-LauncherLog $State 'Die ausgewählten Werte sind bereits eingetragen.' }
            }
            'PowerEnable' {
                [void](Enable-FortniteHighPerformance -StatePath $State.PowerStatePath -Confirm:$false)
                Write-LauncherLog $State 'Energieplan Hohe Leistung aktiv. Vergleiche FPS und Frametimes im Spiel.'
            }
            'PowerRestore' {
                $result = Restore-FortnitePowerPlan -StatePath $State.PowerStatePath -Confirm:$false
                if ($result.Status -eq 'Restored') { Write-LauncherLog $State 'Vorheriger Energieplan wiederhergestellt.' }
                else { Write-LauncherLog $State 'Keine gespeicherte Energieplan-Aenderung vorhanden.' }
            }
            'GameMode' {
                Start-Process 'ms-settings:gaming-gamemode' -ErrorAction Stop | Out-Null
                Write-LauncherLog $State 'Windows-Spielmodus geöffnet. Du änderst den Schalter dort selbst.'
            }
            'Captures' {
                Start-Process 'ms-settings:gaming-gamedvr' -ErrorAction Stop | Out-Null
                Write-LauncherLog $State 'Windows-Spielaufnahmen geöffnet. Deaktiviere dort bei Bedarf die Hintergrundaufnahme.'
            }
            'Apply' {
                $result = Set-FortniteCompetitiveProfile -ConfigPath $State.ConfigPath -BackupRoot $State.BackupRoot -Confirm:$false
                if ($result.Status -eq 'Applied') {
                    $State.Controls.BackupPicker.SelectedItem = $null
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
    param([string]$ConfigPath, [string]$BackupRoot, [string]$PowerStatePath, [string]$KeyboardStatePath)
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'Der grafische Launcher benötigt Windows.' }
    if ([Threading.Thread]::CurrentThread.ApartmentState -ne [Threading.ApartmentState]::STA) {
        throw 'Starte den Launcher über Start.cmd oder powershell.exe -NoProfile -STA -File .\Launcher.ps1.'
    }
    if (-not $ConfigPath) { $ConfigPath = Join-Path $env:LOCALAPPDATA 'FortniteGame\Saved\Config\WindowsClient\GameUserSettings.ini' }
    if (-not $BackupRoot) { $BackupRoot = Join-Path $env:LOCALAPPDATA 'Fortnite-Tweaks\Backups' }
    if (-not $PowerStatePath) { $PowerStatePath = Join-Path $env:LOCALAPPDATA 'Fortnite-Tweaks\State\power-plan.json' }
    if (-not $KeyboardStatePath) { $KeyboardStatePath = Join-Path $env:LOCALAPPDATA 'Fortnite-Tweaks\State\keyboard.json' }
    $ConfigPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ConfigPath)
    $BackupRoot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($BackupRoot)
    $PowerStatePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($PowerStatePath)
    $KeyboardStatePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($KeyboardStatePath)
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
    foreach ($name in @('RefreshButton', 'BrowseButton', 'OpenBackupsButton', 'ApplyButton', 'RestoreButton', 'BackupPicker', 'StatusText', 'HintText', 'CpuText', 'GpuText', 'RamText', 'ConfigPathText', 'ChangeCountText', 'ProfileGrid', 'LogBox', 'ManualOptionsList', 'FpsLimitBox', 'ManualApplyButton', 'PowerEnableButton', 'PowerRestoreButton', 'PowerStatusText', 'GameModeButton', 'CapturesButton', 'InputSection', 'InputButton', 'KeyboardStatusText', 'KeyboardDisableButton', 'KeyboardRestoreButton', 'KeyboardSettingsButton', 'ControllerStatusText', 'ControllerCheckButton', 'ControllerSettingsButton', 'VictrixSoftwareButton')) {
        $controls[$name] = $window.FindName($name)
        if ($null -eq $controls[$name]) { throw "Launcher-Steuerelement fehlt: $name" }
    }
    $state = [pscustomobject]@{
        Window = $window; Controls = $controls; ConfigPath = $ConfigPath; BackupRoot = $BackupRoot
        LastError = $null; IsReady = $false; HardwareLoaded = $false; Refresh = $null
        ManualRows = @(); PowerStatePath = $PowerStatePath
        KeyboardStatePath = $KeyboardStatePath
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
        ManualApplyButton = 'ApplyManual'; PowerEnableButton = 'PowerEnable'; PowerRestoreButton = 'PowerRestore'
        GameModeButton = 'GameMode'; CapturesButton = 'Captures'
        InputButton = 'ShowInput'; KeyboardDisableButton = 'KeyboardDisable'; KeyboardRestoreButton = 'KeyboardRestore'
        KeyboardSettingsButton = 'KeyboardSettings'; ControllerCheckButton = 'ControllerCheck'; ControllerSettingsButton = 'ControllerSettings'
        VictrixSoftwareButton = 'VictrixSoftware'
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
    $controls.FpsLimitBox.Add_LostFocus({ & $dispatch -State $state -Action 'Refresh' }.GetNewClosure())
    Update-LauncherState $state
    Write-LauncherLog $state 'Launcher gestartet. Es wurden keine Einstellungen verändert.'
    return $state
}

Export-ModuleMember -Function New-FortniteLauncher
