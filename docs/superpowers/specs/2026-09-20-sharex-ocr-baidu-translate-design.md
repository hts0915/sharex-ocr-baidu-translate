# ShareX OCR 百度翻译项目设计

## 目标

将当前可用的 ShareX + AutoHotkey + PowerShell 流程整理成一个可公开发布的 GitHub 项目：按下 AutoHotkey 快捷键后，触发 ShareX OCR，等待 OCR 自动复制文字，再调用百度翻译 API，并弹窗同时显示原文和译文。

示例流程：

```text
按 End
→ AutoHotkey 模拟 Home
→ ShareX 执行 OCR 并自动复制结果
→ PowerShell 调用百度翻译
→ 弹窗显示 Original 与 Translation
```

脚本不修改翻译后的剪贴板内容；剪贴板只作为 OCR 结果在 ShareX 与 PowerShell 之间的临时传递渠道。

## 项目结构

```text
sharex-ocr-baidu-translate/
├─ scripts/
│  ├─ ocr_translate.ahk
│  └─ baidu_translate.ps1
├─ config.example.ps1
├─ .gitignore
├─ README.md
└─ LICENSE
```

`config.example.ps1` 只包含配置格式和占位符；用户复制为本地 `config.ps1` 后填写百度 APPID 与密钥。`config.ps1` 被 `.gitignore` 忽略，不会上传到公开仓库。

## 运行设计

### AutoHotkey

- 使用 AutoHotkey v2。
- 默认监听 `End`。
- 清空旧剪贴板后模拟 `Home`，由 ShareX 的 OCR 快捷键完成识别。
- 使用 `ClipWait` 等待 OCR 结果，默认最长 5 秒。
- 成功后启动同目录的 PowerShell 脚本，并隐藏 PowerShell 控制台窗口。
- OCR 超时显示提示，不调用翻译接口。

### PowerShell

- 使用 Windows PowerShell 5.1 兼容语法。
- 从项目根目录的 `config.ps1` 读取 APPID 与密钥。
- 从剪贴板读取 OCR 文本。
- 按百度翻译 API 规则生成 MD5 签名并提交请求。
- 合并百度返回的多段译文，避免长文本只显示第一段。
- 使用 Windows Forms 消息框显示原文、译文或明确的错误信息。
- 不写回剪贴板，脚本完成后退出，不驻留后台。

## 安全设计

- 禁止在源码、README、示例配置、日志或提交信息中出现真实 APPID/密钥。
- `config.ps1` 写入 `.gitignore`。
- README 只说明如何从 `config.example.ps1` 创建本地配置。
- 如果密钥曾经出现在公开历史中，应在发布前更换密钥；本项目不尝试清理外部平台已有的泄露记录。

## 配置与路径

- 脚本使用自身目录和项目根目录计算路径，不依赖用户机器上的绝对路径。
- ShareX 仍需由用户自行将 OCR 快捷键设置为 `Home`，并开启“自动复制结果至剪贴板”。
- 如需更换 AutoHotkey 触发键，只需修改 `ocr_translate.ahk` 的热键声明，并重新加载脚本。

## 错误处理

- OCR 没有在超时时间内写入剪贴板：提示用户检查 ShareX OCR 快捷键和自动复制选项。
- 配置文件缺失或字段为空：提示创建并填写 `config.ps1`。
- 百度 API 返回错误：弹窗显示错误码和错误信息，但不显示密钥。
- 网络或接口调用异常：捕获异常并显示简洁错误信息。

## 验证计划

1. 用固定剪贴板文本进行 PowerShell 单独测试，确认百度翻译返回结果。
2. 用 ShareX OCR 识别单词和多行文本，确认完整译文均显示。
3. 按 AutoHotkey 快捷键测试端到端流程，确认不会读取上一次 OCR。
4. 删除或改名 `config.ps1`，确认缺失配置时给出明确提示。
5. 扫描待提交文件，确认没有真实密钥、个人路径或运行日志。

## 发布范围

首个公开版本只包含脚本、配置模板、安装使用文档和 MIT License，不包含 ShareX 配置数据库、截图、历史记录或任何个人环境文件。
