# One-time script: create a Desktop shortcut that launches ChatGPT through the school proxy.
# Run this once; afterwards launch ChatGPT from the new shortcut, not the original icon.

$ErrorActionPreference = "Stop"

$script = Join-Path $env:USERPROFILE "start-chatgpt-proxy.ps1"
$desktop = [Environment]::GetFolderPath("Desktop")
$lnk = Join-Path $desktop "ChatGPT (School Proxy).lnk"

$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut($lnk)
$sc.TargetPath = "powershell.exe"
$sc.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$script`""
$sc.WorkingDirectory = $env:USERPROFILE
$sc.Description = "Launch ChatGPT desktop via school proxy"
$sc.IconLocation = "C:\Windows\System32\shell32.dll,13"
$sc.Save()

Write-Output "Shortcut created: $lnk"
