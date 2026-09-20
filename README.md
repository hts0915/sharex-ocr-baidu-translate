# ShareX OCR 百度翻译

使用 ShareX OCR 识别屏幕文字，再通过百度翻译 API 自动翻译，并弹窗同时显示原文和译文。

## 功能

- 按一次 AutoHotkey 快捷键触发 ShareX OCR。
- 等待 OCR 自动复制文字到剪贴板。
- 调用百度翻译 API 翻译成中文。
- 支持多行文字，并完整合并所有译文段落。
- 不把译文写回剪贴板。

## 依赖

- Windows 10/11
- [ShareX](https://getsharex.com/)
- [AutoHotkey v2](https://www.autohotkey.com/)
- 百度翻译开放平台的 APPID 和密钥

## 项目结构

```text
scripts/ocr_translate.ahk    AutoHotkey 快捷键脚本
scripts/baidu_translate.ps1  PowerShell 翻译脚本
config.example.ps1           配置模板
tests/                        静态检查脚本
```

## 百度翻译配置

1. 在百度翻译开放平台创建通用翻译应用。
2. 复制配置模板：

   ```powershell
   Copy-Item config.example.ps1 config.ps1
   ```

3. 编辑 `config.ps1`：

   ```powershell
   $BaiduAppId = "你的 APPID"
   $BaiduApiKey = "你的密钥"
   ```

`config.ps1` 已被 `.gitignore` 忽略，绝对不要提交到 GitHub。

## ShareX 配置

1. 在 ShareX 中将 OCR 快捷键设为 `Home`。
2. 在 OCR 任务设置中启用“自动复制结果至剪贴板”。
3. 关闭 ShareX 中为 OCR 配置的“执行操作”，避免同步阻塞。

## 运行方式

1. 双击运行 `scripts/ocr_translate.ahk`。
2. 在包含文字的区域按 `End`。
3. ShareX 会执行 OCR，随后弹出原文和中文译文。

## 修改快捷键

默认触发键是 `End`，ShareX OCR 键是 `Home`。编辑 `scripts/ocr_translate.ahk` 的：

```ahk
End::{
```

并重新加载 AutoHotkey 脚本即可。若修改 ShareX OCR 键，也要同步修改 `Send "{Home}"`。

## 故障排查

- 提示未检测到 OCR 文字：确认 ShareX 的 OCR 快捷键和“自动复制结果至剪贴板”已启用。
- 提示配置缺失：确认已从模板创建 `config.ps1`，且变量值不是占位符。
- API 返回错误：检查百度应用状态、APPID、密钥和网络连接。
- 翻译内容不完整：确认使用的是仓库中的新版 PowerShell 脚本，它会合并全部返回段落。

## 安全说明

不要上传 `config.ps1`、截图、ShareX 数据库、日志或任何包含 API 密钥的文件。若密钥曾经公开，应先在百度翻译控制台重置。

## 许可证

本项目使用 MIT License，详见 [LICENSE](LICENSE)。

