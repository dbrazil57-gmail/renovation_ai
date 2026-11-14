$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
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
    try { dart run tool/ai_relay.dart }
    finally { Pop-Location }
}
finally {
    $env:OPENAI_API_KEY = $previousKey
    if ($keyPointer -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($keyPointer)
    }
    if ($null -ne $secureKey) { $secureKey.Dispose() }
}
