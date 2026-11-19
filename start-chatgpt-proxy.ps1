# Launch ChatGPT desktop via the school international proxy.
#
# Why: the ChatGPT desktop app is Chromium-based. If your school uses a PAC
# (automatic proxy) that Chromium ignores, the UI cannot reach chatgpt.com.
# --proxy-server forces Chromium onto the proxy explicitly.
#
# NOTE: This script only handles the Chromium/UI layer. The built-in Codex
# Rust backend (WebSocket) is a separate process and does NOT read this flag.
# See README.md for the required ~/.codex/config.toml change
# (respect_system_proxy = true) and the Windows system proxy setup.
#
# Safe to delete this script and its shortcut; no system config is changed here.

$ErrorActionPreference = "Stop"
$proxy = "http://proxy-intl-prod-dku.oit.duke.edu:3128"   # <-- change to your proxy

# AppX/MSIX updates change the install path, so locate the exe dynamically.
$pkg = Get-AppxPackage -Name "OpenAI.Codex"
if (-not $pkg) { throw "OpenAI.Codex package not found" }

$exe = Get-ChildItem -Path $pkg.InstallLocation -Filter "ChatGPT.exe" -Recurse -ErrorAction SilentlyContinue |
       Select-Object -First 1
if (-not $exe) { throw "ChatGPT.exe not found under $($pkg.InstallLocation)" }

# An already-running instance ignores launch flags; close it first.
Get-Process -Name "ChatGPT" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 800

Start-Process -FilePath $exe.FullName -ArgumentList "--proxy-server=$proxy"
