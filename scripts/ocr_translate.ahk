#Requires AutoHotkey v2.0
#SingleInstance Force

End::{
    A_Clipboard := ""

    ; ShareX OCR shortcut: Home
    Send "{Home}"

    if !ClipWait(5) {
        MsgBox "OCR did not copy text within 5 seconds.", "ShareX OCR"
        return
    }

    translator := A_ScriptDir "\baidu_translate.ps1"
    command := "powershell.exe -NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File `"" . translator . "`""
    Run command
}

