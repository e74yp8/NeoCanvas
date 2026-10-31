param(
    [ValidateSet('Debug', 'Profile', 'Release')]
    [string]$Mode = 'Debug',

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ExtraArgs
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
    if ($Mode -eq 'Release') {
        Write-Warning 'DevTools and hot reload are not available in Release mode.'
    }

    Write-Host "Running Flutter ($Mode) on Windows..."
    & $flutter run -d windows "--$($Mode.ToLower())" @ExtraArgs
    if ($LASTEXITCODE -ne 0) {
        throw "flutter run failed ($LASTEXITCODE)"
    }
} finally {
    Pop-Location
}
