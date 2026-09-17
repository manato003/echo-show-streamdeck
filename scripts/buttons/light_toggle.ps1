# Toggle the room light via SwitchBot IR remote. State is tracked locally
# (IR remotes have no feedback/queryable status), and pushed to a Companion
# custom variable so a button can reflect it.
# Loads config/config.ps1 (see scripts/lib/LoadConfig.ps1).
. "$PSScriptRoot\..\lib\LoadConfig.ps1"

$deviceId = $SwitchBotLightDeviceId
$stateFile = Join-Path $StateDir "light_state.txt"

$current = if (Test-Path $stateFile) { (Get-Content $stateFile -Raw).Trim() } else { "1" }
$newState = if ($current -eq "1") { "0" } else { "1" }
$command = if ($newState -eq "1") { "turnOn" } else { "turnOff" }

& "$LibDir\SwitchBotCommand.ps1" -DeviceId $deviceId -Command $command | Out-Null

Set-Content -Path $stateFile -Value $newState -NoNewline

Set-CompanionVariable -Name "light_on" -Value $newState
