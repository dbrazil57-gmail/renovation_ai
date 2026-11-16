$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
$dartCommand = Get-Command dart -ErrorAction SilentlyContinue
if ($null -ne $dartCommand) {
    $dartPath = $dartCommand.Source
} else {
    $dartPath = Join-Path $env:USERPROFILE 'Documents\flutter\bin\dart.bat'
    if (-not (Test-Path -LiteralPath $dartPath)) { throw 'Dart is not on PATH. Open a Flutter terminal and retry.' }
}
$previousKey = $env:OPENAI_API_KEY
$secureKey = $null
$keyPointer = [IntPtr]::Zero
try {
    if ([string]::IsNullOrWhiteSpace($env:OPENAI_API_KEY)) {
        $secureKey = Read-Host 'Enter your OpenAI developer API key (hidden; kept only for this session)' -AsSecureString
        $keyPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
        $env:OPENAI_API_KEY = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($keyPointer)
    }
    Push-Location -LiteralPath $projectPath
    try { & $dartPath run tool/ai_relay.dart }
    finally { Pop-Location }
}
finally {
    $env:OPENAI_API_KEY = $previousKey
    if ($keyPointer -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($keyPointer)
    }
    if ($null -ne $secureKey) { $secureKey.Dispose() }
}
