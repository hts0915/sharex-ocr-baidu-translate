$projectRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $projectRoot "scripts\ocr_translate.ahk"

if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "AutoHotkey script is missing."
}

$script = Get-Content -Raw -LiteralPath $scriptPath
foreach ($required in @('End::', 'Send "{Home}"', 'ClipWait(5)', 'baidu_translate.ps1')) {
    if ($script -notlike "*$required*") {
        throw "Missing AutoHotkey requirement: $required"
    }
}

if ($script -match 'D:\\LocalShareX') {
    throw "AutoHotkey script contains a personal absolute path."
}

Write-Output "AutoHotkey static checks passed."

