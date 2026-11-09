param([string]$DosBoxPath)
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$gameRoot = Join-Path $repoRoot 'build\standard'
$configPath = Join-Path $repoRoot 'packaging\dosbox\desktop.conf'
& (Join-Path $PSScriptRoot 'build.ps1') -Profile standard
if ($LASTEXITCODE -ne 0) { throw 'Game assembly failed.' }
if (!$DosBoxPath) {
    $dosBoxCommand = Get-Command dosbox-x -ErrorAction SilentlyContinue
    if ($dosBoxCommand) { $DosBoxPath = $dosBoxCommand.Source }
    else { throw 'DOSBox-X not found. Supply -DosBoxPath with its executable path.' }
}
if (!(Test-Path -LiteralPath $DosBoxPath)) { throw 'DOSBox-X not found. Supply -DosBoxPath with its executable path.' }
if (!(Test-Path -LiteralPath (Join-Path $gameRoot 'INVADERS.COM'))) { throw 'Build INVADERS.COM first.' }
$DosBoxPath = (Resolve-Path -LiteralPath $DosBoxPath).Path
Push-Location $gameRoot
try {
    $mountCommand = 'mount c "' + $gameRoot + '"'
    & $DosBoxPath -nopromptfolder -fastlaunch -conf $configPath -noautoexec -c $mountCommand -c 'c:' -c 'INVADERS.COM' -c 'exit'
    if ($LASTEXITCODE -ne 0) { throw "DOSBox-X exited with code $LASTEXITCODE." }
}
finally { Pop-Location }
