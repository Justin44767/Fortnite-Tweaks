# Dot-sourced by Run-Tests.ps1: all powercfg calls use a local fake, never the host's plan.
Import-Module (Join-Path $PSScriptRoot '../src/WindowsTweaks.psm1') -Force
$powerModule = Get-Module WindowsTweaks
$originalPowerCommand = & $powerModule { (Get-Command Invoke-FortnitePowerCfg).ScriptBlock }
$powerFake = [pscustomobject]@{
    Active = '381b4222-f694-41f0-9685-ff5bb260df2e'
    High = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
    Available = $true; Fail = $false; Ignore = $false; Writes = 0; StatePath = ''
}
$fakePowerCommand = {
    param([string[]]$Arguments)
    switch ($Arguments[0]) {
        '/getactivescheme' { return "Localized active plan: $($powerFake.Active)" }
        '/list' {
            $text = '381b4222-f694-41f0-9685-ff5bb260df2e'
            if ($powerFake.Available) { $text += ' ' + $powerFake.High }
            return $text
        }
        '/setactive' {
            if (-not [IO.File]::Exists($powerFake.StatePath)) { throw 'Baseline was not saved before changing the plan.' }
            if ($powerFake.Fail) { throw 'Simulated powercfg access denial' }
            $powerFake.Writes++
            if (-not $powerFake.Ignore) { $powerFake.Active = $Arguments[1] }
            return ''
        }
        default { throw 'Unexpected powercfg operation.' }
    }
}.GetNewClosure()
& $powerModule { param($body) Set-Item Function:script:Invoke-FortnitePowerCfg $body } $fakePowerCommand

function New-PowerFixture {
    $directory = Join-Path $script:testRoot ([guid]::NewGuid().ToString('N'))
    $powerFake.Active = '381b4222-f694-41f0-9685-ff5bb260df2e'
    $powerFake.Available = $true; $powerFake.Fail = $false; $powerFake.Ignore = $false; $powerFake.Writes = 0
    $powerFake.StatePath = Join-Path $directory 'power-plan.json'
    return $powerFake.StatePath
}

try {
    Test-Case 'Power plan queries and WhatIf create no state or power changes' {
        $path = New-PowerFixture
        $state = Get-FortnitePowerPlanState $path
        Assert-True ($state.HighPerformanceAvailable -and -not $state.CanRestore) 'Initial plan state incorrect.'
        Enable-FortniteHighPerformance $path -WhatIf
        Assert-True ($powerFake.Writes -eq 0 -and -not [IO.File]::Exists($path)) 'Power preview changed state.'
    }

    Test-Case 'Power enable saves baseline before change; repeat enable preserves it' {
        $path = New-PowerFixture
        $original = $powerFake.Active
        Assert-True ((Enable-FortniteHighPerformance $path).Status -eq 'Applied') 'Power enable did not run.'
        $saved = [IO.File]::ReadAllText($path)
        Assert-True (($saved | ConvertFrom-Json).OriginalSchemeId -eq $original) 'Original power plan was not saved.'
        Assert-True ((Enable-FortniteHighPerformance $path).Status -eq 'Unchanged') 'Repeated enable was not a no-op.'
        Assert-True ([IO.File]::ReadAllText($path) -ceq $saved) 'Repeated enable overwrote baseline.'
        Assert-True ((Get-FortnitePowerPlanState $path).CanRestore) 'Restore was not offered.'
        Restore-FortnitePowerPlan $path -WhatIf
        Assert-True ($powerFake.Active -eq $powerFake.High -and [IO.File]::Exists($path)) 'Restore preview changed state.'
        Restore-FortnitePowerPlan $path | Out-Null
        Assert-True ($powerFake.Active -eq $original -and -not [IO.File]::Exists($path)) 'Original plan not restored.'
        Assert-True ((Restore-FortnitePowerPlan $path).Status -eq 'Unchanged') 'Repeat restore was not a no-op.'
    }

    Test-Case 'No fake restore baseline when high performance was already active' {
        $path = New-PowerFixture
        $powerFake.Active = $powerFake.High
        Enable-FortniteHighPerformance $path | Out-Null
        Assert-True (-not [IO.File]::Exists($path) -and $powerFake.Writes -eq 0) 'Invented original scheme or changed the plan.'
    }

    Test-Case 'Unavailable high-performance plan is not created or activated' {
        $path = New-PowerFixture
        $powerFake.Available = $false
        Assert-Throws { Enable-FortniteHighPerformance $path } 'nicht an'
        Assert-True ($powerFake.Writes -eq 0 -and -not [IO.File]::Exists($path)) 'Unavailable plan caused writes.'
    }

    Test-Case 'Power command denial preserves current plan and recovery baseline' {
        $path = New-PowerFixture
        $original = $powerFake.Active
        $powerFake.Fail = $true
        Assert-Throws { Enable-FortniteHighPerformance $path } 'access denial'
        Assert-True ($powerFake.Active -eq $original -and [IO.File]::Exists($path)) 'Failure lost original plan or backup.'
    }

    Test-Case 'Power plan must actually activate before reporting success' {
        $path = New-PowerFixture
        $powerFake.Ignore = $true
        Assert-Throws { Enable-FortniteHighPerformance $path } 'nicht aktiviert'
    }

    Test-Case 'Restore cannot overwrite an externally selected third power plan' {
        $path = New-PowerFixture
        Enable-FortniteHighPerformance $path | Out-Null
        $powerFake.Active = 'a1841308-3541-4fab-bc81-f71556f20b4a'
        $beforeWrites = $powerFake.Writes
        Assert-Throws { Restore-FortnitePowerPlan $path } 'ausserhalb'
        Assert-True ($powerFake.Writes -eq $beforeWrites -and [IO.File]::Exists($path)) 'External power choice was overwritten.'
    }

    Test-Case 'Corrupt power backup is rejected without changing the plan' {
        $path = New-PowerFixture
        [void][IO.Directory]::CreateDirectory((Split-Path $path))
        [IO.File]::WriteAllText($path, '{"Version":1,"OriginalSchemeId":"not-a-guid"}')
        Assert-Throws { Restore-FortnitePowerPlan $path } 'ungueltig'
        Assert-True ($powerFake.Writes -eq 0) 'Corrupt backup caused a power change.'
    }
} finally {
    & $powerModule { param($body) Set-Item Function:script:Invoke-FortnitePowerCfg $body } $originalPowerCommand
}
