param([ValidateRange(1024, 65535)][int]$Port = 7357)
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
try {
    & $flutterPath run -d web-server --web-hostname localhost --web-port $Port "--dart-define=RENOVISION_BUILD_ID=$buildId"
    $runExitCode = $LASTEXITCODE
} finally { Pop-Location }
exit $runExitCode
