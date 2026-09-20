$projectRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $projectRoot "scripts\baidu_translate.ps1"

if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Translator script is missing."
}

$script = Get-Content -Raw -LiteralPath $scriptPath

if ($script -match "Set-Clipboard") {
    throw "Translator must not write to the clipboard."
}
if ($script -notmatch '\$PSScriptRoot') {
    throw "Translator must use a relative project path."
}
if ($script -notmatch "ForEach-Object") {
    throw "Translator must merge all translation segments."
}

Write-Output "Translator static checks passed."
