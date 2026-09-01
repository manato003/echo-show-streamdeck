# Environment-specific settings. Copy this file to config.ps1 and edit it.
# config.ps1 is git-ignored, so your values never get committed.
#
# Nothing secret belongs here - API credentials go in switchbot_secrets.ps1.

# --- Bitfocus Companion (the PC running Companion) ---------------------------
# Use the LAN IP, NOT 127.0.0.1: Companion's web server binds to the LAN
# interface only and does not answer on loopback.
$CompanionHost = "192.168.1.30"
$CompanionPort = "8000"

# Emulator (Surface) id, from Companion: Surfaces > Add Emulator.
$CompanionEmulatorId = "PUT_YOUR_EMULATOR_ID_HERE"

# --- Echo Show ---------------------------------------------------------------
$EchoShowIp  = "192.168.1.221"
$EchoShowAdbPort = "5555"

# Path to adb.exe (Android platform-tools, or the copy bundled with amonet).
$AdbPath = "C:\platform-tools\adb.exe"

# --- SwitchBot device ids ----------------------------------------------------
# Discover yours with:  . .\SwitchBotApi.ps1 ; Get-SwitchBotDevices | ConvertTo-Json -Depth 5
# The light is an IR remote (infraredRemoteList), the meter is a physical device.
$SwitchBotLightDeviceId = "PUT_YOUR_IR_REMOTE_DEVICE_ID_HERE"
$SwitchBotMeterDeviceId = "PUT_YOUR_METER_DEVICE_ID_HERE"

# --- Derived values (do not edit) --------------------------------------------
$CompanionBaseUrl    = "http://${CompanionHost}:${CompanionPort}"
$CompanionEmulatorUrl = "$CompanionBaseUrl/emulator/$CompanionEmulatorId"
$EchoShowAdbTarget   = "${EchoShowIp}:${EchoShowAdbPort}"

# Posts a value to a Companion custom variable. Failures are ignored on purpose:
# the button's real action has already happened by the time this runs.
function Set-CompanionVariable {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$Value
    )
    try {
        Invoke-RestMethod -Uri "$CompanionBaseUrl/api/custom-variable/$Name/value" `
                          -Method Post -Body $Value -ContentType "text/plain" | Out-Null
    } catch {
        Write-Verbose "Companion unreachable: $_"
    }
}
