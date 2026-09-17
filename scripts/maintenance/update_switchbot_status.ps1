# Fetch temperature/humidity from the SwitchBot Meter and push to Companion custom variables.
# Loads config/config.ps1 (see scripts/lib/LoadConfig.ps1).
. "$PSScriptRoot\..\lib\LoadConfig.ps1"
. "$LibDir\SwitchBotApi.ps1"

$deviceId = $SwitchBotMeterDeviceId
$status = Get-SwitchBotStatus -DeviceId $deviceId

$temp = $status.body.temperature
$humidity = $status.body.humidity
$battery = $status.body.battery

Set-CompanionVariable -Name "switchbot_temperature" -Value "$temp"
Set-CompanionVariable -Name "switchbot_humidity"    -Value "$humidity"
Set-CompanionVariable -Name "switchbot_battery"     -Value "$battery"
