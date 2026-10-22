Set-StrictMode -Version Latest
$script:HighPerformance = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'

function Invoke-FortnitePowerCfg {
    param([string[]]$Arguments)
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'Energieplaene benoetigen Windows.' }
    $executable = Join-Path $env:SystemRoot 'System32/powercfg.exe'
    $text = & $executable @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw ("powercfg meldet einen Fehler: " + ($text -join ' ')) }
    return ($text -join [Environment]::NewLine)
}

function Get-ActiveSchemeId {
    $text = Invoke-FortnitePowerCfg @('/getactivescheme')
    $match = [regex]::Match($text, '(?i)[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}')
    if (-not $match.Success) { throw 'Der aktive Energieplan konnte nicht ermittelt werden.' }
    return $match.Value.ToLowerInvariant()
}

function Read-PowerPlanBackup {
    param([string]$StatePath)
    if (-not [IO.File]::Exists($StatePath)) { return $null }
    try {
        $data = [IO.File]::ReadAllText($StatePath) | ConvertFrom-Json
        $parsed = [guid]::Empty
        if ($data.Version -ne 1 -or $data.TargetSchemeId -cne $script:HighPerformance -or
            -not [guid]::TryParse([string]$data.OriginalSchemeId, [ref]$parsed) -or
            $parsed.ToString() -eq $script:HighPerformance) { throw 'Invalid power-plan backup.' }
        return $data
    } catch { throw 'Die Energieplan-Sicherung ist ungueltig. Es wurde kein Energieplan geaendert.' }
}

function Get-SchemeLabel {
    param([string]$Id)
    switch ($Id) {
        '381b4222-f694-41f0-9685-ff5bb260df2e' { return 'Ausbalanciert' }
        '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c' { return 'Hohe Leistung' }
        'a1841308-3541-4fab-bc81-f71556f20b4a' { return 'Energiesparmodus' }
        default { return 'Eigener Energieplan' }
    }
}

function Get-FortnitePowerPlanState {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$StatePath)
    $StatePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($StatePath)
    $active = Get-ActiveSchemeId
    $list = Invoke-FortnitePowerCfg @('/list')
    $backup = Read-PowerPlanBackup $StatePath
    [pscustomobject]@{
        ActiveSchemeId = $active; ActiveLabel = Get-SchemeLabel $active
        HighPerformanceAvailable = $list -match [regex]::Escape($script:HighPerformance)
        CanRestore = ($null -ne $backup -and ($active -eq $script:HighPerformance -or $active -eq $backup.OriginalSchemeId))
    }
}

function Enable-FortniteHighPerformance {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$StatePath)
    $StatePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($StatePath)
    $state = Get-FortnitePowerPlanState $StatePath
    if ($state.ActiveSchemeId -eq $script:HighPerformance) { return [pscustomobject]@{ Status = 'Unchanged' } }
    if (-not $state.HighPerformanceAvailable) { throw 'Der vorhandene PC bietet den Energieplan Hohe Leistung nicht an.' }
    if (-not $PSCmdlet.ShouldProcess('Windows-Energieplan', 'Vorherigen Plan sichern und Hohe Leistung aktivieren')) { return }
    $directory = [IO.Path]::GetDirectoryName($StatePath)
    [void][IO.Directory]::CreateDirectory($directory)
    $temporary = Join-Path $directory ([guid]::NewGuid().ToString('N') + '.tmp')
    $data = [ordered]@{ Version = 1; OriginalSchemeId = $state.ActiveSchemeId; TargetSchemeId = $script:HighPerformance; CreatedUtc = [DateTime]::UtcNow.ToString('o') }
    try {
        [IO.File]::WriteAllText($temporary, ($data | ConvertTo-Json), (New-Object Text.UTF8Encoding($false)))
        if ([IO.File]::Exists($StatePath)) { [IO.File]::Replace($temporary, $StatePath, [NullString]::Value) }
        else { [IO.File]::Move($temporary, $StatePath) }
        if ((Get-ActiveSchemeId) -ne $state.ActiveSchemeId) { throw 'Der Energieplan wurde zwischenzeitlich geaendert. Wiederhole die Aktion.' }
        [void](Invoke-FortnitePowerCfg @('/setactive', $script:HighPerformance))
        if ((Get-ActiveSchemeId) -ne $script:HighPerformance) { throw 'Windows hat den Energieplan nicht aktiviert.' }
        return [pscustomobject]@{ Status = 'Applied' }
    } finally {
        if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
    }
}

function Restore-FortnitePowerPlan {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$StatePath)
    $StatePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($StatePath)
    $backup = Read-PowerPlanBackup $StatePath
    if ($null -eq $backup) { return [pscustomobject]@{ Status = 'Unchanged' } }
    $active = Get-ActiveSchemeId
    if ($active -ne $script:HighPerformance -and $active -ne $backup.OriginalSchemeId) {
        throw 'Ein anderer Energieplan wurde ausserhalb des Launchers aktiviert. Er wird nicht ueberschrieben.'
    }
    if (-not $PSCmdlet.ShouldProcess('Windows-Energieplan', 'Gesicherten Energieplan wiederherstellen')) { return }
    if ($active -ne $backup.OriginalSchemeId) {
        [void](Invoke-FortnitePowerCfg @('/setactive', [string]$backup.OriginalSchemeId))
        if ((Get-ActiveSchemeId) -ne $backup.OriginalSchemeId) { throw 'Windows hat den vorherigen Energieplan nicht aktiviert. Die Sicherung bleibt erhalten.' }
    }
    [IO.File]::Delete($StatePath)
    return [pscustomobject]@{ Status = 'Restored' }
}

Export-ModuleMember -Function Get-FortnitePowerPlanState, Enable-FortniteHighPerformance, Restore-FortnitePowerPlan
