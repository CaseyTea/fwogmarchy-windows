#Requires -Version 5.1
. "$PSScriptRoot\Common.ps1"
Assert-Windows
Refresh-ExecutablePath
foreach ($name in @('glazewm.exe','zebar.exe','wezterm-gui.exe','winget.exe','PowerToys.exe')) {
    $path = Find-DesktopExecutable $name
    if ($path) { Write-Host "OK $name : $path" } else { Write-Warning "Missing $name" }
}
foreach ($file in @('.glzr\glazewm\config.yaml','.wezterm.lua','.glzr\zebar\omarchy-windows\zpack.json')) {
    $path = Join-Path $env:USERPROFILE $file
    if (Test-Path -LiteralPath $path) { Write-Host "OK config: $path" } else { Write-Warning "Missing config: $path" }
}
Get-Process glazewm,zebar -ErrorAction SilentlyContinue | Select-Object ProcessName,Id | Format-Table
$startupFile = Join-Path ([Environment]::GetFolderPath('Startup')) 'OmarchyWindows.lnk'
if (Test-Path -LiteralPath $startupFile) { Write-Host "OK login shortcut: $startupFile" } else { Write-Warning 'Login shortcut is missing. Rerun the installer without -NoStartup.' }
$startupLog = Join-Path (Get-DesktopStateRoot) 'startup.log'
if (Test-Path -LiteralPath $startupLog) { Write-Host "Recent startup log: $startupLog"; Get-Content -LiteralPath $startupLog -Tail 12 }
Write-Host 'Visual/runtime checks still required: docs/WINDOWS-CHECKLIST.md'
