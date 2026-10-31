param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Debug',
    [switch]$PubGet
)

$ErrorActionPreference = 'Stop'

function Resolve-Flutter {
    $command = Get-Command flutter -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }
    if ($env:FLUTTER_ROOT) {
        $candidate = Join-Path $env:FLUTTER_ROOT 'bin\flutter.bat'
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }
    throw 'Flutter not found. Add Flutter bin to PATH, set FLUTTER_ROOT, or restart VS Code.'
}

$root = Split-Path $PSScriptRoot -Parent
$flutter = Resolve-Flutter

Push-Location $root
try {
    if ($PubGet -or -not (Test-Path -LiteralPath '.dart_tool\package_config.json')) {
        Write-Host 'Running flutter pub get...'
        & $flutter pub get
        if ($LASTEXITCODE -ne 0) {
            throw "flutter pub get failed ($LASTEXITCODE)"
        }
    }

    Write-Host "Building Windows ($Configuration)..."
    & $flutter build windows "--$($Configuration.ToLower())"
    if ($LASTEXITCODE -ne 0) {
        throw "flutter build windows failed ($LASTEXITCODE)"
    }

    $exe = Join-Path $root "build\windows\x64\runner\$Configuration\neocanvas.exe"
    if (-not (Test-Path -LiteralPath $exe)) {
        throw "Build output not found: $exe"
    }
    Write-Host "Build OK: $exe"
} finally {
    Pop-Location
}
