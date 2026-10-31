Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function Assert-Windows {
    if ($env:OS -ne 'Windows_NT') { throw 'Run this script on Windows.' }
}
function Get-DesktopStateRoot {
    if ($env:OMARCHY_WINDOWS_STATE) { return $env:OMARCHY_WINDOWS_STATE }
    return (Join-Path $env:LOCALAPPDATA 'OmarchyWindows')
}
function Write-Utf8File([string]$Path, [string]$Content) {
    $parent = Split-Path -Parent $Path
    [IO.Directory]::CreateDirectory($parent) | Out-Null
    [IO.File]::WriteAllText($Path, $Content, [Text.UTF8Encoding]::new($false))
}
function Write-State($State, [string]$Path) {
    Write-Utf8File $Path ($State | ConvertTo-Json -Depth 12)
}
function Refresh-ExecutablePath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
}
function Find-DesktopExecutable([string]$Name) {
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    $candidates = switch ($Name) {
        'glazewm.exe' { @("$env:ProgramFiles\glzr.io\GlazeWM\glazewm.exe", "$env:LOCALAPPDATA\Programs\glzr.io\GlazeWM\glazewm.exe") }
        'zebar.exe' { @("$env:ProgramFiles\glzr.io\Zebar\zebar.exe", "$env:LOCALAPPDATA\Programs\glzr.io\Zebar\zebar.exe") }
        'wezterm-gui.exe' { @("$env:ProgramFiles\WezTerm\wezterm-gui.exe", "$env:LOCALAPPDATA\Programs\WezTerm\wezterm-gui.exe") }
        'PowerToys.exe' { @("$env:LOCALAPPDATA\PowerToys\PowerToys.exe", "$env:ProgramFiles\PowerToys\PowerToys.exe") }
        default { @() }
    }
    foreach ($candidate in $candidates) { if (Test-Path -LiteralPath $candidate) { return $candidate } }
    return $null
}
function New-DesktopStartupShortcut([string]$Path,[string]$RunnerPath) {
    [IO.Directory]::CreateDirectory((Split-Path -Parent $Path)) | Out-Null
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $null
    try {
        $shortcut = $shell.CreateShortcut($Path)
        $shortcut.TargetPath = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $shortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "'+$RunnerPath+'"'
        $shortcut.WorkingDirectory = Split-Path -Parent $RunnerPath
        $shortcut.WindowStyle = 7
        $shortcut.Description = 'Start the Fwogmarchy desktop and configured app launcher'
        $shortcut.Save()
    } finally {
        if ($shortcut) { [Runtime.InteropServices.Marshal]::FinalReleaseComObject($shortcut) | Out-Null }
        [Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell) | Out-Null
    }
}
