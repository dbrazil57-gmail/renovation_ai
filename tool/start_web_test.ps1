param(
    [ValidateRange(1024, 65535)][int]$Port = 7357,
    [switch]$Release
)
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
if ($null -ne $flutterCommand) {
    $flutterPath = $flutterCommand.Source
} else {
    $flutterPath = Join-Path $env:USERPROFILE 'Documents\flutter\bin\flutter.bat'
    if (-not (Test-Path -LiteralPath $flutterPath)) { throw 'Flutter is not on PATH. Open a Flutter terminal and retry.' }
}
if ($Port -eq 8787) { throw 'Port 8787 is reserved for the local AI relay. Use 7357 for the app.' }
# Include source hashes so the running build can be compared with Settings.
$sourceHashes = Get-ChildItem -LiteralPath (Join-Path $projectPath 'lib') -Filter '*.dart' -Recurse |
    Sort-Object FullName | ForEach-Object { (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
$hashAlgorithm = [Security.Cryptography.SHA256]::Create()
try {
    $digest = $hashAlgorithm.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceHashes -join '')))
    $buildId = ([BitConverter]::ToString($digest) -replace '-', '').Substring(0, 10).ToLowerInvariant()
} finally { $hashAlgorithm.Dispose() }
Write-Host "Renovision build: $buildId"
Write-Host "Open http://localhost:$Port in your normal Chrome profile (not Incognito)."
Write-Host 'Keep using this exact address. The launcher will not switch ports if it is busy.'
Write-Host 'If old test projects are missing, restore a project backup into this profile.'
Write-Host 'This launcher does not copy, replace or delete browser data.'
Push-Location -LiteralPath $projectPath
$previousWindowsFeature = $env:FLUTTER_WINDOWS
$previousLinuxFeature = $env:FLUTTER_LINUX
try {
    # This launcher targets Chrome only. Avoid unnecessary desktop-plugin
    # symlinks on Windows without changing global Flutter feature settings.
    $env:FLUTTER_WINDOWS = 'false'
    $env:FLUTTER_LINUX = 'false'
    if ($Release) {
        Write-Host 'Desktop preview: release mode.'
        & $flutterPath build web --release --no-wasm-dry-run --no-web-resources-cdn "--dart-define=RENOVISION_BUILD_ID=$buildId"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        $dartPath = Join-Path (Split-Path -Parent $flutterPath) 'cache\dart-sdk\bin\dart.exe'
        if (-not (Test-Path -LiteralPath $dartPath)) { throw 'The Flutter SDK Dart runtime is unavailable.' }
        & $dartPath (Join-Path $PSScriptRoot 'serve_web_preview.dart') "$Port"
    } else {
        & $flutterPath run -d web-server --web-hostname localhost --web-port $Port "--dart-define=RENOVISION_BUILD_ID=$buildId"
    }
    $runExitCode = $LASTEXITCODE
} finally {
    $env:FLUTTER_WINDOWS = $previousWindowsFeature
    $env:FLUTTER_LINUX = $previousLinuxFeature
    Pop-Location
}
exit $runExitCode
