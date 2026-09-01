# Force Fully Kiosk on the Echo Show back to the Companion button page.
# Use this when the display is stuck on the wrong page.

# Environment-specific settings live in config.ps1 (git-ignored).
# Copy config.example.ps1 to create it.
$configFile = "$PSScriptRoot\config.ps1"
if (-not (Test-Path $configFile)) {
    throw "Missing $configFile. Copy config.example.ps1 and fill in your own values."
}
. $configFile

if (-not (Test-Path $AdbPath)) {
    throw "adb.exe not found at '$AdbPath'. Fix `$AdbPath in config.ps1."
}

Write-Host "Connecting to Echo Show ($EchoShowAdbTarget)..."
& $AdbPath connect $EchoShowAdbTarget

Write-Host "Stopping Fully Kiosk..."
& $AdbPath -s $EchoShowAdbTarget shell am force-stop de.ozerov.fully
Start-Sleep -Seconds 2

Write-Host "Starting Fully Kiosk at $CompanionEmulatorUrl ..."
& $AdbPath -s $EchoShowAdbTarget shell am start `
    -a android.intent.action.VIEW `
    -d "'$CompanionEmulatorUrl'" `
    -n de.ozerov.fully/de.ozerov.fully.FullyActivity

Write-Host "Done."
