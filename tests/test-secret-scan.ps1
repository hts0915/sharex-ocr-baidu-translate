$projectRoot = Split-Path -Parent $PSScriptRoot
$trackedFiles = git -C $projectRoot ls-files
$forbiddenPatterns = @(
    '\$appId\s*=\s*"\d{8,}"',
    '\$key\s*=\s*"[A-Za-z0-9]{16,}"',
    'D:\\LocalShareX'
)

foreach ($file in $trackedFiles) {
    $fullPath = Join-Path $projectRoot $file
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        continue
    }

    $content = Get-Content -Raw -LiteralPath $fullPath
    foreach ($pattern in $forbiddenPatterns) {
        if ($content -match $pattern) {
            throw "Forbidden secret or personal path found in tracked file: $file"
        }
    }
}

Write-Output "Secret scan passed."

