param(
    [string]$Version = '1.0.0',
    [string]$NasmPath,
    [Parameter(Mandatory = $true)][string]$DosBoxArchive,
    [Parameter(Mandatory = $true)][string]$DosBoxSourceArchive,
    [string]$IsccPath,
    [string]$OutputDir = (Join-Path $PSScriptRoot '..\dist')
)

$ErrorActionPreference = 'Stop'
if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw 'Version must use MAJOR.MINOR.PATCH format.' }
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$DosBoxArchive = (Resolve-Path -LiteralPath $DosBoxArchive).Path
$DosBoxSourceArchive = (Resolve-Path -LiteralPath $DosBoxSourceArchive).Path
$expectedDosBoxHash = '3c50915e63aefe35777d65ebb4391a06b4a2c2342e4c75cbee6bbda4c6916e33'
$expectedSourceHash = 'df023a6c0e4a139dcbd60befff5947e0db2cc68e4e79db463670f581a4044ed4'
if ((Get-FileHash -LiteralPath $DosBoxArchive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedDosBoxHash) {
    throw 'DOSBox-X Windows archive does not match the pinned 2026.10.01 asset.'
}
if ((Get-FileHash -LiteralPath $DosBoxSourceArchive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedSourceHash) {
    throw 'DOSBox-X source archive does not match the pinned 2026.10.01 source.'
}
$OutputDir = [IO.Path]::GetFullPath($OutputDir)
$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ('food-invaders-' + [guid]::NewGuid())
$stageRoot = Join-Path $temporaryRoot 'stage'
$emulatorExtract = Join-Path $temporaryRoot 'upstream'
New-Item -ItemType Directory -Force -Path $stageRoot, $emulatorExtract, $OutputDir | Out-Null
try {
    & (Join-Path $PSScriptRoot 'build.ps1') -Profile standard -NasmPath $NasmPath

    Expand-Archive -LiteralPath $DosBoxArchive -DestinationPath $emulatorExtract -Force
    $emulatorSource = Join-Path $emulatorExtract 'bin\x64\Release'
    if (!(Test-Path -LiteralPath (Join-Path $emulatorSource 'dosbox-x.exe'))) {
        throw 'The pinned DOSBox-X archive did not contain bin/x64/Release/dosbox-x.exe.'
    }

    $gameDir = Join-Path $stageRoot 'game'
    $emulatorDir = Join-Path $stageRoot 'DOSBox-X'
    $configDir = Join-Path $stageRoot 'config'
    $licenseDir = Join-Path $stageRoot 'licenses'
    $thirdPartyDir = Join-Path $stageRoot 'third-party'
    New-Item -ItemType Directory -Force -Path $gameDir, $emulatorDir, $configDir, $licenseDir, $thirdPartyDir | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot 'build\standard\INVADERS.COM') -Destination $gameDir
    Copy-Item -Path (Join-Path $emulatorSource '*') -Destination $emulatorDir -Recurse -Force
    Copy-Item -LiteralPath (Join-Path $repoRoot 'packaging\dosbox\desktop.conf') -Destination $configDir
    Copy-Item -LiteralPath (Join-Path $repoRoot 'packaging\windows\run-food-invaders.cmd') -Destination $stageRoot
    Copy-Item -LiteralPath (Join-Path $repoRoot 'LICENSE') -Destination $licenseDir
    Copy-Item -LiteralPath (Join-Path $repoRoot 'THIRD-PARTY-NOTICES.md') -Destination $licenseDir
    Copy-Item -LiteralPath (Join-Path $emulatorExtract 'COPYING') -Destination (Join-Path $licenseDir 'DOSBox-X-COPYING')
    Copy-Item -LiteralPath $DosBoxSourceArchive -Destination (Join-Path $thirdPartyDir 'dosbox-x-source.tar.gz')
    $sourceHash = (Get-FileHash -LiteralPath $DosBoxSourceArchive -Algorithm SHA256).Hash.ToLowerInvariant()
    @"
DOSBox-X version: 2026.10.01
Tag: dosbox-x-v2026.10.01
Commit: b6abbd5980a885f5f310a4088c59a8688d1b116c
Source: https://github.com/joncampbell123/dosbox-x/releases/tag/dosbox-x-v2026.10.01
Included archive: third-party/dosbox-x-source.tar.gz
SHA-256: $sourceHash
License: GNU GPL version 2 (see licenses/DOSBox-X-COPYING)
"@ | Set-Content -LiteralPath (Join-Path $thirdPartyDir 'DOSBox-X-SOURCE.txt') -Encoding utf8

    if (!$IsccPath) {
        $isccCommand = Get-Command ISCC.exe -ErrorAction SilentlyContinue
        if (!$isccCommand) { $isccCommand = Get-Command iscc -ErrorAction SilentlyContinue }
        if ($isccCommand) { $IsccPath = $isccCommand.Source }
        else { throw 'Inno Setup compiler is missing. Install Inno Setup or pass -IsccPath.' }
    }
    if (!(Test-Path -LiteralPath $IsccPath)) { throw 'Inno Setup compiler not found at the supplied path.' }
    $IsccPath = (Resolve-Path -LiteralPath $IsccPath).Path
    $env:FOOD_INVADERS_VERSION = $Version
    $env:FOOD_INVADERS_STAGE = $stageRoot
    $env:FOOD_INVADERS_OUTPUT = $OutputDir
    & $IsccPath (Join-Path $repoRoot 'packaging\windows\food-invaders.iss')
    if ($LASTEXITCODE -ne 0) { throw 'Inno Setup failed.' }
    Get-ChildItem -LiteralPath $OutputDir -Filter "Food-Invaders-Setup-$Version-x64.exe"
} finally {
    Remove-Item -LiteralPath $temporaryRoot -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item Env:FOOD_INVADERS_VERSION, Env:FOOD_INVADERS_STAGE, Env:FOOD_INVADERS_OUTPUT -ErrorAction SilentlyContinue
}
