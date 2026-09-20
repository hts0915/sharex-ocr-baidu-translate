# ShareX OCR 百度翻译项目 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (\`- [ ]\`) syntax for tracking.

**Goal:** 将当前可用的 ShareX + AutoHotkey + PowerShell OCR 翻译流程整理为可公开发布、可配置且不会泄露百度密钥的 GitHub 项目。

**Architecture:** AutoHotkey 负责快捷键编排：清空旧剪贴板、模拟 ShareX OCR 快捷键、等待新 OCR 文本并启动 PowerShell。PowerShell 从项目根目录的本地 \`config.ps1\` 读取百度凭据，调用百度翻译 API，并用 Windows Forms 弹窗显示完整原文和译文；脚本使用自身位置计算路径，不依赖用户的 \`D:\\ShareX\` 路径。

**Tech Stack:** AutoHotkey v2；Windows PowerShell 5.1；ShareX OCR；百度翻译 API；Git/GitHub；MIT License。

## Global Constraints

- 不得把真实 APPID、密钥、截图、ShareX 数据库、历史记录或个人路径提交到公开仓库。
- \`config.ps1\` 必须被 \`.gitignore\` 忽略；仓库只提交 \`config.example.ps1\`。
- AutoHotkey 默认使用 \`End\` 触发，并向 ShareX 发送 \`Home\` OCR 快捷键。
- OCR 最大等待时间默认为 5 秒；超时必须显示明确提示。
- PowerShell 不得修改翻译后的剪贴板内容。
- 百度返回多段译文时必须全部合并显示。
- 所有公开脚本必须使用项目相对路径或 \`$PSScriptRoot\`，不得硬编码 \`D:\\ShareX\`。

---

### Task 1: 建立安全项目骨架

**Files:**
- Create: \`config.example.ps1\`
- Create: \`.gitignore\`
- Create: \`tests/test-secret-scan.ps1\`

**Interfaces:**
- \`config.example.ps1\` exports \`$BaiduAppId\` and \`$BaiduApiKey\`.
- \`.gitignore\` excludes \`config.ps1\`, logs, screenshots, and ShareX local data.

- [ ] **Step 1: Add the secret-scan test**

~~~powershell
$projectRoot = Split-Path -Parent $PSScriptRoot
$trackedFiles = git -C $projectRoot ls-files
$forbiddenPatterns = @(
    '\$appId\s*=\s*"\d{8,}"',
    '\$key\s*=\s*"[A-Za-z0-9]{16,}"',
    'D:\\LocalShareX'
)

foreach ($file in $trackedFiles) {
    $content = Get-Content -Raw (Join-Path $projectRoot $file)
    foreach ($pattern in $forbiddenPatterns) {
        if ($content -match $pattern) {
            throw "Forbidden secret or personal path found in tracked file: $file"
        }
    }
}

Write-Output 'Secret scan passed.'
~~~

- [ ] **Step 2: Add the config template and ignore rules**

~~~powershell
# config.example.ps1
$BaiduAppId = "YOUR_BAIDU_APP_ID"
$BaiduApiKey = "YOUR_BAIDU_API_KEY"
~~~

~~~gitignore
config.ps1
*.log
*.tmp
Screenshots/
Logs/
Backup/
History.db
ApplicationConfig.json
HotkeysConfig.json
UploadersConfig.json
Thumbs.db
Desktop.ini
~~~

- [ ] **Step 3: Run the scan and commit**

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\test-secret-scan.ps1
git add .gitignore config.example.ps1 tests/test-secret-scan.ps1
git commit -m "chore: add secure project scaffold"
~~~

Expected: the scan prints \`Secret scan passed.\`.

---

### Task 2: Implement the configurable PowerShell translator

**Files:**
- Create: \`scripts/baidu_translate.ps1\`
- Create: \`tests/test-translator-static.ps1\`

**Interfaces:**
- Consumes clipboard text and root-level \`config.ps1\`.
- Produces one Windows Forms dialog containing all original and translated text.
- Never calls \`Set-Clipboard\`.

- [ ] **Step 1: Add static checks**

~~~powershell
$projectRoot = Split-Path -Parent $PSScriptRoot
$script = Get-Content -Raw (Join-Path $projectRoot 'scripts\baidu_translate.ps1')

if ($script -match 'Set-Clipboard') { throw 'Translator must not write to clipboard.' }
if ($script -notmatch '\$PSScriptRoot') { throw 'Translator must use relative paths.' }
if ($script -notmatch 'ForEach-Object') { throw 'Translator must merge all translation segments.' }

Write-Output 'Translator static checks passed.'
~~~

- [ ] **Step 2: Implement the script**

The script must:
  1. load \`Join-Path (Split-Path -Parent $PSScriptRoot) 'config.ps1'\`;
  2. stop with a dialog if the file or either credential is missing;
  3. read \`Get-Clipboard -Raw\`;
  4. create a random salt and MD5 of \`APPID + text + salt + key\`;
  5. call \`https://fanyi-api.baidu.com/api/trans/vip/translate\`;
  6. show API errors without exposing credentials;
  7. join every \`trans_result\` destination using \`[Environment]::NewLine\`;
  8. show original and translation using Windows Forms;
  9. never write to the clipboard.

- [ ] **Step 3: Run static and manual tests**

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\test-translator-static.ps1
Copy-Item .\config.example.ps1 .\config.ps1
Set-Clipboard -Value 'Hello world'
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\scripts\baidu_translate.ps1
~~~

Expected: static check passes and a dialog shows the original plus its Chinese translation. Keep \`config.ps1\` local and ignored.

- [ ] **Step 4: Commit**

~~~powershell
git add scripts/baidu_translate.ps1 tests/test-translator-static.ps1
git commit -m "feat: add configurable Baidu OCR translator"
~~~

---

### Task 3: Implement the AutoHotkey trigger

**Files:**
- Create: \`scripts/ocr_translate.ahk\`
- Create: \`tests/test-ahk-static.ps1\`

**Interfaces:**
- ShareX OCR shortcut is \`Home\` and automatic OCR-result copy is enabled.
- Pressing \`End\` starts OCR, waits up to 5 seconds, then starts the PowerShell script beside the AHK file.

- [ ] **Step 1: Add static checks**

~~~powershell
$projectRoot = Split-Path -Parent $PSScriptRoot
$script = Get-Content -Raw (Join-Path $projectRoot 'scripts\ocr_translate.ahk')

foreach ($required in @('End::', 'Send "{Home}"', 'ClipWait(5)', 'baidu_translate.ps1')) {
    if ($script -notlike "*$required*") { throw "Missing AutoHotkey requirement: $required" }
}
if ($script -match 'D:\\LocalShareX') { throw 'Personal absolute path found.' }

Write-Output 'AutoHotkey static checks passed.'
~~~

- [ ] **Step 2: Implement the AHK v2 script**

Use \`End::{\`, clear \`A_Clipboard\`, send \`{Home}\`, call \`ClipWait(5)\`, show a timeout message, and run \`powershell.exe\` with \`-File A_ScriptDir "\\baidu_translate.ps1"\` and \`-WindowStyle Hidden\`.

- [ ] **Step 3: Run the static and end-to-end tests**

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\test-ahk-static.ps1
~~~

Then launch the AHK file, set ShareX OCR to \`Home\`, and press \`End\` over a one-word image and a multi-line image. Expected: no black console window, no stale OCR, and complete multi-line translation.

- [ ] **Step 4: Commit**

~~~powershell
git add scripts/ocr_translate.ahk tests/test-ahk-static.ps1
git commit -m "feat: add ShareX OCR hotkey integration"
~~~

---

### Task 4: Add public documentation and license

**Files:**
- Create: \`README.md\`
- Create: \`LICENSE\`

**Interfaces:**
- README must let a new Windows user install dependencies, configure credentials, set ShareX to \`Home\`, run the AHK script, change the trigger key, and troubleshoot failures.

- [ ] **Step 1: Write README sections**

Include: 功能、依赖、项目结构、百度翻译配置、ShareX 配置、运行方式、快捷键修改、故障排查、安全说明、许可证. Document:

~~~powershell
Copy-Item config.example.ps1 config.ps1
~~~

State clearly that \`config.ps1\` must never be committed.

- [ ] **Step 2: Add MIT License**

Use the standard MIT text and the repository owner’s chosen copyright name.

- [ ] **Step 3: Scan and commit**

~~~powershell
rg -n --hidden --glob '!*.db' '\$appId\s*=\s*"\d{8,}"|\$key\s*=\s*"[A-Za-z0-9]{16,}"|D:\\LocalShareX|config\.ps1' .
git add README.md LICENSE
git commit -m "docs: add setup and publishing guide"
~~~

Expected: no real secret or personal absolute path appears in tracked files; only the ignored local \`config.ps1\` may contain credentials.

---

### Task 5: Verify and publish the public repository

**Files:**
- Modify: Git metadata only

- [ ] **Step 1: Run all checks**

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\test-secret-scan.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\test-translator-static.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\test-ahk-static.ps1
git status --short
~~~

Expected: all checks pass and \`config.ps1\` is not listed.

- [ ] **Step 2: Configure local Git identity**

Use the owner’s chosen display name and GitHub noreply email:

~~~powershell
git config user.name "你的 GitHub 显示名称"
git config user.email "你的 GitHub noreply 邮箱"
~~~

- [ ] **Step 3: Add the public remote**

Create an empty public repository named \`sharex-ocr-baidu-translate\` on GitHub, then add its exact HTTPS URL as \`origin\`. Do not initialize the remote with extra files.

- [ ] **Step 4: Push the main branch**

~~~powershell
git branch -M main
git push -u origin main
~~~

Authenticate through GitHub’s normal credential prompt; never put a token in the remote URL or in a project file.

- [ ] **Step 5: Verify the published files**

Confirm the public repository contains scripts, config template, tests, README, and license, and does not contain \`config.ps1\`, screenshots, ShareX databases, logs, or real credentials.
