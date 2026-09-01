<#
Generic global key-combo sender for Bitfocus Companion "Run a Path" actions.
Uses keybd_event so it reaches global hotkey listeners (e.g. Discord).

Usage:
  powershell.exe -ExecutionPolicy Bypass -File SendKeyCombo.ps1 -Keys "11,10,4D"
  (comma-separated DECIMAL virtual key codes, e.g. Ctrl+Shift+M)

Common VK codes:
  Ctrl=17  Shift=16  Alt=18  Win=91
  PrintScreen=44  S=83  M=77
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$Keys
)

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class KeySender {
    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    public const uint KEYEVENTF_KEYUP = 0x0002;
    public const uint KEYEVENTF_EXTENDEDKEY = 0x0001;
}
"@

# Right-side / navigation keys need the extended-key flag or Windows may not
# report them distinctly from their left-side counterpart.
$extendedKeys = @(163,165,91,92,45,46,33,34,35,36,37,38,39,40,144,145)

$vkCodes = $Keys -split ',' | ForEach-Object { [byte][int]$_.Trim() }

foreach ($vk in $vkCodes) {
    $flags = 0
    if ($extendedKeys -contains [int]$vk) { $flags = [KeySender]::KEYEVENTF_EXTENDEDKEY }
    [KeySender]::keybd_event($vk, 0, $flags, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 20
}
Start-Sleep -Milliseconds 30
[array]::Reverse($vkCodes)
foreach ($vk in $vkCodes) {
    $flags = [KeySender]::KEYEVENTF_KEYUP
    if ($extendedKeys -contains [int]$vk) { $flags = $flags -bor [KeySender]::KEYEVENTF_EXTENDEDKEY }
    [KeySender]::keybd_event($vk, 0, $flags, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 20
}
