#Requires -Version 5.1
. "$PSScriptRoot\Common.ps1"
Assert-Windows
Refresh-ExecutablePath
foreach ($name in @('glazewm.exe','zebar.exe','wezterm-gui.exe','winget.exe')) {
    $path = Find-DesktopExecutable $name
    if ($path) { Write-Host "OK $name : $path" } else { Write-Warning "Missing $name" }
}
foreach ($file in @('.glzr\glazewm\config.yaml','.wezterm.lua','.glzr\zebar\omarchy-windows\zpack.json')) {
    $path = Join-Path $env:USERPROFILE $file
    if (Test-Path -LiteralPath $path) { Write-Host "OK config: $path" } else { Write-Warning "Missing config: $path" }
}
Get-Process glazewm,zebar -ErrorAction SilentlyContinue | Select-Object ProcessName,Id | Format-Table
Write-Host 'Visual/runtime checks still required: docs/WINDOWS-CHECKLIST.md'
