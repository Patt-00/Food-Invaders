param([string]$NasmPath, [switch]$Test, [string]$DosBoxPath, [ValidateSet('normal','dynamic')][string]$Core='normal')
$ErrorActionPreference = 'Stop'
$sourceRoot = $PSScriptRoot
if (!$NasmPath) {
    $nasmCommand = Get-Command nasm -ErrorAction SilentlyContinue
    if ($nasmCommand) { $NasmPath = $nasmCommand.Source }
    else { throw 'NASM not found. Add nasm to PATH or supply -NasmPath with its executable.' }
}
if (!(Test-Path -LiteralPath $NasmPath)) { throw 'NASM not found. Supply -NasmPath with your NASM executable.' }
$NasmPath = (Resolve-Path -LiteralPath $NasmPath).Path
Push-Location $sourceRoot
try {
    # -w-reloc excludes NASM 3 opt-in relocation diagnostics for ordinary
    # resolved COM addresses; other assembler warnings remain build errors.
    & $NasmPath -f bin -Wall -w-reloc -Werror main.asm -o INVADERS.COM
    if ($LASTEXITCODE -ne 0) { throw 'Game assembly failed.' }
    if ((Get-Item INVADERS.COM).Length -ge 60000) { throw 'COM exceeds the code/data budget reserved below the stack.' }
    if ($Test) {
        & $NasmPath -f bin -Wall -w-reloc -Werror -DCOMPACT_TEST_DISPLAY -DSELFTEST main.asm -o TEST.COM
        if ($LASTEXITCODE -ne 0) { throw 'Test assembly failed.' }
        & $NasmPath -f bin -Wall -w-reloc -Werror -DCOMPACT_TEST_DISPLAY tests/player-bullet.asm -o PBTEST.COM
        if ($LASTEXITCODE -ne 0) { throw 'Player and weapon test assembly failed.' }
        & $NasmPath -f bin -Wall -w-reloc -Werror -DCOMPACT_TEST_DISPLAY tests/collision.asm -o COLLTEST.COM
        if ($LASTEXITCODE -ne 0) { throw 'Collision test assembly failed.' }
        & $NasmPath -f bin -Wall -w-reloc -Werror -DCOMPACT_TEST_DISPLAY -DSELFTEST -DVISUAL_TEST main.asm -o WINTEST.COM
        if ($LASTEXITCODE -ne 0) { throw 'Visual test assembly failed.' }
        foreach ($testBinary in @('TEST.COM', 'PBTEST.COM', 'COLLTEST.COM', 'WINTEST.COM')) {
            if ((Get-Item $testBinary).Length -ge 60000) { throw "$testBinary exceeds segment budget." }
        }
        if (!$DosBoxPath) {
            $dosBoxCommand = Get-Command dosbox-x -ErrorAction SilentlyContinue
            if ($dosBoxCommand) { $DosBoxPath = $dosBoxCommand.Source }
            else { throw 'DOSBox-X not found. Supply -DosBoxPath.' }
        }
        if (!(Test-Path -LiteralPath $DosBoxPath)) { throw 'Supply -DosBoxPath pointing to DOSBox-X to execute the test harness.' }
        $DosBoxPath = (Resolve-Path -LiteralPath $DosBoxPath).Path
        $testConfig = Join-Path $sourceRoot 'tests/generated-test.conf'
        @('[sdl]','output=surface','[dosbox]','machine=svga_s3','working directory option=noprompt','[cpu]',('core=' + $Core),'cputype=386','cycles=max','[mixer]','nosound=true','[ne2000]','ne2000=false','[autoexec]',('mount c "' + $sourceRoot + '"'),'c:','RUNTEST.BAT') | Set-Content -LiteralPath $testConfig
        foreach ($generatedFile in @('TESTLOG.TXT','PBLOG.TXT','COLLLOG.TXT','STATUS.TXT')) {
            $generatedPath = Join-Path $sourceRoot $generatedFile
            if (Test-Path -LiteralPath $generatedPath) { Remove-Item -LiteralPath $generatedPath }
        }
        # Tests use redirected DOS output, so avoid opening an SDL window/audio device.
        # RUNTEST.BAT exits the emulator after reporting status.
        $previousAudioDriver = $env:SDL_AUDIODRIVER
        try {
            $env:SDL_AUDIODRIVER = 'dummy'
            & $DosBoxPath -silent -nopromptfolder -fastlaunch -conf $testConfig 2>&1 | Set-Content -LiteralPath (Join-Path $sourceRoot 'tests/dosbox-host.log')
        } finally { $env:SDL_AUDIODRIVER = $previousAudioDriver }
        if (!(Test-Path -LiteralPath 'STATUS.TXT') -or (Get-Content STATUS.TXT -Raw).Trim() -ne 'PASS') {
            foreach ($testLog in @('TESTLOG.TXT','PBLOG.TXT','COLLLOG.TXT')) {
                if (Test-Path -LiteralPath $testLog) { Get-Content $testLog }
            }
            throw 'DOSBox tests did not return PASS. Inspect tests/dosbox-host.log.'
        }
        $resultPath = Join-Path $sourceRoot "tests/integrated-$Core-result.txt"
        $testLogs = @('TESTLOG.TXT','PBLOG.TXT','COLLLOG.TXT')
        foreach ($testLog in $testLogs) {
            if (!(Test-Path -LiteralPath $testLog) -or !(Select-String -LiteralPath $testLog -Pattern '^PASS' -Quiet) -or (Select-String -LiteralPath $testLog -Pattern '^FAIL' -Quiet)) {
                throw "DOSBox test output is missing a PASS record: $testLog"
            }
        }
        $versionMatch = Select-String -LiteralPath (Join-Path $sourceRoot 'tests/dosbox-host.log') -Pattern 'DOSBox-X version ([^ ]+)' | Select-Object -First 1
        $version = if ($versionMatch) { $versionMatch.Matches[0].Groups[1].Value } else { 'unknown version' }
        "DOSBox-X $version, 386 CPU, $Core core" | Set-Content -LiteralPath $resultPath
        Get-Content $testLogs | Add-Content -LiteralPath $resultPath
        Get-Content -LiteralPath $resultPath
    }
    'Built DOSBox real-mode Food Invaders successfully.'
} finally { Pop-Location }
