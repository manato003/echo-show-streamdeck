# Capture active window via Alt+PrintScreen, save clipboard image to Pictures\Screenshots
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Alt(18) + PrintScreen(44)
& "$PSScriptRoot\SendKeyCombo.ps1" -Keys "18,44"

Start-Sleep -Milliseconds 400

if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
    $img = [System.Windows.Forms.Clipboard]::GetImage()
    $dir = "$env:USERPROFILE\Pictures\Screenshots"
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    $filename = "window_{0:yyyyMMdd_HHmmss}.png" -f (Get-Date)
    $path = Join-Path $dir $filename
    $img.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
}
