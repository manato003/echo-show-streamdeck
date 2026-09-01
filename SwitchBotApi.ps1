# SwitchBot OpenAPI v1.1 helper (HMAC-SHA256 request signing).

# Credentials live in switchbot_secrets.ps1, which git ignores. Copy
# switchbot_secrets.example.ps1 to create it.
$secretsFile = "$PSScriptRoot\switchbot_secrets.ps1"
if (-not (Test-Path $secretsFile)) {
    throw "Missing $secretsFile. Copy switchbot_secrets.example.ps1 and fill in your SwitchBot token and secret."
}
. $secretsFile

function Get-SwitchBotAuthHeaders {
    $t = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds().ToString()
    $nonce = [guid]::NewGuid().ToString()
    $stringToSign = "$SwitchBotToken$t$nonce"

    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = [System.Text.Encoding]::UTF8.GetBytes($SwitchBotSecret)
    $signBytes = $hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($stringToSign))
    $sign = [Convert]::ToBase64String($signBytes).ToUpper()

    return @{
        "Authorization" = $SwitchBotToken
        "sign"          = $sign
        "t"             = $t
        "nonce"         = $nonce
        "Content-Type"  = "application/json; charset=utf8"
    }
}

function Get-SwitchBotDevices {
    $headers = Get-SwitchBotAuthHeaders
    Invoke-RestMethod -Uri "https://api.switch-bot.com/v1.1/devices" -Headers $headers -Method Get
}

function Get-SwitchBotStatus {
    param([Parameter(Mandatory=$true)][string]$DeviceId)
    $headers = Get-SwitchBotAuthHeaders
    Invoke-RestMethod -Uri "https://api.switch-bot.com/v1.1/devices/$DeviceId/status" -Headers $headers -Method Get
}
