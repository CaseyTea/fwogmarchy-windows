#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$SkipPackages,
    [switch]$NoStartup,
    [switch]$NoStart,
    # Sandbox target for automated tests; never starts apps or creates login startup.
    [string]$SandboxRoot
)
. "$PSScriptRoot\scripts\Common.ps1"
Assert-Windows
if (!$SandboxRoot -and [Environment]::OSVersion.Version.Build -lt 22000) { throw 'Windows 11 is required.' }
if ($SandboxRoot) {
    $profileDirectory = Join-Path $SandboxRoot 'profile'
    $stateDirectory = Join-Path $SandboxRoot 'state'
    $SkipPackages = $true; $NoStartup = $true; $NoStart = $true
} else {
    $profileDirectory = $env:USERPROFILE
    $stateDirectory = Get-DesktopStateRoot
}
[IO.Directory]::CreateDirectory($stateDirectory) | Out-Null
$statePath = Join-Path $stateDirectory 'state.json'
# Validate templates before installing or touching user settings.
$theme = Get-Content -LiteralPath "$PSScriptRoot\theme.json" -Raw | ConvertFrom-Json
foreach ($property in $theme.PSObject.Properties) {
    if ($property.Name -ne 'name' -and $property.Name -ne 'mode' -and $property.Value -notmatch '^#[0-9a-fA-F]{6}$') {
        throw "Invalid theme color: $($property.Name)"
    }
}
$templates = @(
    @{ Source='configs\glazewm\config.yaml'; Target='.glzr\glazewm\config.yaml' },
    @{ Source='configs\wezterm\wezterm.lua'; Target='.wezterm.lua' }
)
Get-ChildItem -LiteralPath "$PSScriptRoot\configs\zebar\omarchy-windows" -File | ForEach-Object {
    $templates += @{ Source="configs\zebar\omarchy-windows\$($_.Name)"; Target=".glzr\zebar\omarchy-windows\$($_.Name)" }
}
$planned = @()
foreach ($template in $templates) {
    $content = Get-Content -LiteralPath (Join-Path $PSScriptRoot $template.Source) -Raw
    foreach ($property in $theme.PSObject.Properties) { $content = $content.Replace('{{'+$property.Name+'}}', [string]$property.Value) }
    if ($content -match '\{\{\w+\}\}') { throw "Unresolved theme token in $($template.Source)" }
    $planned += @{ Path=(Join-Path $profileDirectory $template.Target); Content=$content }
}
if (!$SkipPackages) {
    if (!(Get-Command winget.exe -ErrorAction SilentlyContinue)) { throw 'Install App Installer from Microsoft Store, then retry (winget is required).' }
    $packages = Get-Content -LiteralPath "$PSScriptRoot\packages.json" -Raw | ConvertFrom-Json
    foreach ($package in $packages) {
        # Installed applications are retained at their existing version. Updates are explicit.
        & winget.exe list --id $package.id --exact --source winget --accept-source-agreements --disable-interactivity | Out-Host
        if ($LASTEXITCODE -eq 0) { continue }
        & winget.exe install --id $package.id --exact --source winget --silent --accept-package-agreements --accept-source-agreements --disable-interactivity | Out-Host
        $code = $LASTEXITCODE
        # MSI reboot-required codes; tell user to reboot rather than automatically restarting.
        if ($code -eq 3010 -or $code -eq 1641) { Write-Warning 'An installer requested a restart. Reboot after setup.' }
        elseif ($code -ne 0) {
            if ($package.required) { throw "Installation failed for $($package.id), exit $code. Fix it and rerun; user configs have not been changed." }
            Write-Warning "Optional package $($package.id) failed, exit $code."
        }
    }
    Refresh-ExecutablePath
}
if (!$SandboxRoot) {
    foreach ($executable in @('glazewm.exe','zebar.exe','wezterm-gui.exe')) {
        if (!(Find-DesktopExecutable $executable)) { throw "$executable was not found. Open a fresh PowerShell and rerun, or add the installed executable folder to PATH." }
    }
    if (Get-Process glazewm -ErrorAction SilentlyContinue) {
        throw 'GlazeWM is running. Quit it from its tray icon or press Alt+Shift+Escape, then rerun setup.'
    }
}
# Copy management scripts into a stable location so moving the clone does not break login startup.
foreach ($name in @('Common.ps1','Start-Desktop.ps1','Restore.ps1','Doctor.ps1','Keybindings.ps1','Show-Keybindings.ps1')) {
    $planned += @{ Path=(Join-Path $stateDirectory $name); Content=(Get-Content -LiteralPath "$PSScriptRoot\scripts\$name" -Raw) }
}
$planned += @{ Path=(Join-Path $stateDirectory 'theme.json'); Content=(Get-Content -LiteralPath "$PSScriptRoot\theme.json" -Raw) }
if (!$NoStartup) {
    $startupFile = Join-Path ([Environment]::GetFolderPath('Startup')) 'OmarchyWindows.cmd'
    $runner = Join-Path $stateDirectory 'Start-Desktop.ps1'
    $planned += @{ Path=$startupFile; Content="@echo off`r`npowershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$runner`"`r`n" }
}
# Capture originals once per installation. Reruns never replace the baseline backups.
if (Test-Path -LiteralPath $statePath) {
    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    if ($state.version -ne 1) { throw 'Unknown backup format. Stop and inspect state.json.' }
} else {
    $state = [pscustomobject]@{ version=1; created=(Get-Date -Format o); files=@() }
    Write-State $state $statePath
}
foreach ($item in $planned) {
    $entry = @($state.files | Where-Object { $_.path -eq $item.Path })
    if (!$entry.Count) {
        $existed = Test-Path -LiteralPath $item.Path
        $backup = Join-Path $stateDirectory ('backups\'+[guid]::NewGuid().ToString()+'.bak')
        if ($existed) {
            if (!(Test-Path -LiteralPath $item.Path -PathType Leaf)) { throw "Expected file at $($item.Path)" }
            [IO.Directory]::CreateDirectory((Split-Path -Parent $backup)) | Out-Null
            Copy-Item -LiteralPath $item.Path -Destination $backup
        }
        $state.files = @($state.files) + [pscustomobject]@{ path=$item.Path; existed=$existed; backup=$backup }
        # Record recovery information before changing each destination.
        Write-State $state $statePath
    }
    Write-Utf8File $item.Path $item.Content
}
Write-Host "Settings applied. Originals and restore tools: $stateDirectory"
Write-Host 'Emergency pause: Alt+Shift+P. Exit tiling: Alt+Shift+Escape.'
Write-Host 'PowerToys and ShareX use their own defaults. Read docs/WINDOWS-CHECKLIST.md.'
if (!$NoStart) { & (Join-Path $stateDirectory 'Start-Desktop.ps1') }
