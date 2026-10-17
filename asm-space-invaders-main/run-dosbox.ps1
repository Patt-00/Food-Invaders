param([string]$DosBoxPath)
$ErrorActionPreference = 'Stop'
if (!$DosBoxPath) {
    $dosBoxCommand = Get-Command dosbox-x -ErrorAction SilentlyContinue
    if ($dosBoxCommand) { $DosBoxPath = $dosBoxCommand.Source }
    else { throw 'DOSBox-X not found. Supply -DosBoxPath with its executable path.' }
}
if (!(Test-Path -LiteralPath $DosBoxPath)) { throw 'DOSBox-X not found. Supply -DosBoxPath with its executable path.' }
if (!(Test-Path -LiteralPath (Join-Path $PSScriptRoot 'INVADERS.COM'))) { throw 'Build INVADERS.COM first.' }
$DosBoxPath = (Resolve-Path -LiteralPath $DosBoxPath).Path
Push-Location $PSScriptRoot
try { & $DosBoxPath -nopromptfolder -fastlaunch -conf dosbox.conf }
finally { Pop-Location }
