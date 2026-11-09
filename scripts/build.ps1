param(
    [string]$NasmPath,
    [string]$DosBoxPath,
    [switch]$Test,
    [ValidateSet('normal', 'dynamic', 'both')][string]$Core = 'both',
    [ValidateSet('standard', 'termux')][string]$Profile = 'standard'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sourceRoot = Join-Path $repoRoot 'src'
$testsRoot = Join-Path $repoRoot 'tests'
$buildRoot = Join-Path $repoRoot "build\$Profile"
$testBuildRoot = Join-Path $repoRoot 'build\tests'

if (!$NasmPath) {
    $nasmCommand = Get-Command nasm -ErrorAction SilentlyContinue
    if ($nasmCommand) { $NasmPath = $nasmCommand.Source }
    else { throw 'NASM not found. Add nasm to PATH or pass -NasmPath.' }
}
if (!(Test-Path -LiteralPath $NasmPath)) { throw 'NASM not found at the supplied path.' }
$NasmPath = (Resolve-Path -LiteralPath $NasmPath).Path
if (!(Test-Path -LiteralPath $sourceRoot)) { throw 'The src directory is missing.' }

New-Item -ItemType Directory -Force -Path $buildRoot | Out-Null
function Invoke-Nasm([string[]]$NasmArgs, [string]$Message) {
    & $NasmPath @NasmArgs
    if ($LASTEXITCODE -ne 0) { throw $Message }
}
function Assert-ComSize([string]$Path) {
    $size = (Get-Item -LiteralPath $Path).Length
    if ($size -ge 60000) { throw "$([IO.Path]::GetFileName($Path)) exceeds the 60,000-byte DOS segment budget ($size bytes)." }
}

$includeRoot = $repoRoot.Replace('\', '/') + '/'
$includeSource = $sourceRoot.Replace('\', '/') + '/'
$includeTests = $testsRoot.Replace('\', '/') + '/'
$baseArgs = @("-I$includeRoot", "-I$includeSource", "-I$includeTests", '-f', 'bin', '-Wall', '-w-reloc', '-Werror')
$profileArgs = @()
if ($Profile -eq 'termux') { $profileArgs += '-DTERMUX_FAST' }
Push-Location $sourceRoot
try { Invoke-Nasm ($baseArgs + $profileArgs + @('main.asm', '-o', (Join-Path $buildRoot 'INVADERS.COM'))) 'Game assembly failed.' }
finally { Pop-Location }
Assert-ComSize (Join-Path $buildRoot 'INVADERS.COM')

if ($Test) {
    New-Item -ItemType Directory -Force -Path $testBuildRoot | Out-Null
    Push-Location $sourceRoot
    try {
        Invoke-Nasm ($baseArgs + @('-DCOMPACT_TEST_DISPLAY', '-DSELFTEST', (Join-Path $sourceRoot 'main.asm'), '-o', (Join-Path $testBuildRoot 'TEST.COM'))) 'Core test assembly failed.'
        Invoke-Nasm ($baseArgs + @('-DCOMPACT_TEST_DISPLAY', (Join-Path $testsRoot 'player-bullet.asm'), '-o', (Join-Path $testBuildRoot 'PBTEST.COM'))) 'Player test assembly failed.'
        Invoke-Nasm ($baseArgs + @('-DCOMPACT_TEST_DISPLAY', (Join-Path $testsRoot 'collision.asm'), '-o', (Join-Path $testBuildRoot 'COLLTEST.COM'))) 'Collision test assembly failed.'
        Invoke-Nasm ($baseArgs + @('-DCOMPACT_TEST_DISPLAY', '-DSELFTEST', '-DVISUAL_TEST', (Join-Path $sourceRoot 'main.asm'), '-o', (Join-Path $testBuildRoot 'WINTEST.COM'))) 'Victory test assembly failed.'
    } finally { Pop-Location }

    foreach ($name in @('TEST.COM', 'PBTEST.COM', 'COLLTEST.COM', 'WINTEST.COM')) {
        Assert-ComSize (Join-Path $testBuildRoot $name)
    }
    Copy-Item -LiteralPath (Join-Path $testsRoot 'RUNTEST.BAT') -Destination (Join-Path $testBuildRoot 'RUNTEST.BAT') -Force
    if (!$DosBoxPath) {
        $dosBoxCommand = Get-Command dosbox-x -ErrorAction SilentlyContinue
        if ($dosBoxCommand) { $DosBoxPath = $dosBoxCommand.Source }
        else { throw 'DOSBox-X not found. Pass -DosBoxPath to run the suites.' }
    }
    if (!(Test-Path -LiteralPath $DosBoxPath)) { throw 'DOSBox-X not found at the supplied path.' }
    $DosBoxPath = (Resolve-Path -LiteralPath $DosBoxPath).Path
    $cores = if ($Core -eq 'both') { @('normal', 'dynamic') } else { @($Core) }
    foreach ($cpuCore in $cores) {
        $testConfig = Join-Path $testBuildRoot "dosbox-$cpuCore.conf"
        @('[sdl]', 'output=surface', '[dosbox]', 'machine=svga_s3', 'working directory option=noprompt', '[cpu]', ('core=' + $cpuCore), 'cputype=386', 'cycles=max', '[mixer]', 'nosound=true', '[ne2000]', 'ne2000=false', '[autoexec]', ('mount c "' + $testBuildRoot + '"'), 'c:', 'RUNTEST.BAT') | Set-Content -LiteralPath $testConfig
        foreach ($name in @('TESTLOG.TXT', 'PBLOG.TXT', 'COLLLOG.TXT', 'STATUS.TXT')) {
            $path = Join-Path $testBuildRoot $name
            if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path }
        }
        $oldAudio = $env:SDL_AUDIODRIVER
        $oldPreference = $ErrorActionPreference
        try {
            $env:SDL_AUDIODRIVER = 'dummy'
            $ErrorActionPreference = 'Continue'
            & $DosBoxPath -silent -nopromptfolder -fastlaunch -conf $testConfig 2>&1 | Set-Content -LiteralPath (Join-Path $testBuildRoot "dosbox-$cpuCore.log")
        } finally {
            $ErrorActionPreference = $oldPreference
            $env:SDL_AUDIODRIVER = $oldAudio
        }
        if (!(Test-Path -LiteralPath (Join-Path $testBuildRoot 'STATUS.TXT')) -or (Get-Content (Join-Path $testBuildRoot 'STATUS.TXT') -Raw).Trim() -ne 'PASS') {
            foreach ($name in @('TESTLOG.TXT', 'PBLOG.TXT', 'COLLLOG.TXT')) {
                $path = Join-Path $testBuildRoot $name
                if (Test-Path -LiteralPath $path) { Get-Content $path }
            }
            throw "DOSBox-X $cpuCore test run failed. Inspect build/tests/dosbox-$cpuCore.log."
        }
        foreach ($name in @('TESTLOG.TXT', 'PBLOG.TXT', 'COLLLOG.TXT')) {
            $path = Join-Path $testBuildRoot $name
            $content = Get-Content -LiteralPath $path -Raw
            if ($content -notmatch '(?m)^PASS' -or $content -match '(?m)^FAIL') { throw "$name did not report PASS on the $cpuCore core." }
        }
        $version = 'DOSBox-X'
        $versionMatch = Select-String -LiteralPath (Join-Path $testBuildRoot "dosbox-$cpuCore.log") -Pattern 'DOSBox-X version ([^ ]+)' | Select-Object -First 1
        if ($versionMatch) { $version = 'DOSBox-X ' + $versionMatch.Matches[0].Groups[1].Value }
        $resultPath = Join-Path $testBuildRoot "integrated-$cpuCore-result.txt"
        ($version + ', 386 CPU, ' + $cpuCore + ' core') | Set-Content -LiteralPath $resultPath
        Get-Content @((Join-Path $testBuildRoot 'TESTLOG.TXT'), (Join-Path $testBuildRoot 'PBLOG.TXT'), (Join-Path $testBuildRoot 'COLLLOG.TXT')) | Add-Content -LiteralPath $resultPath
        Get-Content $resultPath
    }
}

Write-Output "Built Food Invaders ($Profile) at $buildRoot."
