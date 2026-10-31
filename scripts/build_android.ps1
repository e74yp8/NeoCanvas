param(
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

    Write-Host 'Building Android APK (Debug)...'
    & $flutter build apk --debug
    if ($LASTEXITCODE -ne 0) {
        throw "flutter build apk failed ($LASTEXITCODE)"
    }

    $apk = Join-Path $root 'build\app\outputs\flutter-apk\app-debug.apk'
    if (-not (Test-Path -LiteralPath $apk)) {
        throw "Build output not found: $apk"
    }
    Write-Host "Build OK: $apk"
} finally {
    Pop-Location
}
