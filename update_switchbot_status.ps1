# Fetch temperature/humidity from the SwitchBot Meter and push to Companion custom variables.
# Environment-specific settings live in config.ps1 (git-ignored).
# Copy config.example.ps1 to create it.
$configFile = "$PSScriptRoot\config.ps1"
if (-not (Test-Path $configFile)) {
    throw "Missing $configFile. Copy config.example.ps1 and fill in your own values."
}
. $configFile
. "$PSScriptRoot\SwitchBotApi.ps1"

$deviceId = $SwitchBotMeterDeviceId
$status = Get-SwitchBotStatus -DeviceId $deviceId

$temp = $status.body.temperature
$humidity = $status.body.humidity
$battery = $status.body.battery

Set-CompanionVariable -Name "switchbot_temperature" -Value "$temp"
Set-CompanionVariable -Name "switchbot_humidity"    -Value "$humidity"
Set-CompanionVariable -Name "switchbot_battery"     -Value "$battery"
