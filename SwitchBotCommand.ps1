# Send a command to a SwitchBot device/IR-remote via the SwitchBot OpenAPI v1.1.
param(
    [Parameter(Mandatory=$true)][string]$DeviceId,
    [Parameter(Mandatory=$true)][string]$Command,
    [string]$Parameter = "default",
    [string]$CommandType = "command"
)

. "$PSScriptRoot\SwitchBotApi.ps1"

$headers = Get-SwitchBotAuthHeaders
$body = @{
    command = $Command
    parameter = $Parameter
    commandType = $CommandType
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://api.switch-bot.com/v1.1/devices/$DeviceId/commands" -Headers $headers -Method Post -Body $body
