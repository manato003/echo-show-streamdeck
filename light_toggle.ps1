# Toggle the room light via SwitchBot IR remote. State is tracked locally
# (IR remotes have no feedback/queryable status), and pushed to a Companion
# custom variable so a button can reflect it.
# Environment-specific settings live in config.ps1 (git-ignored).
# Copy config.example.ps1 to create it.
$configFile = "$PSScriptRoot\config.ps1"
if (-not (Test-Path $configFile)) {
    throw "Missing $configFile. Copy config.example.ps1 and fill in your own values."
}
. $configFile

$deviceId = $SwitchBotLightDeviceId
$stateFile = "$PSScriptRoot\light_state.txt"

$current = if (Test-Path $stateFile) { (Get-Content $stateFile -Raw).Trim() } else { "1" }
$newState = if ($current -eq "1") { "0" } else { "1" }
$command = if ($newState -eq "1") { "turnOn" } else { "turnOff" }

& "$PSScriptRoot\SwitchBotCommand.ps1" -DeviceId $deviceId -Command $command | Out-Null

Set-Content -Path $stateFile -Value $newState -NoNewline

Set-CompanionVariable -Name "light_on" -Value $newState
