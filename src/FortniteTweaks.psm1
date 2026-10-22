Set-StrictMode -Version Latest

$script:Profile = [ordered]@{
    'ScalabilityGroups' = [ordered]@{
        'sg.AntiAliasingQuality' = '0'
        'sg.ShadowQuality' = '0'
        'sg.GlobalIlluminationQuality' = '0'
        'sg.ReflectionQuality' = '0'
        'sg.PostProcessQuality' = '0'
        'sg.TextureQuality' = '1'
        'sg.EffectsQuality' = '0'
        'sg.FoliageQuality' = '0'
        'sg.ShadingQuality' = '0'
    }
    '/Script/FortniteGame.FortGameUserSettings' = [ordered]@{
        'bUseVSync' = 'False'
        'bMotionBlur' = 'False'
    }
}

$script:Options = @(
    @{ Id = 'Shadows'; Label = 'Schatten und Beleuchtung'; Description = 'Schatten, globale Beleuchtung und Reflexionen auf niedrig.'; Keys = @('sg.ShadowQuality', 'sg.GlobalIlluminationQuality', 'sg.ReflectionQuality') },
    @{ Id = 'Effects'; Label = 'Effekte reduzieren'; Description = 'Effekte, Nachbearbeitung, Vegetation und Shading auf niedrig.'; Keys = @('sg.EffectsQuality', 'sg.PostProcessQuality', 'sg.FoliageQuality', 'sg.ShadingQuality') },
    @{ Id = 'Textures'; Label = 'Texturen und Kantenglättung'; Description = 'Texturen auf mittel, Kantenglättung auf niedrig.'; Keys = @('sg.TextureQuality', 'sg.AntiAliasingQuality') },
    @{ Id = 'VSyncOff'; Label = 'VSync deaktivieren'; Description = 'Kann die Eingabeverzögerung senken; Bildrisse sind möglich.'; Keys = @('bUseVSync') },
    @{ Id = 'MotionBlurOff'; Label = 'Bewegungsunschärfe deaktivieren'; Description = 'Klarere Darstellung bei Bewegung; kein garantierter FPS-Gewinn.'; Keys = @('bMotionBlur') },
    @{ Id = 'FpsCap'; Label = 'Eigenes FPS-Limit'; Description = 'Frei wählbar: 30 bis 1000 FPS. Ein passendes Limit kann Frametimes stabilisieren.'; Keys = @('FrameRateLimit') }
)

function Get-FortniteOptimizationOptions {
    foreach ($option in $script:Options) {
        [pscustomobject]@{ Id = $option.Id; Label = $option.Label; Description = $option.Description; Keys = [string[]]$option.Keys }
    }
}

function Get-SelectedSettingsPatch {
    param([string[]]$Options, [int]$FrameRateLimit)
    if ($Options.Count -eq 0) { throw 'Wähle mindestens eine Optimierung aus.' }
    $patch = [ordered]@{}
    foreach ($id in $Options) {
        $definitions = @($script:Options | Where-Object { $_.Id -eq $id })
        if ($definitions.Count -ne 1) { throw "Unbekannte Optimierung: $id" }
        if ($id -eq 'FpsCap') {
            if ($FrameRateLimit -lt 30 -or $FrameRateLimit -gt 1000) { throw 'Das FPS-Limit muss eine ganze Zahl von 30 bis 1000 sein.' }
            $section = '/Script/FortniteGame.FortGameUserSettings'
            if (-not $patch.Contains($section)) { $patch[$section] = [ordered]@{} }
            $patch[$section]['FrameRateLimit'] = $FrameRateLimit.ToString('0.000000', [Globalization.CultureInfo]::InvariantCulture)
            continue
        }
        foreach ($key in $definitions[0].Keys) {
            foreach ($section in $script:Profile.Keys) {
                if ($script:Profile[$section].Contains($key)) {
                    if (-not $patch.Contains($section)) { $patch[$section] = [ordered]@{} }
                    $patch[$section][$key] = $script:Profile[$section][$key]
                }
            }
        }
    }
    return $patch
}

function Get-BytesHash {
    param([byte[]]$Bytes)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($sha.ComputeHash($Bytes)).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
}

function Read-SettingsFile {
    param([string]$ConfigPath)
    $item = Get-Item -LiteralPath $ConfigPath -ErrorAction Stop
    if ($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw 'Die Einstellungsdatei muss eine normale Datei sein.'
    }
    $bytes = [IO.File]::ReadAllBytes($item.FullName)
    $offset = 0
    $encoding = New-Object Text.UTF8Encoding($false, $true)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) {
        $offset = 3
    } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 255 -and $bytes[1] -eq 254) {
        $encoding = New-Object Text.UnicodeEncoding($false, $false, $true)
        $offset = 2
    } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 254 -and $bytes[1] -eq 255) {
        $encoding = New-Object Text.UnicodeEncoding($true, $false, $true)
        $offset = 2
    }
    try { $text = $encoding.GetString($bytes, $offset, $bytes.Length - $offset) }
    catch { throw 'Nicht unterstuetzte Zeichenkodierung. Erwartet wird UTF-8 oder UTF-16.' }
    if ($text -notmatch '(?im)^[ \t]*\[/Script/FortniteGame\.FortGameUserSettings\][ \t]*(?:[;#][^\r\n]*)?\r?$') {
        throw 'Keine Fortnite-GameUserSettings erkannt. Starte Fortnite einmal und beende es wieder.'
    }
    $preamble = New-Object byte[] $offset
    if ($offset -gt 0) { [Array]::Copy($bytes, $preamble, $offset) }
    return [pscustomobject]@{
        Path = $item.FullName; Bytes = $bytes; Text = $text
        Encoding = $encoding; Preamble = $preamble
    }
}

function ConvertTo-CompetitiveSettings {
    param([string]$Text, [Collections.IDictionary]$Profile = $script:Profile)
    $newline = "`r`n"
    $lineMatch = [regex]::Match($Text, '\r\n|\n')
    if ($lineMatch.Success) { $newline = $lineMatch.Value }
    foreach ($section in $Profile.Keys) {
        $pattern = '(?im)^[ \t]*\[' + [regex]::Escape($section) + '\][ \t]*(?:[;#][^\r\n]*)?(?:\r\n|\n|$)'
        $headers = [regex]::Matches($Text, $pattern)
        if ($headers.Count -gt 1) { throw "Abschnitt [$section] ist mehrfach vorhanden. Es wurde nichts geaendert." }
        if ($headers.Count -eq 0) {
            if ($Text.Length -gt 0 -and $Text -notmatch '\n$') { $Text += $newline }
            $Text += "[$section]$newline"
            $headers = [regex]::Matches($Text, $pattern)
        }
        $start = $headers[0].Index + $headers[0].Length
        if ($start -eq $Text.Length -and $Text -notmatch '\n$') {
            $Text += $newline
            $start = $Text.Length
        }
        $remaining = $Text.Substring($start)
        $next = [regex]::Match($remaining, '(?m)^[ \t]*\[[^\r\n\]]+\]')
        $length = $remaining.Length
        if ($next.Success) { $length = $next.Index }
        $body = $remaining.Substring(0, $length)
        foreach ($key in $Profile[$section].Keys) {
            $value = $Profile[$section][$key]
            $keyPattern = '(?im)^([ \t]*' + [regex]::Escape($key) + '[ \t]*=[ \t]*)([^;#\r\n]*?)([ \t]*(?:[;#][^\r\n]*)?)(?=\r\n|\n|$)'
            if ([regex]::IsMatch($body, $keyPattern)) {
                $body = [regex]::Replace($body, $keyPattern, [Text.RegularExpressions.MatchEvaluator]{
                    param($match)
                    $match.Groups[1].Value + $value + $match.Groups[3].Value
                })
            } else {
                if ($body.Length -gt 0 -and $body -notmatch '\n$') { $body += $newline }
                $body += "$key=$value$newline"
            }
        }
        $Text = $Text.Substring(0, $start) + $body + $Text.Substring($start + $length)
    }
    return $Text
}

function Get-ScopedBackupDirectory {
    param([string]$ConfigPath, [string]$BackupRoot)
    $fullPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ConfigPath)
    $BackupRoot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($BackupRoot)
    if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) { $fullPath = $fullPath.ToLowerInvariant() }
    $key = Get-BytesHash ([Text.Encoding]::UTF8.GetBytes($fullPath))
    return Join-Path $BackupRoot $key
}

function Assert-FortniteClosed {
    $running = @(Get-Process -ErrorAction Stop | Where-Object {
        $_.ProcessName -like 'FortniteClient*' -or $_.ProcessName -eq 'FortniteLauncher'
    })
    if ($running.Count -gt 0) { throw 'Beende Fortnite, bevor du Einstellungen aenderst oder wiederherstellst.' }
}

function Assert-WritableSettings {
    param([string]$ConfigPath)
    $item = Get-Item -LiteralPath $ConfigPath -ErrorAction Stop
    if ($item.Attributes -band [IO.FileAttributes]::ReadOnly) {
        throw 'Die Einstellungsdatei ist schreibgeschuetzt. Entferne den Schreibschutz bewusst und versuche es erneut.'
    }
}

function Save-SettingsBackup {
    param([byte[]]$Bytes, [string]$Directory, [string]$Kind)
    [void][IO.Directory]::CreateDirectory($Directory)
    $name = $Kind + '-' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ') + '-' + [guid]::NewGuid().ToString('N') + '.ini'
    $path = Join-Path $Directory $name
    [IO.File]::WriteAllBytes($path, $Bytes)
    [IO.File]::WriteAllText($path + '.sha256', (Get-BytesHash $Bytes), [Text.Encoding]::ASCII)
    return $path
}

function Write-SettingsAtomically {
    param([string]$ConfigPath, [byte[]]$Bytes, [byte[]]$ExpectedBytes)
    $temporary = Join-Path ([IO.Path]::GetDirectoryName($ConfigPath)) ([guid]::NewGuid().ToString('N') + '.tmp')
    try {
        [IO.File]::WriteAllBytes($temporary, $Bytes)
        $current = [IO.File]::ReadAllBytes($ConfigPath)
        if ((Get-BytesHash $current) -ne (Get-BytesHash $ExpectedBytes)) {
            throw 'Die Datei wurde zwischenzeitlich geaendert. Wiederhole den Vorgang bei geschlossenem Fortnite.'
        }
        Assert-FortniteClosed
        [IO.File]::Replace($temporary, $ConfigPath, [NullString]::Value)
    } finally {
        if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
    }
}

function Get-FortniteProfile {
    foreach ($section in $script:Profile.Keys) {
        foreach ($key in $script:Profile[$section].Keys) {
            [pscustomobject]@{ Section = $section; Setting = $key; Value = $script:Profile[$section][$key] }
        }
    }
}

function Get-FortniteBackups {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ConfigPath, [Parameter(Mandatory)][string]$BackupRoot)
    $directory = Get-ScopedBackupDirectory $ConfigPath $BackupRoot
    if (-not [IO.Directory]::Exists($directory)) { return }
    Get-ChildItem -LiteralPath $directory -Filter 'apply-*.ini' -File |
        Where-Object { [IO.File]::Exists($_.FullName + '.sha256') } |
        Sort-Object Name -Descending
}

function Get-FortniteProfilePreview {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ConfigPath, [AllowEmptyCollection()][string[]]$Options, [int]$FrameRateLimit = 144)
    $profile = $script:Profile
    if ($PSBoundParameters.ContainsKey('Options')) { $profile = Get-SelectedSettingsPatch @($Options) $FrameRateLimit }
    $settings = Read-SettingsFile $ConfigPath
    # Validate all target sections before returning a partial preview.
    [void](ConvertTo-CompetitiveSettings $settings.Text $profile)
    foreach ($section in $profile.Keys) {
        $headerPattern = '(?im)^[ \t]*\[' + [regex]::Escape($section) + '\][ \t]*(?:[;#][^\r\n]*)?(?:\r\n|\n|$)'
        $header = [regex]::Match($settings.Text, $headerPattern)
        $body = ''
        if ($header.Success) {
            $body = $settings.Text.Substring($header.Index + $header.Length)
            $next = [regex]::Match($body, '(?m)^[ \t]*\[[^\r\n\]]+\]')
            if ($next.Success) { $body = $body.Substring(0, $next.Index) }
        }
        foreach ($key in $profile[$section].Keys) {
            $keyMatches = [regex]::Matches($body, '(?im)^[ \t]*' + [regex]::Escape($key) + '[ \t]*=[ \t]*([^;#\r\n]*)')
            $values = @($keyMatches | ForEach-Object { $_.Groups[1].Value.Trim() })
            $target = $profile[$section][$key]
            $current = 'Nicht gesetzt'
            if ($values.Count -gt 0) { $current = $values -join ', ' }
            [pscustomobject]@{
                Section = $section; Setting = $key; CurrentValue = $current; ProfileValue = $target
                NeedsChange = ($values.Count -eq 0 -or @($values | Where-Object { $_ -cne $target }).Count -gt 0)
            }
        }
    }
}

function Set-FortniteCompetitiveProfile {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$ConfigPath, [Parameter(Mandatory)][string]$BackupRoot, [AllowEmptyCollection()][string[]]$Options, [int]$FrameRateLimit = 144)
    $profile = $script:Profile
    if ($PSBoundParameters.ContainsKey('Options')) { $profile = Get-SelectedSettingsPatch @($Options) $FrameRateLimit }
    Assert-FortniteClosed
    $settings = Read-SettingsFile $ConfigPath
    $updated = ConvertTo-CompetitiveSettings $settings.Text $profile
    if ($updated -ceq $settings.Text) { return [pscustomobject]@{ Status = 'Unchanged'; Backup = $null } }
    Assert-WritableSettings $settings.Path
    if (-not $PSCmdlet.ShouldProcess($settings.Path, 'Sichern und Grafikprofil anwenden')) { return }
    [byte[]]$bytes = $settings.Preamble + $settings.Encoding.GetBytes($updated)
    $directory = Get-ScopedBackupDirectory $settings.Path $BackupRoot
    $backup = Save-SettingsBackup $settings.Bytes $directory 'apply'
    Write-SettingsAtomically $settings.Path $bytes $settings.Bytes
    return [pscustomobject]@{ Status = 'Applied'; Backup = $backup }
}

function Restore-FortniteBackup {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$ConfigPath,
        [Parameter(Mandatory)][string]$BackupRoot,
        [string]$BackupName
    )
    Assert-FortniteClosed
    $settings = Read-SettingsFile $ConfigPath
    $backups = @(Get-FortniteBackups $settings.Path $BackupRoot)
    if ($BackupName) { $backups = @($backups | Where-Object { $_.Name -ceq $BackupName }) }
    if ($backups.Count -eq 0) { throw 'Keine passende Sicherung gefunden.' }
    $backup = $backups[0]
    $backupSettings = Read-SettingsFile $backup.FullName
    $expectedHash = [IO.File]::ReadAllText($backup.FullName + '.sha256').Trim()
    if ($expectedHash -cne (Get-BytesHash $backupSettings.Bytes)) { throw 'Die Sicherung ist beschaedigt (SHA256 stimmt nicht).' }
    if ((Get-BytesHash $settings.Bytes) -ceq $expectedHash) {
        return [pscustomobject]@{ Status = 'Unchanged'; Backup = $backup.FullName; SafetyBackup = $null }
    }
    Assert-WritableSettings $settings.Path
    if (-not $PSCmdlet.ShouldProcess($settings.Path, ('Sicherung wiederherstellen: ' + $backup.Name))) { return }
    $directory = Get-ScopedBackupDirectory $settings.Path $BackupRoot
    $safety = Save-SettingsBackup $settings.Bytes $directory 'before-restore'
    Write-SettingsAtomically $settings.Path $backupSettings.Bytes $settings.Bytes
    return [pscustomobject]@{ Status = 'Restored'; Backup = $backup.FullName; SafetyBackup = $safety }
}

Export-ModuleMember -Function Get-FortniteProfile, Get-FortniteProfilePreview, Get-FortniteOptimizationOptions, Get-FortniteBackups, Set-FortniteCompetitiveProfile, Restore-FortniteBackup
