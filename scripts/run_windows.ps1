param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Debug',
    [switch]$Build
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$exe = Join-Path $root "build\windows\x64\runner\$Configuration\neocanvas.exe"

if ($Build -or -not (Test-Path -LiteralPath $exe)) {
    & (Join-Path $PSScriptRoot 'build_windows.ps1') -Configuration $Configuration -PubGet
}

if (-not (Test-Path -LiteralPath $exe)) {
    throw "Executable not found: $exe. Run build_windows.ps1 first."
}

Write-Host "Launching: $exe"
Start-Process -FilePath $exe
