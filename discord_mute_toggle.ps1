# Toggle Discord mute so it reflects in Discord's own UI.
# Discord's global hotkey hook ignores synthetic (injected) key events when
# unfocused, but accepts them fine when Discord is the foreground window.
# So: briefly focus Discord, send the hotkey, then restore the previous
# foreground window.
# Discord's "Toggle Mute" hotkey is registered as "RIGHT CTRL + KANAMOJI",
# which is the OEM_5 key (\ on US layout, Yen on JIS layout) - not VK_KANA.

# Environment-specific settings live in config.ps1 (git-ignored).
# Copy config.example.ps1 to create it.
$configFile = "$PSScriptRoot\config.ps1"
if (-not (Test-Path $configFile)) {
    throw "Missing $configFile. Copy config.example.ps1 and fill in your own values."
}
. $configFile

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    public const uint KEYEVENTF_KEYUP = 0x0002;
    public const byte VK_MENU = 0x12;
}
"@

$discordProc = Get-Process -Name Discord -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1

if (-not $discordProc) {
    Write-Error "Discord window not found."
    exit 1
}

$originalForeground = [Win32]::GetForegroundWindow()

# Alt tap trick: bypasses Windows' foreground-lock restriction for SetForegroundWindow
[Win32]::keybd_event([Win32]::VK_MENU, 0, 0, [UIntPtr]::Zero)
[Win32]::keybd_event([Win32]::VK_MENU, 0, [Win32]::KEYEVENTF_KEYUP, [UIntPtr]::Zero)

[Win32]::SetForegroundWindow($discordProc.MainWindowHandle) | Out-Null
Start-Sleep -Milliseconds 400

# Right Ctrl=163, OEM_5 (\/Yen)=220
& "$PSScriptRoot\SendKeyCombo.ps1" -Keys "163,220"

Start-Sleep -Milliseconds 200
if ($originalForeground -ne [IntPtr]::Zero) {
    [Win32]::SetForegroundWindow($originalForeground) | Out-Null
}

# Track assumed mute state locally (Discord exposes no readable mute state),
# and push it to Companion's custom variable so the button can show it.
$stateFile = "$PSScriptRoot\discord_mute_state.txt"
$current = if (Test-Path $stateFile) { Get-Content $stateFile -Raw } else { "0" }
$newState = if ($current.Trim() -eq "1") { "0" } else { "1" }
Set-Content -Path $stateFile -Value $newState -NoNewline

Set-CompanionVariable -Name "discord_mute" -Value $newState
