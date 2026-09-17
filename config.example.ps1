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
# ADB target.
#   USB (recommended): the device serial shown by "adb devices", e.g. "G0XXXXXXXXXXXXXX".
#   Wi-Fi:             "<ECHO_IP>:5555" - only if Wi-Fi ADB is enabled on the device.
$EchoShowAdbTarget = "PUT_YOUR_DEVICE_SERIAL_HERE"

# Path to adb.exe (Android platform-tools, or the copy bundled with amonet).
$AdbPath = "C:\platform-tools\adb.exe"

# --- SwitchBot device ids ----------------------------------------------------
# Discover yours with:  . .\scripts\lib\SwitchBotApi.ps1 ; Get-SwitchBotDevices | ConvertTo-Json -Depth 5
# The light is an IR remote (infraredRemoteList), the meter is a physical device.
$SwitchBotLightDeviceId = "PUT_YOUR_IR_REMOTE_DEVICE_ID_HERE"
$SwitchBotMeterDeviceId = "PUT_YOUR_METER_DEVICE_ID_HERE"
