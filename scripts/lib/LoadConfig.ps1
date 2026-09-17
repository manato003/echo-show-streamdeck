# Shared bootstrap for every script in scripts/.
# Dot-source it first:   . "$PSScriptRoot\..\lib\LoadConfig.ps1"
#
# Loads the user's config/config.ps1 and defines:
#   $RepoRoot, $LibDir, $StateDir, $CompanionBaseUrl, $CompanionEmulatorUrl,
#   and the Set-CompanionVariable function.

$LibDir   = $PSScriptRoot
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$StateDir = Join-Path $RepoRoot 'state'

$configFile = Join-Path $RepoRoot 'config\config.ps1'
if (-not (Test-Path $configFile)) {
    throw "Missing $configFile. Copy config\config.example.ps1 to config\config.ps1 and fill in your own values."
}
. $configFile

if (-not (Test-Path $StateDir)) {
    New-Item -ItemType Directory -Path $StateDir | Out-Null
}

$CompanionBaseUrl     = "http://${CompanionHost}:${CompanionPort}"
$CompanionEmulatorUrl = "$CompanionBaseUrl/emulator/$CompanionEmulatorId"

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
