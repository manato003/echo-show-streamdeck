# Force Fully Kiosk on the Echo Show back to the Companion button page.
# Use this when the display is stuck on the wrong page.

# Loads config.ps1 from the repository root (see scripts/lib/Config.ps1).
. "$PSScriptRoot\..\lib\Config.ps1"

if (-not (Test-Path $AdbPath)) {
    throw "adb.exe not found at '$AdbPath'. Fix `$AdbPath in config.ps1."
}

# "host:port" means Wi-Fi ADB and needs an explicit connect; a bare serial is USB.
if ($EchoShowAdbTarget -match ':') {
    Write-Host "Connecting to Echo Show over Wi-Fi ($EchoShowAdbTarget)..."
    & $AdbPath connect $EchoShowAdbTarget
}

$state = (& $AdbPath -s $EchoShowAdbTarget get-state 2>$null)
if ($state -ne 'device') {
    throw "Echo Show ($EchoShowAdbTarget) is not reachable over ADB. Check the USB cable, or see docs/10-troubleshooting.md in the repository (OTA may have removed root)."
}

Write-Host "Stopping Fully Kiosk..."
& $AdbPath -s $EchoShowAdbTarget shell am force-stop de.ozerov.fully
Start-Sleep -Seconds 2

Write-Host "Starting Fully Kiosk at $CompanionEmulatorUrl ..."
& $AdbPath -s $EchoShowAdbTarget shell am start `
    -a android.intent.action.VIEW `
    -d "'$CompanionEmulatorUrl'" `
    -n de.ozerov.fully/de.ozerov.fully.FullyActivity

Write-Host "Done."
