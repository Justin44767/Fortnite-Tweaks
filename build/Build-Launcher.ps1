#Requires -Version 5.1
[CmdletBinding()]
param([string]$OutputDirectory, [string]$ReferenceDirectory)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repository = Split-Path $PSScriptRoot -Parent
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $repository 'dist' }
$OutputDirectory = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDirectory)
[void][IO.Directory]::CreateDirectory($OutputDirectory)
$output = Join-Path $OutputDirectory 'Fortnite-Tweaks-Launcher.exe'
$source = Join-Path $PSScriptRoot 'Bootstrap.cs'
$manifest = Join-Path $PSScriptRoot 'Launcher.manifest'
$payload = [ordered]@{
    'FortniteTweaks.EntryPoint' = (Join-Path $repository 'Launcher.ps1')
    'FortniteTweaks.Interface' = (Join-Path $repository 'src/Launcher.psm1')
    'FortniteTweaks.Layout' = (Join-Path $repository 'src/Launcher.xaml')
    'FortniteTweaks.Settings' = (Join-Path $repository 'src/FortniteTweaks.psm1')
}
foreach ($path in $payload.Values) {
    if (-not [IO.File]::Exists($path)) { throw "Payload file missing: $path" }
}

if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
    $compiler = Join-Path $env:SystemRoot 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
    if (-not [IO.File]::Exists($compiler)) { $compiler = Join-Path $env:SystemRoot 'Microsoft.NET/Framework/v4.0.30319/csc.exe' }
    if (-not [IO.File]::Exists($compiler)) { throw '.NET Framework C# compiler not found.' }
    $arguments = @('/nologo', '/target:winexe', '/platform:anycpu', '/optimize+', "/out:$output", "/win32manifest:$manifest", '/reference:System.Windows.Forms.dll', '/reference:System.Core.dll')
    foreach ($name in $payload.Keys) { $arguments += "/resource:$($payload[$name]),$name" }
    $arguments += $source
    & $compiler @arguments
    if ($LASTEXITCODE -ne 0) { throw "C# compiler failed with exit code $LASTEXITCODE." }
} else {
    # PowerShell 7 bundles Roslyn. Framework reference assemblies are supplied separately.
    if (-not $ReferenceDirectory) { throw 'On Linux, provide -ReferenceDirectory with the .NET Framework 4.8 reference assemblies.' }
    Add-Type -Path (Join-Path $PSHOME 'Microsoft.CodeAnalysis.dll')
    Add-Type -Path (Join-Path $PSHOME 'Microsoft.CodeAnalysis.CSharp.dll')
    $references = New-Object 'Collections.Generic.List[Microsoft.CodeAnalysis.MetadataReference]'
    foreach ($name in @('mscorlib.dll', 'System.dll', 'System.Core.dll', 'System.Windows.Forms.dll', 'System.Drawing.dll')) {
        $path = Join-Path $ReferenceDirectory $name
        if (-not [IO.File]::Exists($path)) { throw "Reference assembly missing: $path" }
        $references.Add([Microsoft.CodeAnalysis.MetadataReference]::CreateFromFile($path))
    }
    $parseOptions = [Microsoft.CodeAnalysis.CSharp.CSharpParseOptions]::Default.WithLanguageVersion([Microsoft.CodeAnalysis.CSharp.LanguageVersion]::CSharp5)
    $tree = [Microsoft.CodeAnalysis.CSharp.CSharpSyntaxTree]::ParseText([IO.File]::ReadAllText($source), $parseOptions)
    $options = [Microsoft.CodeAnalysis.CSharp.CSharpCompilationOptions]::new([Microsoft.CodeAnalysis.OutputKind]::WindowsApplication)
    $options = $options.WithOptimizationLevel([Microsoft.CodeAnalysis.OptimizationLevel]::Release)
    $options = $options.WithPlatform([Microsoft.CodeAnalysis.Platform]::AnyCpu)
    $options = $options.WithDeterministic($true)
    $compilation = [Microsoft.CodeAnalysis.CSharp.CSharpCompilation]::Create('Fortnite-Tweaks-Launcher', [Microsoft.CodeAnalysis.SyntaxTree[]]@($tree), $references, $options)
    $resources = New-Object 'Collections.Generic.List[Microsoft.CodeAnalysis.ResourceDescription]'
    foreach ($name in $payload.Keys) {
        $resourcePath = $payload[$name]
        $provider = [Func[IO.Stream]]{ [IO.File]::OpenRead($resourcePath) }.GetNewClosure()
        $resources.Add([Microsoft.CodeAnalysis.ResourceDescription]::new($name, $provider, $true))
    }
    $peStream = [IO.File]::Create($output)
    $manifestStream = [IO.File]::OpenRead($manifest)
    $nativeResources = $null
    try {
        $nativeResources = $compilation.CreateDefaultWin32Resources($true, $false, $manifestStream, $null)
        $result = $compilation.Emit($peStream, $null, $null, $nativeResources, $resources)
        if (-not $result.Success) { throw (($result.Diagnostics | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine) }
    } finally {
        if ($null -ne $nativeResources) { $nativeResources.Dispose() }
        $manifestStream.Dispose()
        $peStream.Dispose()
    }
}

$hash = (Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash.ToLowerInvariant()
[IO.File]::WriteAllText($output + '.sha256', ($hash + ' *' + [IO.Path]::GetFileName($output) + "`n"), [Text.Encoding]::ASCII)
Write-Host "Built: $output"
Write-Host "SHA256: $hash"
