param([string]$NasmPath, [switch]$Test, [string]$DosBoxPath, [ValidateSet('normal','dynamic')][string]$Core='normal')
$ErrorActionPreference = 'Stop'
$sourceRoot = $PSScriptRoot
if (!$NasmPath) {
    $nasmCommand = Get-Command nasm -ErrorAction SilentlyContinue
    if ($nasmCommand) { $NasmPath = $nasmCommand.Source }
    else { $NasmPath = Join-Path $sourceRoot '../../../work/toolchain/nasm/nasm-3.01/nasm.exe' }
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
        & $NasmPath -f bin -Wall -w-reloc -Werror -DSELFTEST main.asm -o TEST.COM
        if ($LASTEXITCODE -ne 0) { throw 'Test assembly failed.' }
        if ((Get-Item TEST.COM).Length -ge 60000) { throw 'Test COM exceeds segment budget.' }
        if (!$DosBoxPath) {
            $dosBoxCommand = Get-Command dosbox-x -ErrorAction SilentlyContinue
            if ($dosBoxCommand) { $DosBoxPath = $dosBoxCommand.Source }
            else { throw 'DOSBox-X not found. Supply -DosBoxPath.' }
        }
        if (!(Test-Path -LiteralPath $DosBoxPath)) { throw 'Supply -DosBoxPath pointing to DOSBox-X to execute the test harness.' }
        $DosBoxPath = (Resolve-Path -LiteralPath $DosBoxPath).Path
        $testConfig = Join-Path $sourceRoot 'tests/generated-test.conf'
        @('[sdl]','output=surface','[dosbox]','machine=svga_s3','working directory option=noprompt','[cpu]',('core=' + $Core),'cputype=386','cycles=max','[mixer]','nosound=true','[ne2000]','ne2000=false','[autoexec]',('mount c "' + $sourceRoot + '"'),'c:','RUNTEST.BAT') | Set-Content -LiteralPath $testConfig
        foreach ($generatedFile in @('TESTLOG.TXT','STATUS.TXT')) {
            $generatedPath = Join-Path $sourceRoot $generatedFile
            if (Test-Path -LiteralPath $generatedPath) { Remove-Item -LiteralPath $generatedPath }
        }
        # No audio devices are needed by tests. RUNTEST.BAT exits the emulator after reporting status.
        $previousAudioDriver = $env:SDL_AUDIODRIVER
        try {
            $env:SDL_AUDIODRIVER = 'dummy'
            & $DosBoxPath -nopromptfolder -fastlaunch -conf $testConfig 2>&1 | Set-Content -LiteralPath (Join-Path $sourceRoot 'tests/dosbox-host.log')
        } finally { $env:SDL_AUDIODRIVER = $previousAudioDriver }
        if (!(Test-Path -LiteralPath 'STATUS.TXT') -or (Get-Content STATUS.TXT -Raw).Trim() -ne 'PASS') {
            if (Test-Path -LiteralPath 'TESTLOG.TXT') { Get-Content TESTLOG.TXT }
            throw 'DOSBox tests did not return PASS. Inspect tests/dosbox-host.log.'
        }
        Get-Content TESTLOG.TXT
        Copy-Item -LiteralPath (Join-Path $sourceRoot 'TESTLOG.TXT') -Destination (Join-Path $sourceRoot "tests/$Core-result.txt") -Force
    }
    'Built DOSBox real-mode Food Invaders successfully.'
} finally { Pop-Location }
