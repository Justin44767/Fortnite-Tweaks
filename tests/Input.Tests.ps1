# Dot-sourced by Run-Tests.ps1. Native writes are replaced with an in-memory OS adapter.
Import-Module (Join-Path $PSScriptRoot '../src/InputTweaks.psm1') -Force
$inputModule = Get-Module InputTweaks
$originalKeyboardRead = & $inputModule { (Get-Command Read-NativeKeyboard).ScriptBlock }
$originalKeyboardWrite = & $inputModule { (Get-Command Write-NativeKeyboard).ScriptBlock }
$originalControllerRead = & $inputModule { (Get-Command Read-NativeControllers).ScriptBlock }
$inputFake = [pscustomobject]@{ Current = $null; Writes = 0; Reads = 0; Fail = $false; Ignore = $false; Race = $false; StatePath = '' }
$keyboardReadFake = {
    $inputFake.Reads++
    if ($inputFake.Race -and $inputFake.Reads -eq 2) { $inputFake.Current.Wait = 777 }
    $v = $inputFake.Current
    [pscustomobject]@{ Flags = $v.Flags; Wait = $v.Wait; Delay = $v.Delay; Repeat = $v.Repeat; Bounce = $v.Bounce }
}.GetNewClosure()
$keyboardWriteFake = {
    param($Values)
    if (-not [IO.File]::Exists($inputFake.StatePath)) { throw 'Keyboard baseline was not saved before changing native settings.' }
    if ($inputFake.Fail) { throw 'Simulated native API denial' }
    $inputFake.Writes++
    if (-not $inputFake.Ignore) {
        $inputFake.Current = [pscustomobject]@{ Flags = $Values.Flags; Wait = $Values.Wait; Delay = $Values.Delay; Repeat = $Values.Repeat; Bounce = $Values.Bounce }
    }
}.GetNewClosure()
& $inputModule {
    param($read, $write)
    Set-Item Function:script:Read-NativeKeyboard $read
    Set-Item Function:script:Write-NativeKeyboard $write
} $keyboardReadFake $keyboardWriteFake

function New-InputFixture {
    $inputFake.Current = [pscustomobject]@{ Flags = 127; Wait = 400; Delay = 500; Repeat = 30; Bounce = 0 }
    $inputFake.Writes = 0; $inputFake.Reads = 0; $inputFake.Fail = $false; $inputFake.Ignore = $false; $inputFake.Race = $false
    $inputFake.StatePath = Join-Path (Join-Path $script:testRoot ([guid]::NewGuid().ToString('N'))) 'keyboard.json'
    return $inputFake.StatePath
}

try {
    Test-Case 'Input interop compiles; Win32 struct sizes and stick normalization are correct' {
        if (-not ('FortniteTweaks.InputNative' -as [type])) { Add-Type -Path (Join-Path $PSScriptRoot '../src/InputNative.cs') }
        Assert-True ([Runtime.InteropServices.Marshal]::SizeOf([type]'FortniteTweaks.InputNative+FilterKeys') -eq 24) 'FILTERKEYS struct has incorrect layout.'
        Assert-True ([Runtime.InteropServices.Marshal]::SizeOf([type]'FortniteTweaks.InputNative+GamepadState') -eq 16) 'XINPUT_STATE struct has incorrect layout.'
        Assert-True ([FortniteTweaks.InputNative]::StickPercent(0, 0) -eq 0) 'Neutral stick should report zero.'
        Assert-True ([FortniteTweaks.InputNative]::StickPercent(16384, 0) -eq 50) 'Half-range stick should report 50 percent.'
        Assert-True ([FortniteTweaks.InputNative]::StickPercent(-32768, -32768) -eq 100) 'Stick normalization should be capped at 100 percent.'
    }

    Test-Case 'Keyboard status and WhatIf never write native settings or backup files' {
        $path = New-InputFixture
        $state = Get-FortniteKeyboardState $path
        Assert-True ($state.FilterKeysEnabled -and $state.AcceptanceDelayMs -eq 400 -and -not $state.CanRestore) 'Wrong keyboard status.'
        Disable-FortniteKeyboardFilter $path -WhatIf
        Assert-True ($inputFake.Writes -eq 0 -and -not [IO.File]::Exists($path)) 'Preview changed keyboard or backup.'
    }

    Test-Case 'Disable removes only the filter enabled bit and preserves every timing and shortcut flag' {
        $path = New-InputFixture
        Assert-True ((Disable-FortniteKeyboardFilter $path).Status -eq 'Applied') 'Disable did not apply.'
        Assert-True ($inputFake.Current.Flags -eq 126 -and $inputFake.Current.Wait -eq 400 -and $inputFake.Current.Delay -eq 500 -and $inputFake.Current.Repeat -eq 30 -and $inputFake.Current.Bounce -eq 0) 'Unrelated keyboard settings changed.'
        $baseline = [IO.File]::ReadAllText($path)
        Assert-True (($baseline | ConvertFrom-Json).Original.Flags -eq 127) 'Original filter state not saved.'
        Assert-True ((Disable-FortniteKeyboardFilter $path).Status -eq 'Unchanged') 'Repeat disable was not a no-op.'
        Assert-True ($inputFake.Writes -eq 1 -and [IO.File]::ReadAllText($path) -ceq $baseline) 'Repeat disable replaced baseline or wrote settings.'
    }

    Test-Case 'Keyboard restore reads persisted state, supports WhatIf, and restores all original values' {
        $path = New-InputFixture
        Disable-FortniteKeyboardFilter $path | Out-Null
        Assert-True ((Get-FortniteKeyboardState $path).CanRestore) 'No keyboard restore offered.'
        Restore-FortniteKeyboardFilter $path -WhatIf
        Assert-True ($inputFake.Current.Flags -eq 126 -and [IO.File]::Exists($path)) 'Restore preview changed state.'
        Assert-True ((Restore-FortniteKeyboardFilter $path).Status -eq 'Restored') 'Keyboard restore did not run.'
        Assert-True ($inputFake.Current.Flags -eq 127 -and $inputFake.Current.Wait -eq 400 -and $inputFake.Current.Delay -eq 500 -and $inputFake.Current.Repeat -eq 30 -and $inputFake.Current.Bounce -eq 0) 'Original keyboard state not restored.'
        Assert-True (-not [IO.File]::Exists($path)) 'Completed restore left active baseline.'
        Assert-True ((Restore-FortniteKeyboardFilter $path).Status -eq 'Unchanged') 'Repeated restore was not a no-op.'
    }

    Test-Case 'Already disabled filter keys yield no invented speed tweak or restore baseline' {
        $path = New-InputFixture
        $inputFake.Current.Flags = 126
        Assert-True ((Disable-FortniteKeyboardFilter $path).Status -eq 'Unchanged') 'Already-disabled state was changed.'
        Assert-True ($inputFake.Writes -eq 0 -and -not [IO.File]::Exists($path)) 'Invented baseline for already-disabled filters.'
    }

    Test-Case 'Native keyboard write failure retains recovery baseline and does not report success' {
        $path = New-InputFixture
        $inputFake.Fail = $true
        Assert-Throws { Disable-FortniteKeyboardFilter $path } 'API denial'
        Assert-True ($inputFake.Current.Flags -eq 127 -and [IO.File]::Exists($path)) 'Write failure lost original state or recovery file.'
    }

    Test-Case 'An ignored native write cannot be reported as a successful keyboard tweak' {
        $path = New-InputFixture
        $inputFake.Ignore = $true
        Assert-Throws { Disable-FortniteKeyboardFilter $path } 'nicht uebernommen'
    }

    Test-Case 'Keyboard restore preserves externally changed accessibility settings' {
        $path = New-InputFixture
        Disable-FortniteKeyboardFilter $path | Out-Null
        $inputFake.Current.Wait = 999
        Assert-Throws { Restore-FortniteKeyboardFilter $path } 'ausserhalb'
        Assert-True ($inputFake.Writes -eq 1 -and $inputFake.Current.Wait -eq 999) 'External keyboard choice was overwritten.'
    }

    Test-Case 'Corrupted keyboard baseline cannot enable arbitrary filter settings' {
        $path = New-InputFixture
        [void][IO.Directory]::CreateDirectory((Split-Path $path))
        foreach ($invalid in @('{"Version":1}', '{"Version":1,"Original":{"Flags":0,"Wait":0,"Delay":0,"Repeat":0,"Bounce":0}}', '{"Version":1,"Original":{"Flags":127,"Wait":20001,"Delay":0,"Repeat":0,"Bounce":0}}')) {
            [IO.File]::WriteAllText($path, $invalid)
            Assert-Throws { Restore-FortniteKeyboardFilter $path } 'ungueltig'
        }
        Assert-True ($inputFake.Writes -eq 0) 'Corrupt baseline wrote native keyboard settings.'
    }

    Test-Case 'Concurrent keyboard changes prevent overwriting native settings' {
        $path = New-InputFixture
        $inputFake.Race = $true
        Assert-Throws { Disable-FortniteKeyboardFilter $path } 'zwischenzeitlich'
        Assert-True ($inputFake.Writes -eq 0 -and $inputFake.Current.Wait -eq 777) 'Concurrent keyboard change was overwritten.'
    }

    Test-Case 'Controller query returns read-only samples and accepts no connected controller' {
        & $inputModule { Set-Item Function:script:Read-NativeControllers { @() } }
        Assert-True (@(Get-FortniteControllerState).Count -eq 0) 'No-controller result should be empty.'
        & $inputModule { Set-Item Function:script:Read-NativeControllers { [pscustomobject]@{ Slot = 1; LeftStickPercent = 2.5; RightStickPercent = 0; LeftTriggerPercent = 0; RightTriggerPercent = 0 } } }
        $samples = @(Get-FortniteControllerState)
        Assert-True ($samples.Count -eq 1 -and $samples[0].LeftStickPercent -eq 2.5) 'Controller sample was not returned.'
    }
} finally {
    & $inputModule {
        param($read, $write, $controllers)
        Set-Item Function:script:Read-NativeKeyboard $read
        Set-Item Function:script:Write-NativeKeyboard $write
        Set-Item Function:script:Read-NativeControllers $controllers
    } $originalKeyboardRead $originalKeyboardWrite $originalControllerRead
}
