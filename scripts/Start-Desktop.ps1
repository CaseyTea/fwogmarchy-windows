#Requires -Version 5.1
. "$PSScriptRoot\Common.ps1"
Assert-Windows
Refresh-ExecutablePath
# Add discovered application directories for GlazeWM shell-exec commands.
foreach ($name in @('glazewm.exe','zebar.exe','wezterm-gui.exe')) {
    $exe = Find-DesktopExecutable $name
    if (!$exe) { throw "Cannot find $name. Reopen PowerShell or repair its installation." }
    $env:Path += ';' + (Split-Path -Parent $exe)
}
if (!(Get-Process glazewm -ErrorAction SilentlyContinue)) {
    $wm = Find-DesktopExecutable 'glazewm.exe'
    $config = Join-Path $env:USERPROFILE '.glzr\glazewm\config.yaml'
    Start-Process -FilePath $wm -ArgumentList @('start', '--config', ('"'+$config+'"'))
}
