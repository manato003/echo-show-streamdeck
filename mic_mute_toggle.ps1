# Toggle the default microphone's mute state via Windows Core Audio API.
# This mutes the physical mic input system-wide (Discord and any other
# app relying on the same input device will be muted too), and does not
# depend on keyboard hooks or window focus.
. "$PSScriptRoot\AudioMuteHelper.ps1"
[AudioMute]::SetMuted(-not [AudioMute]::IsMuted())
