Set-StrictMode -Version Latest
$script:KeyboardFields = @('Flags', 'Wait', 'Delay', 'Repeat', 'Bounce')

function Initialize-FortniteInputNative {
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'Eingabegeraete-Einstellungen benoetigen Windows.' }
    if (-not ('FortniteTweaks.InputNative' -as [type])) { Add-Type -Path (Join-Path $PSScriptRoot 'InputNative.cs') -ErrorAction Stop }
}

function Read-NativeKeyboard {
    Initialize-FortniteInputNative
    $values = [FortniteTweaks.InputNative]::ReadFilterKeys()
    return [pscustomobject]@{ Flags = $values.Flags; Wait = $values.Wait; Delay = $values.Delay; Repeat = $values.Repeat; Bounce = $values.Bounce }
}

function Write-NativeKeyboard {
    param($Values)
    Initialize-FortniteInputNative
    [FortniteTweaks.InputNative]::WriteFilterKeys($Values.Flags, $Values.Wait, $Values.Delay, $Values.Repeat, $Values.Bounce)
}

function Test-KeyboardValuesEqual {
    param($First, $Second)
    foreach ($name in $script:KeyboardFields) { if ($First.$name -ne $Second.$name) { return $false } }
    return $true
}

function Get-KeyboardDisabledValues {
    param($Original)
    return [pscustomobject]@{ Flags = ([uint32]$Original.Flags -band [uint32]4294967294); Wait = $Original.Wait; Delay = $Original.Delay; Repeat = $Original.Repeat; Bounce = $Original.Bounce }
}

function Read-KeyboardBackup {
    param([string]$StatePath)
    if (-not [IO.File]::Exists($StatePath)) { return $null }
    try {
        $data = [IO.File]::ReadAllText($StatePath) | ConvertFrom-Json
        if ($data.Version -ne 1) { throw 'Unsupported version.' }
        foreach ($name in $script:KeyboardFields) {
            $number = 0L
            $maximum = 20000L
            if ($name -eq 'Flags') { $maximum = 4294967295L }
            if (-not [long]::TryParse([string]$data.Original.$name, [ref]$number) -or $number -lt 0 -or $number -gt $maximum) { throw 'Invalid field.' }
        }
        if (([uint32]$data.Original.Flags -band 1) -eq 0) { throw 'No original enabled state.' }
        return $data.Original
    } catch { throw 'Die Tastatur-Sicherung ist ungueltig. Es wurden keine Eingabeeinstellungen geaendert.' }
}

function Get-FortniteKeyboardState {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$StatePath)
    $StatePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($StatePath)
    $current = Read-NativeKeyboard
    $original = Read-KeyboardBackup $StatePath
    $canRestore = $false
    if ($null -ne $original) { $canRestore = (Test-KeyboardValuesEqual $current $original) -or (Test-KeyboardValuesEqual $current (Get-KeyboardDisabledValues $original)) }
    return [pscustomobject]@{ FilterKeysEnabled = (([uint32]$current.Flags -band 1) -ne 0); AcceptanceDelayMs = $current.Wait; CanRestore = $canRestore }
}

function Disable-FortniteKeyboardFilter {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$StatePath)
    $StatePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($StatePath)
    $current = Read-NativeKeyboard
    if (([uint32]$current.Flags -band 1) -eq 0) { return [pscustomobject]@{ Status = 'Unchanged' } }
    [void](Read-KeyboardBackup $StatePath)
    if (-not $PSCmdlet.ShouldProcess('Windows-Filtertasten', 'Aktuellen Zustand sichern und Filtertasten deaktivieren')) { return }
    $directory = [IO.Path]::GetDirectoryName($StatePath)
    [void][IO.Directory]::CreateDirectory($directory)
    $temporary = Join-Path $directory ([guid]::NewGuid().ToString('N') + '.tmp')
    try {
        $data = [ordered]@{ Version = 1; Original = $current; CreatedUtc = [DateTime]::UtcNow.ToString('o') }
        [IO.File]::WriteAllText($temporary, ($data | ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding($false)))
        if ([IO.File]::Exists($StatePath)) { [IO.File]::Replace($temporary, $StatePath, [NullString]::Value) }
        else { [IO.File]::Move($temporary, $StatePath) }
        if (-not (Test-KeyboardValuesEqual (Read-NativeKeyboard) $current)) { throw 'Tastatureinstellungen wurden zwischenzeitlich geaendert. Wiederhole die Aktion.' }
        $disabled = Get-KeyboardDisabledValues $current
        Write-NativeKeyboard $disabled
        if (-not (Test-KeyboardValuesEqual (Read-NativeKeyboard) $disabled)) { throw 'Windows hat die Filtertasten-Aenderung nicht uebernommen. Die Sicherung bleibt erhalten.' }
        return [pscustomobject]@{ Status = 'Applied' }
    } finally {
        if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
    }
}

function Restore-FortniteKeyboardFilter {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$StatePath)
    $StatePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($StatePath)
    $original = Read-KeyboardBackup $StatePath
    if ($null -eq $original) { return [pscustomobject]@{ Status = 'Unchanged' } }
    $current = Read-NativeKeyboard
    $alreadyOriginal = Test-KeyboardValuesEqual $current $original
    if (-not $alreadyOriginal -and -not (Test-KeyboardValuesEqual $current (Get-KeyboardDisabledValues $original))) {
        throw 'Die Tastatureinstellungen wurden ausserhalb des Launchers geaendert und werden nicht ueberschrieben.'
    }
    if (-not $PSCmdlet.ShouldProcess('Windows-Filtertasten', 'Gesicherten Tastaturzustand wiederherstellen')) { return }
    if (-not $alreadyOriginal) {
        Write-NativeKeyboard $original
        if (-not (Test-KeyboardValuesEqual (Read-NativeKeyboard) $original)) { throw 'Windows hat den Tastaturzustand nicht wiederhergestellt. Die Sicherung bleibt erhalten.' }
    }
    [IO.File]::Delete($StatePath)
    return [pscustomobject]@{ Status = 'Restored' }
}

function Read-NativeControllers {
    Initialize-FortniteInputNative
    [FortniteTweaks.InputNative]::ReadControllers()
}

function Get-FortniteControllerState {
    [CmdletBinding()]
    param()
    Read-NativeControllers
}

Export-ModuleMember -Function Get-FortniteKeyboardState, Disable-FortniteKeyboardFilter, Restore-FortniteKeyboardFilter, Get-FortniteControllerState
