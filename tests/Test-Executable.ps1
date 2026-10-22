#Requires -Version 5.1
[CmdletBinding()]
param([string]$ExecutablePath)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repository = Split-Path $PSScriptRoot -Parent
if (-not $ExecutablePath) { $ExecutablePath = Join-Path $repository 'dist/Fortnite-Tweaks-Launcher.exe' }
$ExecutablePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ExecutablePath)
$expectedHash = ([IO.File]::ReadAllText($ExecutablePath + '.sha256').Trim() -split '\s+')[0]
if ((Get-FileHash -LiteralPath $ExecutablePath -Algorithm SHA256).Hash.ToLowerInvariant() -cne $expectedHash) {
    throw 'Executable checksum mismatch.'
}
$assembly = [Reflection.Assembly]::Load([IO.File]::ReadAllBytes($ExecutablePath))
$payload = [ordered]@{
    'FortniteTweaks.EntryPoint' = 'Launcher.ps1'
    'FortniteTweaks.Interface' = 'src/Launcher.psm1'
    'FortniteTweaks.Layout' = 'src/Launcher.xaml'
    'FortniteTweaks.Settings' = 'src/FortniteTweaks.psm1'
}
if ($assembly.GetManifestResourceNames().Count -ne $payload.Count) { throw 'Wrong number of embedded payload files.' }
foreach ($name in $payload.Keys) {
    $stream = $assembly.GetManifestResourceStream($name)
    if ($null -eq $stream) { throw "Missing embedded payload: $name" }
    $memory = New-Object IO.MemoryStream
    try {
        $stream.CopyTo($memory)
        $original = [IO.File]::ReadAllBytes((Join-Path $repository $payload[$name]))
        if ([Convert]::ToBase64String($memory.ToArray()) -cne [Convert]::ToBase64String($original)) {
            throw "Embedded payload is stale: $name. Rebuild the executable."
        }
    } finally { $stream.Dispose(); $memory.Dispose() }
}
$kind = [Reflection.PortableExecutableKinds]::NotAPortableExecutableImage
$machine = [Reflection.ImageFileMachine]::I386
$assembly.ManifestModule.GetPEKind([ref]$kind, [ref]$machine)
if (($kind -band [Reflection.PortableExecutableKinds]::ILOnly) -eq 0 -or ($kind -band [Reflection.PortableExecutableKinds]::Required32Bit) -ne 0) {
    throw 'Executable should be managed AnyCPU without a 32-bit runtime requirement.'
}
Write-Host 'PASS Executable SHA256, AnyCPU flags, and all 4 embedded files match source.'

if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
    $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = $ExecutablePath
    $start.Arguments = '--verify-payload'
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardError = $true
    $start.RedirectStandardOutput = $true
    $process = New-Object Diagnostics.Process
    try {
        $process.StartInfo = $start
        [void]$process.Start()
        if (-not $process.WaitForExit(30000)) { $process.Kill(); throw 'Executable verification timed out.' }
        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()
        if ($process.ExitCode -ne 0 -or $stdout -notmatch 'Payload verified: 4 files') {
            throw "Executable verification failed (exit $($process.ExitCode)): $stdout $stderr"
        }
        Write-Host 'PASS Windows executable starts, extracts and verifies its payload, and locates PowerShell.'
    } finally { $process.Dispose() }
} else {
    Write-Host 'SKIP Running the executable (requires Windows and .NET Framework 4.8).'
}
