#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../src/FortniteTweaks.psm1') -Force
$script:passed = 0
$script:failed = 0
$script:skipped = 0
$script:testRoot = Join-Path ([IO.Path]::GetTempPath()) ('fortnite-tweaks-tests-' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($script:testRoot)
$script:sample = @'
; Original settings
[ScalabilityGroups]
sg.ResolutionQuality=85.000000
sg.ViewDistanceQuality=2
sg.ShadowQuality=3 ; keep comment
sg.TextureQuality=3
; sg.EffectsQuality=3
[/Script/FortniteGame.FortGameUserSettings]
ResolutionSizeX=2560
ResolutionSizeY=1440
FrameRateLimit=165.000000
bUseVSync=True
bMotionBlur=True
PreferredRHI=dx12
PlayerName=Spieler
[OtherSettings]
sg.ShadowQuality=9
bUseVSync=True
'@

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-BytesEqual {
    param([byte[]]$Expected, [byte[]]$Actual)
    Assert-True ([Convert]::ToBase64String($Expected) -ceq [Convert]::ToBase64String($Actual)) 'Byte contents differ.'
}

function Assert-Throws {
    param([scriptblock]$Body, [string]$Pattern)
    $failure = $null
    try { & $Body | Out-Null } catch { $failure = $_ }
    Assert-True ($null -ne $failure) 'Expected an error, but the operation succeeded.'
    if ($Pattern) { Assert-True ($failure.Exception.Message -match $Pattern) "Unexpected error: $failure" }
}

function New-Fixture {
    param([string]$Text = $script:sample, [Text.Encoding]$Encoding = (New-Object Text.UTF8Encoding($false)))
    $directory = Join-Path $script:testRoot ([guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($directory)
    $config = Join-Path $directory 'GameUserSettings.ini'
    [byte[]]$bytes = $Encoding.GetPreamble() + $Encoding.GetBytes($Text)
    [IO.File]::WriteAllBytes($config, $bytes)
    return [pscustomobject]@{
        Config = $config; Root = (Join-Path $directory 'backups'); Original = $bytes
    }
}

function Test-Case {
    param([string]$Name, [scriptblock]$Body)
    try {
        & $Body
        $script:passed++
        Write-Host "PASS $Name"
    } catch {
        $script:failed++
        Write-Host "FAIL $Name : $_" -ForegroundColor Red
        Write-Host $_.ScriptStackTrace
    }
}

try {
    . (Join-Path $PSScriptRoot 'PowerPlan.Tests.ps1')
    . (Join-Path $PSScriptRoot 'Input.Tests.ps1')

    Test-Case 'Manual VSync option leaves all other game settings unchanged' {
        $f = New-Fixture
        $result = Set-FortniteCompetitiveProfile $f.Config $f.Root -Options VSyncOff
        # Account for Windows checkout line endings without touching other sections.
        $expected = [regex]::Replace($script:sample, '(bUseVSync=)True(?=\r?\nbMotionBlur)', '${1}False')
        Assert-BytesEqual ([Text.Encoding]::UTF8.GetBytes($expected)) ([IO.File]::ReadAllBytes($f.Config))
        Assert-BytesEqual $f.Original ([IO.File]::ReadAllBytes($result.Backup))
    }

    Test-Case 'Manual shadows and effects do not change textures, VSync or FPS' {
        $f = New-Fixture
        Set-FortniteCompetitiveProfile $f.Config $f.Root -Options Shadows,Effects | Out-Null
        $text = [IO.File]::ReadAllText($f.Config)
        Assert-True ($text -match 'sg.ShadowQuality=0' -and $text -match 'sg.EffectsQuality=0') 'Selected options were not applied.'
        Assert-True ($text.Contains('sg.TextureQuality=3') -and $text.Contains('bUseVSync=True') -and $text.Contains('FrameRateLimit=165.000000')) 'Unselected settings changed.'
        Assert-True (@(Get-FortniteProfile).Count -eq 11) 'Manual options mutated the default profile.'
    }

    Test-Case 'Manual FPS cap changes only the cap and is repeatable and restorable' {
        $f = New-Fixture
        Set-FortniteCompetitiveProfile $f.Config $f.Root -Options FpsCap -FrameRateLimit 237 | Out-Null
        $text = [IO.File]::ReadAllText($f.Config)
        Assert-True ($text -ceq $script:sample.Replace('FrameRateLimit=165.000000', 'FrameRateLimit=237.000000')) 'FPS option changed unrelated values.'
        Assert-True ((Set-FortniteCompetitiveProfile $f.Config $f.Root -Options FpsCap -FrameRateLimit 237).Status -eq 'Unchanged') 'FPS apply is not repeatable.'
        $preview = @(Get-FortniteProfilePreview $f.Config -Options FpsCap -FrameRateLimit 237)
        Assert-True ($preview.Count -eq 1 -and -not $preview[0].NeedsChange) 'FPS preview disagrees with written value.'
        Restore-FortniteBackup $f.Config $f.Root | Out-Null
        Assert-BytesEqual $f.Original ([IO.File]::ReadAllBytes($f.Config))
    }

    Test-Case 'No selection, unknown options and invalid FPS caps cannot change files' {
        $f = New-Fixture
        Assert-Throws { Set-FortniteCompetitiveProfile $f.Config $f.Root -Options @() } 'mindestens'
        Assert-Throws { Set-FortniteCompetitiveProfile $f.Config $f.Root -Options Unknown } 'Unbekannte'
        foreach ($invalid in @(0, 29, 1001)) {
            Assert-Throws { Set-FortniteCompetitiveProfile $f.Config $f.Root -Options FpsCap -FrameRateLimit $invalid } '30 bis 1000'
        }
        Assert-BytesEqual $f.Original ([IO.File]::ReadAllBytes($f.Config))
        Assert-True (-not (Test-Path -LiteralPath $f.Root)) 'Invalid selection created a backup.'
    }

    Test-Case 'Manual preview and WhatIf never apply selected changes' {
        $f = New-Fixture
        $preview = @(Get-FortniteProfilePreview $f.Config -Options MotionBlurOff,FpsCap -FrameRateLimit 240)
        Assert-True ($preview.Count -eq 2 -and $preview[1].ProfileValue -eq '240.000000') 'Selected preview has the wrong settings.'
        Set-FortniteCompetitiveProfile $f.Config $f.Root -Options MotionBlurOff,FpsCap -FrameRateLimit 240 -WhatIf
        Assert-BytesEqual $f.Original ([IO.File]::ReadAllBytes($f.Config))
        Assert-True (-not (Test-Path -LiteralPath $f.Root)) 'Preview created backups.'
    }

    Test-Case 'Packaged executable checksum and embedded source files' {
        & (Join-Path $PSScriptRoot 'Test-Executable.ps1')
    }
    Test-Case 'Preview reads current values from the correct section without writing' {
        $f = New-Fixture
        $rows = @(Get-FortniteProfilePreview $f.Config)
        Assert-True ($rows.Count -eq 11) 'Preview has the wrong number of settings.'
        $shadow = @($rows | Where-Object { $_.Setting -eq 'sg.ShadowQuality' })[0]
        Assert-True ($shadow.CurrentValue -eq '3' -and $shadow.ProfileValue -eq '0' -and $shadow.NeedsChange) 'Shadow preview is incorrect.'
        $missing = @($rows | Where-Object { $_.Setting -eq 'sg.EffectsQuality' })[0]
        Assert-True ($missing.CurrentValue -eq 'Nicht gesetzt' -and $missing.NeedsChange) 'Commented setting treated as active.'
        Assert-BytesEqual $f.Original ([IO.File]::ReadAllBytes($f.Config))
        Assert-True (-not (Test-Path -LiteralPath $f.Root)) 'Preview created backups.'
    }

    Test-Case 'Preview reports no changes after applying the profile' {
        $f = New-Fixture
        Set-FortniteCompetitiveProfile $f.Config $f.Root | Out-Null
        $rows = @(Get-FortniteProfilePreview $f.Config)
        Assert-True ($rows.Count -eq 11 -and @($rows | Where-Object { $_.NeedsChange }).Count -eq 0) 'Preview and applied settings disagree.'
    }

    Test-Case 'Preview rejects ambiguous sections rather than showing misleading values' {
        $f = New-Fixture -Text ($script:sample + "`n[ScalabilityGroups]`nsg.ShadowQuality=2")
        Assert-Throws { Get-FortniteProfilePreview $f.Config } 'mehrfach'
        Assert-BytesEqual $f.Original ([IO.File]::ReadAllBytes($f.Config))
    }

    Test-Case 'Apply profile, preserve unrelated values, and save exact original bytes' {
        $f = New-Fixture
        $result = Set-FortniteCompetitiveProfile $f.Config $f.Root
        Assert-True ($result.Status -eq 'Applied') 'Apply did not run.'
        $text = [IO.File]::ReadAllText($f.Config)
        Assert-True ($text -match 'sg.ShadowQuality=0 ; keep comment') 'Shadow value or comment incorrect.'
        Assert-True ($text -match 'sg.TextureQuality=1') 'Texture value incorrect.'
        Assert-True ($text -match 'sg.EffectsQuality=0') 'Missing effect setting was not inserted.'
        Assert-True ($text -match 'bUseVSync=False' -and $text -match 'bMotionBlur=False') 'Boolean settings incorrect.'
        foreach ($line in @('sg.ResolutionQuality=85.000000', 'sg.ViewDistanceQuality=2', 'ResolutionSizeX=2560', 'ResolutionSizeY=1440', 'FrameRateLimit=165.000000', 'PreferredRHI=dx12', '; sg.EffectsQuality=3')) {
            Assert-True ($text.Contains($line)) "Unrelated setting was changed: $line"
        }
        Assert-True ($text -match '(?s)\[OtherSettings\]\r?\nsg.ShadowQuality=9\r?\nbUseVSync=True') 'Another section was changed.'
        Assert-BytesEqual $f.Original ([IO.File]::ReadAllBytes($result.Backup))
        Assert-True ((Get-Item -LiteralPath ($result.Backup + '.sha256')).Length -eq 64) 'Checksum missing.'
        Assert-True (@(Get-ChildItem -LiteralPath (Split-Path $f.Config) -Filter '*.tmp').Count -eq 0) 'Temporary file leaked.'
    }

    Test-Case 'Repeated apply is a no-op with no extra backup' {
        $f = New-Fixture
        Set-FortniteCompetitiveProfile $f.Config $f.Root | Out-Null
        $before = [IO.File]::ReadAllBytes($f.Config)
        $result = Set-FortniteCompetitiveProfile $f.Config $f.Root
        Assert-True ($result.Status -eq 'Unchanged') 'Second apply was not a no-op.'
        Assert-True (@(Get-FortniteBackups $f.Config $f.Root).Count -eq 1) 'Unexpected extra backup.'
        Assert-BytesEqual $before ([IO.File]::ReadAllBytes($f.Config))
    }

    Test-Case 'Restore exact original and preserve pre-restore state; repeat restore is a no-op' {
        $f = New-Fixture
        Set-FortniteCompetitiveProfile $f.Config $f.Root | Out-Null
        $applied = [IO.File]::ReadAllBytes($f.Config)
        $result = Restore-FortniteBackup $f.Config $f.Root
        Assert-True ($result.Status -eq 'Restored') 'Restore did not run.'
        Assert-BytesEqual $f.Original ([IO.File]::ReadAllBytes($f.Config))
        Assert-BytesEqual $applied ([IO.File]::ReadAllBytes($result.SafetyBackup))
        $again = Restore-FortniteBackup $f.Config $f.Root
        Assert-True ($again.Status -eq 'Unchanged') 'Repeated restore was not a no-op.'
        Assert-True (@(Get-ChildItem -LiteralPath (Split-Path $result.Backup) -Filter 'before-restore-*.ini').Count -eq 1) 'Unexpected safety backup.'
    }

    Test-Case 'Apply preview writes neither settings nor backup directory' {
        $f = New-Fixture
        Set-FortniteCompetitiveProfile $f.Config $f.Root -WhatIf
        Assert-BytesEqual $f.Original ([IO.File]::ReadAllBytes($f.Config))
        Assert-True (-not (Test-Path -LiteralPath $f.Root)) 'Preview created backup directory.'
    }

    Test-Case 'Restore preview leaves current file and backups unchanged' {
        $f = New-Fixture
        $apply = Set-FortniteCompetitiveProfile $f.Config $f.Root
        $current = [IO.File]::ReadAllBytes($f.Config)
        Restore-FortniteBackup $f.Config $f.Root -WhatIf
        Assert-BytesEqual $current ([IO.File]::ReadAllBytes($f.Config))
        Assert-True (@(Get-ChildItem -LiteralPath (Split-Path $apply.Backup) -Filter '*.ini').Count -eq 1) 'Restore preview wrote a backup.'
    }

    Test-Case 'Corrupted backup is rejected before writing' {
        $f = New-Fixture
        $apply = Set-FortniteCompetitiveProfile $f.Config $f.Root
        $current = [IO.File]::ReadAllBytes($f.Config)
        [IO.File]::AppendAllText($apply.Backup, "`n; corruption")
        Assert-Throws { Restore-FortniteBackup $f.Config $f.Root } 'SHA256'
        Assert-BytesEqual $current ([IO.File]::ReadAllBytes($f.Config))
    }

    Test-Case 'Backups are scoped to each configuration path' {
        $first = New-Fixture
        $second = New-Fixture
        Set-FortniteCompetitiveProfile $first.Config $first.Root | Out-Null
        Assert-True (@(Get-FortniteBackups $second.Config $first.Root).Count -eq 0) 'Backup leaked to another config.'
        Assert-Throws { Restore-FortniteBackup $second.Config $first.Root } 'Keine passende'
        Assert-BytesEqual $second.Original ([IO.File]::ReadAllBytes($second.Config))
    }

    Test-Case 'An older backup can be selected explicitly' {
        $f = New-Fixture
        $first = Set-FortniteCompetitiveProfile $f.Config $f.Root
        $changed = [IO.File]::ReadAllText($f.Config).Replace('sg.ShadowQuality=0', 'sg.ShadowQuality=2')
        [IO.File]::WriteAllText($f.Config, $changed, (New-Object Text.UTF8Encoding($false)))
        Set-FortniteCompetitiveProfile $f.Config $f.Root | Out-Null
        Assert-True (@(Get-FortniteBackups $f.Config $f.Root).Count -eq 2) 'Second backup missing.'
        Restore-FortniteBackup $f.Config $f.Root -BackupName ([IO.Path]::GetFileName($first.Backup)) | Out-Null
        Assert-BytesEqual $f.Original ([IO.File]::ReadAllBytes($f.Config))
    }

    Test-Case 'Backup name cannot point outside the scoped backup directory' {
        $f = New-Fixture
        Set-FortniteCompetitiveProfile $f.Config $f.Root | Out-Null
        $current = [IO.File]::ReadAllBytes($f.Config)
        Assert-Throws { Restore-FortniteBackup $f.Config $f.Root -BackupName '../outside.ini' } 'Keine passende'
        Assert-BytesEqual $current ([IO.File]::ReadAllBytes($f.Config))
    }

    Test-Case 'Missing or unrelated configuration is rejected without backups' {
        $f = New-Fixture -Text '[Unrelated]'
        Assert-Throws { Set-FortniteCompetitiveProfile $f.Config $f.Root } 'Keine Fortnite'
        Assert-BytesEqual $f.Original ([IO.File]::ReadAllBytes($f.Config))
        Assert-Throws { Set-FortniteCompetitiveProfile ($f.Config + '.missing') $f.Root }
        Assert-True (-not (Test-Path -LiteralPath $f.Root)) 'Backup created for invalid file.'
    }

    Test-Case 'Duplicate target sections are rejected without writes' {
        $f = New-Fixture -Text ($script:sample + "`n[ScalabilityGroups]`nsg.ShadowQuality=2")
        Assert-Throws { Set-FortniteCompetitiveProfile $f.Config $f.Root } 'mehrfach'
        Assert-BytesEqual $f.Original ([IO.File]::ReadAllBytes($f.Config))
        Assert-True (-not (Test-Path -LiteralPath $f.Root)) 'Backup created for duplicate section.'
    }

    Test-Case 'Read-only config is not changed or made writable' {
        $f = New-Fixture
        [IO.File]::SetAttributes($f.Config, [IO.FileAttributes]::ReadOnly)
        try {
            Assert-Throws { Set-FortniteCompetitiveProfile $f.Config $f.Root } 'schreibgeschuetzt'
            Assert-BytesEqual $f.Original ([IO.File]::ReadAllBytes($f.Config))
            Assert-True (([IO.File]::GetAttributes($f.Config) -band [IO.FileAttributes]::ReadOnly) -ne 0) 'Read-only attribute changed.'
        } finally { [IO.File]::SetAttributes($f.Config, [IO.FileAttributes]::Normal) }
    }

    foreach ($kind in @('UTF8-BOM', 'UTF16-LE', 'UTF16-BE')) {
        Test-Case "Preserve $kind encoding and restore byte-for-byte" {
            $encoding = switch ($kind) {
                'UTF8-BOM' { New-Object Text.UTF8Encoding($true) }
                'UTF16-LE' { New-Object Text.UnicodeEncoding($false, $true) }
                'UTF16-BE' { New-Object Text.UnicodeEncoding($true, $true) }
            }
            $unicodeName = 'Spieler-' + [char]0x00fc
            $f = New-Fixture -Text ($script:sample.Replace('Spieler', $unicodeName)) -Encoding $encoding
            Set-FortniteCompetitiveProfile $f.Config $f.Root | Out-Null
            $bytes = [IO.File]::ReadAllBytes($f.Config)
            Assert-BytesEqual ($encoding.GetPreamble()) ([byte[]]$bytes[0..($encoding.GetPreamble().Length - 1)])
            Assert-True ([IO.File]::ReadAllText($f.Config).Contains($unicodeName)) 'Unicode text was corrupted.'
            Restore-FortniteBackup $f.Config $f.Root | Out-Null
            Assert-BytesEqual $f.Original ([IO.File]::ReadAllBytes($f.Config))
        }
    }

    foreach ($style in @('LF', 'CRLF')) {
        Test-Case "Preserve $style line endings" {
            $text = $script:sample.Replace("`r`n", "`n")
            if ($style -eq 'CRLF') { $text = $text.Replace("`n", "`r`n") }
            $f = New-Fixture -Text $text
            Set-FortniteCompetitiveProfile $f.Config $f.Root | Out-Null
            $updated = [IO.File]::ReadAllText($f.Config)
            if ($style -eq 'LF') { Assert-True (-not $updated.Contains("`r")) 'CR inserted into LF file.' }
            else { Assert-True ($updated -notmatch '(?<!\r)\n') 'Bare LF inserted into CRLF file.' }
        }
    }

    Test-Case 'Create missing scalability section and handle final header without newline' {
        $f = New-Fixture -Text '[/Script/FortniteGame.FortGameUserSettings]'
        Set-FortniteCompetitiveProfile $f.Config $f.Root | Out-Null
        $text = [IO.File]::ReadAllText($f.Config)
        Assert-True ($text -match '(?s)FortGameUserSettings\]\r\nbUseVSync=False') 'First key joined onto header.'
        Assert-True ($text -match '\[ScalabilityGroups\]' -and $text -match 'sg.TextureQuality=1') 'Missing section not created.'
        Assert-True ((Set-FortniteCompetitiveProfile $f.Config $f.Root).Status -eq 'Unchanged') 'Generated profile is not stable.'
    }

    Test-Case 'Case-insensitive keys preserve original spelling and whitespace' {
        $text = $script:sample.Replace('[ScalabilityGroups]', '[scalabilitygroups]').Replace('sg.ShadowQuality=3 ; keep comment', ' SG.SHADOWQUALITY = 3 ; keep comment')
        $f = New-Fixture -Text $text
        Set-FortniteCompetitiveProfile $f.Config $f.Root | Out-Null
        Assert-True ([IO.File]::ReadAllText($f.Config).Contains(' SG.SHADOWQUALITY = 0 ; keep comment')) 'Formatting or case lost.'
    }

    Test-Case 'Invalid UTF-8 fails before backup or edit' {
        $f = New-Fixture
        [byte[]]$invalid = $f.Original + [byte[]]@(255, 255)
        [IO.File]::WriteAllBytes($f.Config, $invalid)
        Assert-Throws { Set-FortniteCompetitiveProfile $f.Config $f.Root } 'Zeichenkodierung'
        Assert-BytesEqual $invalid ([IO.File]::ReadAllBytes($f.Config))
        Assert-True (-not (Test-Path -LiteralPath $f.Root)) 'Backup created for invalid encoding.'
    }

    Test-Case 'Backup storage failure leaves current settings intact' {
        $f = New-Fixture
        [IO.File]::WriteAllText($f.Root, 'This is a file, not a directory.')
        Assert-Throws { Set-FortniteCompetitiveProfile $f.Config $f.Root }
        Assert-BytesEqual $f.Original ([IO.File]::ReadAllBytes($f.Config))
    }

    Test-Case 'Running Fortnite blocks apply and restore before creating backups' {
        $f = New-Fixture
        $module = Get-Module FortniteTweaks
        & $module { Set-Item Function:script:Get-Process { [pscustomobject]@{ ProcessName = 'FortniteClient-Win64-Shipping' } } }
        try {
            Assert-Throws { Set-FortniteCompetitiveProfile $f.Config $f.Root } 'Beende Fortnite'
            Assert-Throws { Restore-FortniteBackup $f.Config $f.Root } 'Beende Fortnite'
            Assert-BytesEqual $f.Original ([IO.File]::ReadAllBytes($f.Config))
            Assert-True (-not (Test-Path -LiteralPath $f.Root)) 'Backup created while game running.'
        } finally { & $module { Remove-Item Function:Get-Process } }
    }

    Test-Case 'Concurrent modification is preserved and temporary write is cleaned up' {
        $f = New-Fixture
        $changed = [Text.Encoding]::UTF8.GetBytes($script:sample + "`n; external edit")
        [IO.File]::WriteAllBytes($f.Config, $changed)
        $module = Get-Module FortniteTweaks
        Assert-Throws {
            & $module { param($path, $expected) Write-SettingsAtomically $path $expected $expected } $f.Config $f.Original
        } 'zwischenzeitlich'
        Assert-BytesEqual $changed ([IO.File]::ReadAllBytes($f.Config))
        Assert-True (@(Get-ChildItem -LiteralPath (Split-Path $f.Config) -Filter '*.tmp').Count -eq 0) 'Temporary file leaked.'
    }

    Test-Case 'Relative config and backup paths follow the PowerShell working directory' {
        $f = New-Fixture
        Push-Location (Split-Path $f.Config)
        try {
            Set-FortniteCompetitiveProfile './GameUserSettings.ini' './backups' | Out-Null
            Assert-True (@(Get-FortniteBackups './GameUserSettings.ini' './backups').Count -eq 1) 'Relative backup lookup failed.'
            Restore-FortniteBackup './GameUserSettings.ini' './backups' | Out-Null
            Assert-BytesEqual $f.Original ([IO.File]::ReadAllBytes($f.Config))
        } finally { Pop-Location }
    }

    if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
        Test-Case 'Graphical launcher: load WPF and exercise its actual buttons in STA' {
            $engine = (Get-Process -Id $PID).Path
            & $engine -NoProfile -STA -File (Join-Path $PSScriptRoot 'Test-Launcher.ps1')
            Assert-True ($LASTEXITCODE -eq 0) 'Graphical launcher tests failed.'
        }
        Test-Case 'Windows entry point: status, hardware, apply preview, apply, restore preview, restore' {
            $f = New-Fixture
            $entry = Join-Path $PSScriptRoot '../Fortnite-Tweaks.ps1'
            $parameters = @{ ConfigPath = $f.Config; BackupRoot = $f.Root }
            & $entry -Action Status @parameters
            & $entry -Action System @parameters
            & $entry -Action Apply -WhatIf @parameters
            Assert-BytesEqual $f.Original ([IO.File]::ReadAllBytes($f.Config))
            Assert-True (-not (Test-Path -LiteralPath $f.Root)) 'Entry point preview wrote backups.'
            & $entry -Action Apply @parameters
            $applied = [IO.File]::ReadAllBytes($f.Config)
            Assert-True ([Convert]::ToBase64String($applied) -cne [Convert]::ToBase64String($f.Original)) 'Entry point did not apply profile.'
            & $entry -Action Backups @parameters
            & $entry -Action Restore -WhatIf @parameters
            Assert-BytesEqual $applied ([IO.File]::ReadAllBytes($f.Config))
            & $entry -Action Restore @parameters
            Assert-BytesEqual $f.Original ([IO.File]::ReadAllBytes($f.Config))
        }
    } else {
        $script:skipped += 3
        Write-Host 'SKIP Windows entry point and hardware detection (requires Windows).'
        Write-Host 'SKIP WPF launcher and its buttons (requires Windows and STA).'
        Write-Host 'SKIP Starting the packaged Windows executable (requires Windows).'
    }
} finally {
    Remove-Item -LiteralPath $script:testRoot -Recurse -Force
}

Write-Host "Tests: $script:passed passed, $script:failed failed, $script:skipped skipped."
if ($script:failed -gt 0) { exit 1 }
if ($script:passed -eq 0) { throw 'No tests executed.' }
