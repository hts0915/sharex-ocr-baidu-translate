Add-Type -AssemblyName System.Windows.Forms

function Show-Message {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $true)][string]$Title
    )

    [System.Windows.Forms.MessageBox]::Show($Message, $Title) | Out-Null
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $projectRoot "config.ps1"

if (-not (Test-Path -LiteralPath $configPath)) {
    Show-Message "Missing config.ps1. Copy config.example.ps1 to config.ps1 and fill in your Baidu credentials." "OCR Translation"
    exit 1
}

try {
    . $configPath
} catch {
    Show-Message "Could not load config.ps1: $($_.Exception.Message)" "OCR Translation"
    exit 1
}

if ([string]::IsNullOrWhiteSpace($BaiduAppId) -or
    [string]::IsNullOrWhiteSpace($BaiduApiKey) -or
    $BaiduAppId -eq "YOUR_BAIDU_APP_ID" -or
    $BaiduApiKey -eq "YOUR_BAIDU_API_KEY") {
    Show-Message "Fill in BaiduAppId and BaiduApiKey in config.ps1 first." "OCR Translation"
    exit 1
}

$text = Get-Clipboard -Raw
if ([string]::IsNullOrWhiteSpace($text)) {
    Show-Message "No OCR text was found in the clipboard." "OCR Translation"
    exit 1
}

$salt = Get-Random -Minimum 10000 -Maximum 99999
$raw = "$BaiduAppId$text$salt$BaiduApiKey"
$md5 = [Security.Cryptography.MD5]::Create()
$sign = [BitConverter]::ToString(
    $md5.ComputeHash([Text.Encoding]::UTF8.GetBytes($raw))
).Replace("-", "").ToLower()

$body = @{
    q = $text
    from = "auto"
    to = "zh"
    appid = $BaiduAppId
    salt = $salt
    sign = $sign
}

try {
    $result = Invoke-RestMethod `
        -Uri "https://fanyi-api.baidu.com/api/trans/vip/translate" `
        -Method Post `
        -Body $body `
        -ErrorAction Stop
} catch {
    Show-Message "Baidu request failed: $($_.Exception.Message)" "Baidu Translation Error"
    exit 1
}

if ($result.error_code) {
    Show-Message "$($result.error_code): $($result.error_msg)" "Baidu Translation Error"
    exit 1
}

if (-not $result.trans_result) {
    Show-Message "Baidu returned no translation." "Baidu Translation Error"
    exit 1
}

$translation = @($result.trans_result | ForEach-Object {
    $_.dst
}) -join [Environment]::NewLine

$message = "Original:`r`n$text`r`n`r`nTranslation:`r`n$translation"
Show-Message $message "OCR Translation"

