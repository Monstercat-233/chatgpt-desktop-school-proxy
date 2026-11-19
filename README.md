# ChatGPT Desktop / Codex — School Proxy Fix (Windows)

Fix the endless **"正在重新连接 / Reconnecting 1/5 → 5/5"** loop in the official
ChatGPT desktop app when you are behind a school proxy that uses a PAC
(automatic configuration script).

## The problem (two separate layers)

The ChatGPT desktop app has **two** network layers, and each ignores the proxy
in a different way:

1. **Chromium UI layer** — does not read the Windows PAC (`AutoConfigURL`).
   Direct connections to `chatgpt.com` time out → the window spins / won't load.
2. **Built-in Codex Rust backend** (`codex.exe`, a separate process handling the
   WebSocket) — does **not** read `--proxy-server` and does **not** use the
   system proxy by default. Its WSS connections go direct and fail, causing the
   `Reconnecting 1/5 … 5/5` loop. Only after falling back to HTTP does it work.

Your browser (e.g. Edge) works out of the box because it **does** read the PAC,
which routes `chatgpt.com` through the international proxy.

## The fix

### 1. Set the Windows system proxy to your school PAC

Point `AutoConfigURL` at your PAC URL and disable the manual proxy:

```powershell
$k = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
Set-ItemProperty $k -Name 'AutoConfigURL' -Value 'http://proxy-dku.oit.duke.edu/wpad.dat'
Set-ItemProperty $k -Name 'ProxyEnable' -Value 0
Set-ItemProperty $k -Name 'ProxyServer' -Value ''
```

Or in Windows Settings → Network & Internet → Proxy → "Use setup script", enter
the PAC URL. Refresh the settings so apps pick it up (sign out/in or reboot).

> Note: a PAC can return different proxies for different hosts. Make sure the
> PAC sends `chatgpt.com` / `openai.com` to an **international**出口 that can
> actually reach them. A domestic-only proxy may return 503 / `ERR_CONNECT_FAIL`.

### 2. Make the Codex backend respect the system proxy

Edit `~/.codex/config.toml` (UTF-8 **without BOM**) and add one line under the
existing `[features]` table. Do **not** create a second `[features]` table and do
not touch `model_provider` (changing it can make old sessions disappear).

```toml
[features]
respect_system_proxy = true
```

Back up the file first. Fully quit ChatGPT (including the tray process) and the
`codex.exe` backend, then relaunch.

### 3. Force the Chromium UI onto the proxy

Edit the proxy address in `start-chatgpt-proxy.ps1` if yours differs, then:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\start-chatgpt-proxy.ps1
```

This closes any running ChatGPT, then relaunches it with
`--proxy-server=<your proxy>`.

Optional — create a Desktop shortcut once:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-chatgpt-proxy-shortcut.ps1
```

Afterwards launch from the **"ChatGPT (School Proxy)"** shortcut, not the
original icon. Keep your school VPN connected.

## Verify

After relaunch, check that `codex.exe` has an ESTABLISHED connection to your
international proxy — that is direct evidence the WebSocket is going through it:

```powershell
Get-NetTCPConnection -State Established |
  Where-Object { $_.RemotePort -eq 3128 } |
  Select-Object RemoteAddress, RemotePort, OwningProcess
```

If you see connections from the `codex` process to the proxy, the fix worked and
a new chat should show "Thinking" instead of "Reconnecting".

## Files

- `start-chatgpt-proxy.ps1` — relaunch ChatGPT with `--proxy-server`.
- `install-chatgpt-proxy-shortcut.ps1` — create the Desktop shortcut.

## References

- Codex `Feature::RespectSystemProxy` (default false) and WSS proxy routing:
  [openai/codex#e621d7d](https://github.com/openai/codex/commit/e621d7df8c4571e0b996a29095ef0de5bc93af5c),
  [openai/codex#31916](https://github.com/openai/codex/pull/31916)
- Desktop "Reconnecting 5/5" root cause (WS ignores system proxy):
  [LINUX DO](https://linux.do/t/topic/2987375)
