param([string]$DosBoxPath)
$ErrorActionPreference = 'Stop'
if (!$DosBoxPath) {
    $dosBoxCommand = Get-Command dosbox -ErrorAction SilentlyContinue
    if ($dosBoxCommand) { $DosBoxPath = $dosBoxCommand.Source }
    else { $DosBoxPath = Join-Path $PSScriptRoot '../../../work/toolchain/dosbox/dosbox-staging-v0.82.2/dosbox.exe' }
}
if (!(Test-Path -LiteralPath $DosBoxPath)) { throw 'DOSBox not found. Supply -DosBoxPath with its executable path.' }
if (!(Test-Path -LiteralPath (Join-Path $PSScriptRoot 'INVADERS.COM'))) { throw 'Build INVADERS.COM first.' }
$DosBoxPath = (Resolve-Path -LiteralPath $DosBoxPath).Path
Push-Location $PSScriptRoot
try { & $DosBoxPath -conf dosbox.conf }
finally { Pop-Location }
